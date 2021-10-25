defmodule Tpanel.MixSupervisor do
  use DynamicSupervisor

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def get_mixserver(mix_id) do
    if not is_integer(mix_id), do: raise "Invalid mix ID" 
    case Registry.lookup(Tpanel.MixRegistry, "mixserver_#{mix_id}") do
      [{pid, _val}] -> pid
      [] -> DynamicSupervisor.start_child(__MODULE__, {Tpanel.MixServer, %Tpanel.MixServer.State{test_mix_id: mix_id}})
    end
  end
end
