defmodule Tpanel.MixSupervisor do
  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_mixserver(mix_id, opts \\ []) do
    autostart = Keyword.get(opts, :start, false)
    if not is_integer(mix_id), do: raise "Invalid mix ID" 
    case Registry.lookup(Tpanel.MixRegistry, "mixserver_#{mix_id}") do
      [{pid, _val}] -> pid
      [] -> 
        if autostart do
          DynamicSupervisor.start_child(__MODULE__, {Tpanel.MixServer, %Tpanel.MixServer.State{test_mix_id: mix_id}})
        else
          []
        end
    end
  end

  def register_task(mix_id, pid) do
    Registry.register(Tpanel.MixRegistry, "mixtask_#{mix_id}", pid)
  end

  def clear_task(mix_id) do
    Registry.unregister(Tpanel.MixRegistry, "mixtask_#{mix_id}")
  end

  def stop_mixserver(mix_id) do
    case Registry.lookup(Tpanel.MixRegistry, "mixserver_#{mix_id}") do
      [{gs_pid, _val}] -> 
        GenServer.stop(gs_pid)
        case Registry.lookup(Tpanel.MixRegistry, "mixtask_#{mix_id}") do
          [val] ->
            IO.inspect val
            clear_task(mix_id)
            Rambo.kill(val)
          [] -> []
        end
      [] -> []
    end
  end
end
