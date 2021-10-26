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

  def broadcast(state, msg, %{} = contents) do
    TpanelWeb.Endpoint.broadcast(state.output_topic, msg, contents)
  end

  def run_sync(%State{} = state, mission, arguments, opts \\ []) do
    directory = Keyword.get(opts, :cd, ".")
    timeout = Keyword.get(opts, :timeout, 10000)
    realdir = "#{state.workdir}/#{directory}/"

    broadcast(state, "exec", %{directory: directory, command: [mission | arguments]})
    task = Task.async(fn ->
      Rambo.run(mission, arguments, cd: realdir, timeout: timeout, log: fn
        {stream, output} -> broadcast(state, "output", %{stream: stream, output: output})
      end)
    end)
    {:ok, %Rambo{} = ret} = Task.await(task, timeout)
    broadcast(state, "exec_end", %{})
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
      %Rambo{status: 0, out: rev} = run_sync(state, "git", ["rev-parse", branch.name])
      rev = String.replace(rev, "\n", "")
      if not String.match?(rev, ~r/^[[:alnum:]]{40}$/) do
        raise "Did not find a valid revision for branch #{branch.name}"
      end
      Tpanel.GitTools.update_branch(branch, %{fetched_revision: rev})
    end)
    Tpanel.GitTools.update_test_mix(state.test_mix, %{last_fetch: DateTime.now!("Etc/UTC")})
    TpanelWeb.Endpoint.broadcast(state.update_topic, "reloaded", %{})
    state
  end

end
