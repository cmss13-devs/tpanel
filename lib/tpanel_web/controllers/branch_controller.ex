defmodule TpanelWeb.BranchController do
  use TpanelWeb, :controller

  alias Tpanel.GitTools
  alias Tpanel.GitTools.Branch

  def index(conn, _params) do
    branches = GitTools.list_branches()
    render(conn, "index.html", branches: branches)
  end

  def new(conn, _params) do
    changeset = GitTools.change_branch(%Branch{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"branch" => branch_params}) do
    case GitTools.create_branch(branch_params) do
      {:ok, branch} ->
        conn
        |> put_flash(:info, "Branch created successfully.")
        |> redirect(to: Routes.branch_path(conn, :show, branch))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    branch = GitTools.get_branch!(id)
    render(conn, "show.html", branch: branch)
  end

  def edit(conn, %{"id" => id}) do
    branch = GitTools.get_branch!(id)
    changeset = GitTools.change_branch(branch)
    render(conn, "edit.html", branch: branch, changeset: changeset)
  end

  def update(conn, %{"id" => id, "branch" => branch_params}) do
    branch = GitTools.get_branch!(id)

    case GitTools.update_branch(branch, branch_params) do
      {:ok, branch} ->
        conn
        |> put_flash(:info, "Branch updated successfully.")
        |> redirect(to: Routes.branch_path(conn, :show, branch))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", branch: branch, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    branch = GitTools.get_branch!(id)
    {:ok, _branch} = GitTools.delete_branch(branch)

    conn
    |> put_flash(:info, "Branch deleted successfully.")
    |> redirect(to: Routes.branch_path(conn, :index))
  end
end
