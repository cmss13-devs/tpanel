defmodule Tpanel.MixServer do
  use GenServer, restart: :transient

  @moduledoc """
  GenServer for executing actual git related tasks on filesystem
  for the Tpanel workflow. There is normally only one GenServer
  per working directory and TestMix to avoid concurrent use
  of the git repository.
  """
  
  defmodule State do
    defstruct test_mix_id: 0, output_topic: "", update_topic: "", workdir: "/tmp", test_mix: %Tpanel.GitTools.TestMix{}
  end

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state, name: process_name(state))
  end

  @impl true
  def terminate(_reasonn, %State{} = state) do
    send_event(state, "killed", %{})
  end

  defp process_name(%State{} = state) do
    {:via, Registry, {Tpanel.MixRegistry, "mixserver_#{state.test_mix_id}"}}
  end

  def send_event(state, msg, %{} = contents) do
    TpanelWeb.Endpoint.broadcast(state.output_topic, msg, contents)
  end

  def send_info(state, msg) do
    TpanelWeb.Endpoint.broadcast(state.output_topic, "info", %{msg: msg})
  end

  def send_error(state, msg) do
    TpanelWeb.Endpoint.broadcast(state.output_topic, "error", %{msg: msg})
  end
  
  def push_output(topic, stream, msg) do
    TpanelWeb.Endpoint.broadcast(topic, "output", %{stream: stream, msg: msg})
  end 

  def run_sync(%State{} = state, mission, arguments, opts \\ []) do
    {directory, opts} = Keyword.get_and_update(opts, :cd, fn
      directory -> {directory, "#{state.workdir}/#{directory}/"}
    end)
    send_event(state, "exec", %{directory: directory, command: [mission | arguments]})
    try do
      rambo_sync(state, mission, arguments, opts)
    rescue
      e -> 
        send_event(state, "fatal", %{msg: Exception.format(:error, e, __STACKTRACE__)})
        reraise e, __STACKTRACE__
    end
  end

  def rambo_sync(state, mission, arguments, opts) do
    timeout = Keyword.get(opts, :timeout, 10000)
    logger = fn
       {:stdout, output} -> push_output(state.output_topic, "stdout", output)
       {:stderr, output} -> push_output(state.output_topic, "stderr", output)
    end
    {logopt, opts} = Keyword.get_and_update(opts, :log, fn 
      true -> {true, logger}
      nil -> {nil, logger}
      val -> {val, false}
    end)
    task = Task.async(fn ->
      Rambo.run(mission, arguments, opts)
    end)
    Tpanel.MixSupervisor.register_task(state.test_mix_id, task.pid)
    {_term, %Rambo{} = ret} = Task.await(task, timeout)
    Tpanel.MixSupervisor.clear_task(state.test_mix_id)
    if logopt do
      send_event(state, "status", %{status: ret.status})
    end
    ret
  end

  @impl true
  def init(%State{} = state) do
    test_mix = Tpanel.GitTools.get_full_test_mix!(state.test_mix_id)
    state = state 
    |> struct(%{
      test_mix: test_mix,
      output_topic: "mixserver_#{test_mix.id}",
      update_topic: "mix_#{test_mix.id}",
      workdir: "./workdir/#{test_mix.name}"
    })
    {:ok, state, {:continue, :deferred_init}}
  end

  @impl true
  def handle_continue(:deferred_init, %State{} = state) do
    init_workdir(state) 
    TpanelWeb.Endpoint.subscribe(state.update_topic)
    send_event(state, "reloaded", %{})
    {:noreply, state}
  end

  @impl true
  def handle_cast(:fetch, %State{} = state) do
    {:noreply, 
    state
    |> reload_mix()
    |> do_fetch()
    }
  end

  @impl true
  def handle_cast(:build, %State{} = state) do
    {:noreply,
    state
    |> reload_mix()
    |> do_mix()
    |> do_build()
    }
  end

  @impl true
  def handle_info(%{event: "modified"}, %State{} = state) do
    {:noreply, reload_mix(state)}
  end

  @impl true
  def handle_info(%{event: "updated"}, %State{} = state) do
    {:noreply, reload_mix(state)}
  end

  def reload_mix(%State{} = state) do
    state
    |> struct(%{test_mix: Tpanel.GitTools.get_full_test_mix!(state.test_mix_id)})
  end
 
  @doc """
  Initializes local working directory for working with a TestMix if neccessary
  """
  def init_workdir(%State{} = state) do
    if not File.exists?(state.workdir) do
      File.mkdir!(state.workdir)
      run_sync(state, "git", ["init"])
      do_fetch(state)
    end
  end

  @doc """
  Update contents of the TestMix git repo, tracking remotes 
  set in the database model and fetching remote branches
  """
  def do_fetch(%State{} = state) do
    Enum.each(state.test_mix.branches, fn branch ->
      %Rambo{status: 0} = run_sync(state, "git", ["fetch", "-u", "--force", branch.remote, "#{branch.refspec}:#{branch.name}"], timeout: 120000)
      %Rambo{status: 0, out: rev} = run_sync(state, "git", ["rev-parse", branch.name], log: false)
      rev = String.replace(rev, "\n", "")
      if not String.match?(rev, ~r/^[[:alnum:]]{40}$/) do
        msg = "Did not find a valid revision for branch #{branch.name}"
        send_error(state, msg)
        raise msg
      end
      Tpanel.GitTools.update_branch(branch, %{fetched_revision: rev})
      send_info(state, "Branch #{branch.name} fetched at #{rev}")
    end)
    fetch_time = DateTime.now!("Etc/UTC")
    Tpanel.GitTools.update_test_mix(state.test_mix, %{last_fetch: fetch_time})
    TpanelWeb.Endpoint.broadcast("mix_#{state.test_mix_id}", "updated", %{})
    send_info(state, "Done fetching remotes at #{fetch_time}")
    state
  end

  def do_mix(%State{} = state) do
    base_branch  = Enum.at(state.test_mix.branches, 0)
    branches = Enum.drop(state.test_mix.branches, 1)
    if base_branch == nil do
      send_error(state, "No branches to build from")
      raise "No branches to build"
    end
    %Rambo{} = run_sync(state, "git", ["rebase", "--abort"], timeout: 10000, log: false)
    %Rambo{status: 0} = run_sync(state, "git", ["reset", "--hard"], timeout: 15000)
    base_rev = Tpanel.GitTools.default_rev(base_branch)
    %Rambo{status: 0} = run_sync(state, "git", ["checkout", base_rev], timeout: 15000, log: false)
    Tpanel.GitTools.update_branch(base_branch, %{built_revision: base_rev})
    Enum.each(branches, fn branch ->
      target_rev = Tpanel.GitTools.default_rev(branch)
      %Rambo{status: 0} = run_sync(state, "git", ["rebase", "HEAD", target_rev], timeout: 10000)
      Tpanel.GitTools.update_branch(branch, %{built_revision: target_rev})
    end)
    TpanelWeb.Endpoint.broadcast("mix_#{state.test_mix_id}", "updated", %{})
    send_info(state, "Successfully applied branches via rebase")
    state
  end

  @doc """
  Runs the build associated to the TestMix
  """
  def do_build(%State{} = state) do
    state
    |> do_docker_build()
    |> refresh_build()
    |> send_info("Built successfully")
    TpanelWeb.Endpoint.broadcast("mix_#{state.test_mix_id}", "updated", %{})
    state
  end 

  @doc """
  Update last build time
  """
  def refresh_build(%State{} = state) do
    build_time = DateTime.now!("Etc/UTC")
    Tpanel.GitTools.update_test_mix(state.test_mix, %{last_build: build_time})
    state
  end
 
  @doc """
  Invokes the external docker build process
  """ 
  def do_docker_build(%State{} = state) do
    cpu_shares = Application.get_env(:tpanel, :build_cpu_shares)
    timeout = Application.get_env(:tpanel, :build_timeout)
    target_tag = "#{Application.get_env(:tpanel, :build_image_name)}:#{state.test_mix.name}"
    cmd_args = ["build", "--cpu-shares=#{cpu_shares}", "--build-arg", "BUILD_TYPE=standalone", "--target", "deploy", "--tag", target_tag, "."]
    %Rambo{status: 0} = run_sync(state, "docker", cmd_args, timeout: timeout, env: %{"DOCKER_BUILDKIT" => "1"})
    state
  end

end
