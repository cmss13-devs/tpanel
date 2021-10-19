defmodule TpanelWeb.BranchLiveView do
  use TpanelWeb, :live_view

  def mount(_params, %{"test_mix_id" => test_mix_id}, socket) do
    test_mix = Tpanel.GitTools.get_full_test_mix!(test_mix_id)
    {:ok, assign(socket, test_mix: test_mix, newchangeset: Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{}))}
  end

  def handle_event("delete_branch", %{"branch" => branch_id}, socket) do
    Tpanel.GitTools.get_branch!(branch_id)
      |> Tpanel.GitTools.delete_branch
    put_flash(socket, :info, "Branch deleted")
    {:noreply, socket}
  end

  def handle_event("create_branch", %{"branch" => branch_changeset}, socket) do
    socket.assigns.test_mix
    |> Tpanel.GitTools.create_mix_branch(branch_changeset)
    |> case do
      {:ok, branch} ->
        {:noreply, 
        socket 
        |> put_flash(:info, "Branch '#{branch.name}' created")
        |> assign(newchangeset: Tpanel.GitTools.change_branch(%Tpanel.GitTools.Branch{}))
        }
      {:error, %Ecto.Changeset{} = newchangeset} ->
        {:noreply, assign(socket, newchangeset: newchangeset)}
    end
  end
end
