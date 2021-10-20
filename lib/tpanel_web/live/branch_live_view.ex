defmodule TpanelWeb.BranchLiveView do
  use TpanelWeb, :live_view

  def mount(_params, %{"test_mix_id" => test_mix_id}, socket) do
    test_mix = Tpanel.GitTools.get_full_test_mix!(test_mix_id)
    topic = "mixbranches_#{test_mix.id}"
    TpanelWeb.Endpoint.subscribe(topic)
    changeset = Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{})
    {:ok, assign(socket, test_mix: test_mix, changeset: changeset, topic: topic)}
  end

  def handle_event("delete_branch", %{"branch" => branch_id}, socket) do
    Tpanel.GitTools.get_branch!(branch_id)
    |> Tpanel.GitTools.delete_branch
    TpanelWeb.Endpoint.broadcast(socket.assigns.topic, "deleted", %{})
    {:noreply, socket}
  end

  def handle_event("create_branch", %{"branch" => branch_changeset}, socket) do
    socket.assigns.test_mix
    |> Tpanel.GitTools.create_mix_branch(branch_changeset)
    |> case do
      {:ok, _branch} ->
        TpanelWeb.Endpoint.broadcast(socket.assigns.topic, "created", %{})
        {:noreply, 
        socket 
        |> assign(changeset: Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{}))
        }
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info(_event, socket) do
    test_mix = Tpanel.GitTools.get_full_test_mix!(socket.assigns.test_mix.id)
    changeset = Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{})
    {:noreply, assign(socket, test_mix: test_mix, changeset: changeset)}
  end
end
