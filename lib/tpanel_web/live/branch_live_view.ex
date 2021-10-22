defmodule TpanelWeb.BranchLiveView do
  use TpanelWeb, :live_view

  def mount(_params, %{"test_mix_id" => test_mix_id}, socket) do
    test_mix = Tpanel.GitTools.get_full_test_mix!(test_mix_id)
    topic = "mix_#{test_mix.id}"
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

  def handle_event("default_branch", %{"branch" => branch_id}, socket) do
    socket.assigns.test_mix
    |> Tpanel.GitTools.update_test_mix(%{base_branch_id: branch_id})
    |> case do
      {:ok, test_mix} ->
        TpanelWeb.Endpoint.broadcast_from(self(), socket.assigns.topic, "updated", %{})
        {:noreply, assign(socket, test_mix: test_mix)}
      {:error, _thing} ->
        put_flash(socket, :error, "Couldn't set default branch")
        {:noreply, socket}
    end
  end

  def handle_event("create_branch", %{"branch" => branch_changeset}, socket) do
    socket.assigns.test_mix
    |> Tpanel.GitTools.create_mix_branch(branch_changeset)
    |> case do
      {:ok, _branch} ->
        TpanelWeb.Endpoint.broadcast(socket.assigns.topic, "created", %{})
        changeset = Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{})
        {:noreply, assign(socket, changeset: changeset)}
      {:error, %Ecto.Changeset{} = changeset} ->
        put_flash(socket, :error, "Couldn't create branch entry")
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info(_event, socket) do
    test_mix = Tpanel.GitTools.get_full_test_mix!(socket.assigns.test_mix.id)
    changeset = Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{})
    {:noreply, assign(socket, test_mix: test_mix, changeset: changeset)}
  end
end
