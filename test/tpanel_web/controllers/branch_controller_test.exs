defmodule TpanelWeb.BranchControllerTest do
  use TpanelWeb.ConnCase

  import Tpanel.GitToolsFixtures

  @create_attrs %{description: "some description", name: "some name", refspec: "some refspec", remote: "some remote"}
  @update_attrs %{description: "some updated description", name: "some updated name", refspec: "some updated refspec", remote: "some updated remote"}
  @invalid_attrs %{description: nil, name: nil, refspec: nil, remote: nil}

  describe "index" do
    test "lists all branches", %{conn: conn} do
      conn = get(conn, Routes.branch_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Branches"
    end
  end

  describe "new branch" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.branch_path(conn, :new))
      assert html_response(conn, 200) =~ "New Branch"
    end
  end

  describe "create branch" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.branch_path(conn, :create), branch: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.branch_path(conn, :show, id)

      conn = get(conn, Routes.branch_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Branch"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.branch_path(conn, :create), branch: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Branch"
    end
  end

  describe "edit branch" do
    setup [:create_branch]

    test "renders form for editing chosen branch", %{conn: conn, branch: branch} do
      conn = get(conn, Routes.branch_path(conn, :edit, branch))
      assert html_response(conn, 200) =~ "Edit Branch"
    end
  end

  describe "update branch" do
    setup [:create_branch]

    test "redirects when data is valid", %{conn: conn, branch: branch} do
      conn = put(conn, Routes.branch_path(conn, :update, branch), branch: @update_attrs)
      assert redirected_to(conn) == Routes.branch_path(conn, :show, branch)

      conn = get(conn, Routes.branch_path(conn, :show, branch))
      assert html_response(conn, 200) =~ "some updated description"
    end

    test "renders errors when data is invalid", %{conn: conn, branch: branch} do
      conn = put(conn, Routes.branch_path(conn, :update, branch), branch: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Branch"
    end
  end

  describe "delete branch" do
    setup [:create_branch]

    test "deletes chosen branch", %{conn: conn, branch: branch} do
      conn = delete(conn, Routes.branch_path(conn, :delete, branch))
      assert redirected_to(conn) == Routes.branch_path(conn, :index)

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
