defmodule TpanelWeb.BranchLiveView do
  use TpanelWeb, :live_view
  import TpanelWeb.FormatHelper

  def pub_event(socket, event) do
    TpanelWeb.Endpoint.broadcast_from(self(), "mix_#{socket.assigns.mix.id}", event, %{})
    socket
  end

  def reload_mix(socket) do
    mix = Tpanel.GitTools.get_full_test_mix!(socket.assigns.mix_id)
    refresh_at = Timex.format!(Timex.now("Etc/UTC"), "%H:%M:%S", :strftime)
    assign(socket, mix: mix,
      refresh_at: refresh_at, 
      fetched_ago: from_now(mix.last_fetch),
      built_ago: from_now(mix.last_build))
  end


  def from_now(nil), do: "Never"
  def from_now(val) do
      Timex.from_now(val) |> case do
      {:error, _msg} -> "Unknown"
      x -> x
    end
  end

  def reset_changeset(socket) do
    changeset = Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{})
    assign(socket, changeset: changeset)
  end

  def mount(_params, %{"test_mix_id" => mix_id}, socket) do
    if connected?(socket) do
      TpanelWeb.Endpoint.subscribe("mix_#{mix_id}")
      Process.send_after(self(), :refresh, 120000)
    end

    {:ok, 
    assign(socket, mix_id: mix_id)
    |> reload_mix()
    |> reset_changeset() 
    } 
  end

  def handle_event("delete_branch", %{"branch" => branch_id}, socket) do
    Tpanel.GitTools.get_branch!(branch_id)
    |> Tpanel.GitTools.delete_branch
    pub_event(socket, "modified")
    {:noreply, reload_mix(socket)}
  end

  def handle_event("order_branch", %{"_target" => [target]} = payload, socket) do
    branch_id = Enum.at(String.split(target, "-"), 1)
    {:ok, _branch} = Tpanel.GitTools.get_branch!(branch_id)
    |> Tpanel.GitTools.update_branch(%{priority: payload[target]})
    {:noreply, socket
    |> pub_event("modified")
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
        |> pub_event("modified")
        |> reset_changeset()
        |> reload_mix()
        }
      {:error, %Ecto.Changeset{} = changeset} ->
        put_flash(socket, :error, "Couldn't create branch entry")
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info(%{event: "modified"}, socket) do
    {:noreply, 
    socket
    |> reload_mix()
    |> reset_changeset()
    }
  end

  def handle_info(%{event: "updated"}, socket) do
    {:noreply, reload_mix(socket)}
  end

  def handle_info(:refresh, socket) do
    Process.send_after(self(), :refresh, 120000)
    {:noreply, reload_mix(socket)}
  end 
end
