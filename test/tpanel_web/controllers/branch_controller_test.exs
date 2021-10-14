defmodule TpanelWeb.BranchControllerTest do
  use TpanelWeb.ConnCase

  import Tpanel.GitToolsFixtures

  alias Tpanel.GitTools.Branch

  @create_attrs %{
    description: "some description",
    name: "some name",
    refspec: "some refspec",
    remote: "some remote"
  }
  @update_attrs %{
    description: "some updated description",
    name: "some updated name",
    refspec: "some updated refspec",
    remote: "some updated remote"
  }
  @invalid_attrs %{description: nil, name: nil, refspec: nil, remote: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all branches", %{conn: conn} do
      conn = get(conn, Routes.branch_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create branch" do
    test "renders branch when data is valid", %{conn: conn} do
      conn = post(conn, Routes.branch_path(conn, :create), branch: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.branch_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "description" => "some description",
               "name" => "some name",
               "refspec" => "some refspec",
               "remote" => "some remote"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.branch_path(conn, :create), branch: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update branch" do
    setup [:create_branch]

    test "renders branch when data is valid", %{conn: conn, branch: %Branch{id: id} = branch} do
      conn = put(conn, Routes.branch_path(conn, :update, branch), branch: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.branch_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "description" => "some updated description",
               "name" => "some updated name",
               "refspec" => "some updated refspec",
               "remote" => "some updated remote"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, branch: branch} do
      conn = put(conn, Routes.branch_path(conn, :update, branch), branch: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete branch" do
    setup [:create_branch]

    test "deletes chosen branch", %{conn: conn, branch: branch} do
      conn = delete(conn, Routes.branch_path(conn, :delete, branch))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.branch_path(conn, :show, branch))
      end
    end
  end

  defp create_branch(_) do
    branch = branch_fixture()
    %{branch: branch}
  end
end
