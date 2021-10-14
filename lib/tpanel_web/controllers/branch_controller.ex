defmodule TpanelWeb.BranchController do
  use TpanelWeb, :controller

  alias Tpanel.GitTools
  alias Tpanel.GitTools.Branch

  action_fallback TpanelWeb.FallbackController

  def index(conn, _params) do
    branches = GitTools.list_branches()
    render(conn, "index.json", branches: branches)
  end

  def create(conn, %{"branch" => branch_params}) do
    with {:ok, %Branch{} = branch} <- GitTools.create_branch(branch_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.branch_path(conn, :show, branch))
      |> render("show.json", branch: branch)
    end
  end

  def show(conn, %{"id" => id}) do
    branch = GitTools.get_branch!(id)
    render(conn, "show.json", branch: branch)
  end

  def update(conn, %{"id" => id, "branch" => branch_params}) do
    branch = GitTools.get_branch!(id)

    with {:ok, %Branch{} = branch} <- GitTools.update_branch(branch, branch_params) do
      render(conn, "show.json", branch: branch)
    end
  end

  def delete(conn, %{"id" => id}) do
    branch = GitTools.get_branch!(id)

    with {:ok, %Branch{}} <- GitTools.delete_branch(branch) do
      send_resp(conn, :no_content, "")
    end
  end
end
