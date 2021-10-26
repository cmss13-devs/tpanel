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
    {_, opts} = Keyword.get_and_update(opts, :log, fn 
      true -> {true, logger}
      nil -> {nil, logger}
      val -> {val, false}
    end)
    task = Task.async(fn ->
      Rambo.run(mission, arguments, opts)
    end)
    {:ok, %Rambo{} = ret} = Task.await(task, timeout)
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
    {:noreply, state}
  end

  @impl true
  def handle_cast(:fetch, %State{} = state) do
    {:noreply, 
    state
    |> reload_mix()
    |> fetch_remotes()
    }
  end

  @impl true
  def handle_info(%{event: "updated"}, %State{} = state) do
    {:noreply, reload_mix(state)}
  end

  @impl true
  def handle_info(%{event: "reloaded"}, %State{} = state) do
    {:noreply, state}
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
    end
    fetch_remotes(state)
  end

  @doc """
  Update contents of the TestMix git repo, tracking remotes 
  set in the database model and fetching remote branches
  """
  def fetch_remotes(%State{} = state) do
    Enum.each(state.test_mix.branches, fn branch ->
      %Rambo{status: 0} = run_sync(state, "git", ["fetch", "--force", branch.remote, "#{branch.refspec}:#{branch.name}"], timeout: 120000)
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
    send_info(state, "Done fetching remotes at #{fetch_time}")
    TpanelWeb.Endpoint.broadcast(state.update_topic, "reloaded", %{})
    state
  end

end
