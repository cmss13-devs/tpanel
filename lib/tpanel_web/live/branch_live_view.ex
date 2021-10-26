defmodule TpanelWeb.BranchLiveView do
  use TpanelWeb, :live_view

  def pub_event(socket, event) do
    TpanelWeb.Endpoint.broadcast_from(self(), "mix_#{socket.assigns.mix.id}", event, %{})
    socket
  end

  def scan_mixserver(socket) do
    assign(socket, mixserver: Tpanel.MixSupervisor.get_mixserver(socket.assigns.mix.id))
  end

  def reload_mix(socket) do
    mix = Tpanel.GitTools.get_full_test_mix!(socket.assigns.mix_id)
    assign(socket, mix: mix)
  end

  def reset_changeset(socket) do
    changeset = Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{})
    assign(socket, changeset: changeset)
  end

  def mount(_params, %{"test_mix_id" => mix_id}, socket) do
    TpanelWeb.Endpoint.subscribe("mix_#{mix_id}")
    {:ok, 
    assign(socket, mix_id: mix_id)
    |> reload_mix()
    |> scan_mixserver()
    |> reset_changeset() 
    } 
  end

  def handle_event("start_mixserver", _stuff, socket) do
    scan_mixserver(socket)
  end

  def handle_event("update_mixserver", _stuff, socket) do
    socket = scan_mixserver(socket)
    GenServer.cast(socket.assigns.mixserver, :fetch)
    {:noreply, socket}
  end

  def handle_event("delete_branch", %{"branch" => branch_id}, socket) do
    Tpanel.GitTools.get_branch!(branch_id)
    |> Tpanel.GitTools.delete_branch
    pub_event(socket, "updated")
    {:noreply, reload_mix(socket)}
  end

  def handle_event("order_branch", %{"_target" => [target]} = payload, socket) do
    branch_id = Enum.at(String.split(target, "-"), 1)
    {:ok, _branch} = Tpanel.GitTools.get_branch!(branch_id)
    |> Tpanel.GitTools.update_branch(%{priority: payload[target]})
    {:noreply, socket
    |> pub_event("updated")
    |> reload_mix()
    }
  end

  def handle_event("create_branch", %{"branch" => branch_changeset}, socket) do
    socket.assigns.mix
    |> Tpanel.GitTools.create_mix_branch(branch_changeset)
    |> case do
      {:ok, _branch} ->
        {:noreply, 
        socket
        |> pub_event("updated")
        |> reset_changeset()
        |> reload_mix()
        }
      {:error, %Ecto.Changeset{} = changeset} ->
        put_flash(socket, :error, "Couldn't create branch entry")
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info(%{event: "updated"}, socket) do
    {:noreply, 
    socket
    |> reload_mix()
    |> reset_changeset()
    }
  end

  def handle_info(%{event: "reloaded"}, socket) do
    {:noreply,
    socket
    |> reload_mix()
    |> scan_mixserver()
    }
  end 
end
