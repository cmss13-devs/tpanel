defmodule Tpanel.GitExecutor do
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
    {:via, Registry, {ExecutorRegistry, "mixserver_#{state.test_mix_id}"}}
  end

  @impl true
  def init(%State{} = state) do
    state = state 
    |> struct(%{
      test_mix: Tpanel.GitTools.get_full_test_mix!(state.test_mix_id),
      output_topic: "mixserver_#{state.test_mix_id}",
      update_topic: "mix_#{state.test_mix_id}",
      workdir: "workdir/#{state.test_mix.name}"
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
  def handle_cast(:reload, %State{} = state) do
    {:noreply, reload_mix(state)}
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
    |> update_remotes()
  end
 
  @doc """
  Initializes local working directory for working with a TestMix if neccessary
  """
  def init_workdir(%State{} = state) do
    if not File.exists?(state.workdir) do
      File.mkdir!(state.workdir)
      System.cmd("git", ["init"], cd: state.workdir)
    end
    update_remotes(state)
  end

  @doc """
  Update contents of the TestMix git repo, tracking remotes 
  set in the database model and fetching remote branches
  """
  def update_remotes(%State{} = state) do
    Enum.each(state.test_mix.branches, fn branch ->
      System.cmd("git", ["fetch", "--force", branch.remote, "#{branch.refspec}:#{branch.name}"], cd: state.workdir)
      rev = System.cmd("git", ["rev-parse", branch.name], cd: state.workdir)
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
