defmodule TpanelWeb.TestMixControllerTest do
  use TpanelWeb.ConnCase

  import Tpanel.GitToolsFixtures

  @create_attrs %{lastbuild: ~D[2021-10-14], name: "some name"}
  @update_attrs %{lastbuild: ~D[2021-10-15], name: "some updated name"}
  @invalid_attrs %{lastbuild: nil, name: nil}

  describe "index" do
    test "lists all testmixes", %{conn: conn} do
      conn = get(conn, Routes.test_mix_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Testmixes"
    end
  end

  describe "new test_mix" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.test_mix_path(conn, :new))
      assert html_response(conn, 200) =~ "New Test mix"
    end
  end

  describe "create test_mix" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.test_mix_path(conn, :create), test_mix: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.test_mix_path(conn, :show, id)

      conn = get(conn, Routes.test_mix_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Test mix"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.test_mix_path(conn, :create), test_mix: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Test mix"
    end
  end

  describe "edit test_mix" do
    setup [:create_test_mix]

    test "renders form for editing chosen test_mix", %{conn: conn, test_mix: test_mix} do
      conn = get(conn, Routes.test_mix_path(conn, :edit, test_mix))
      assert html_response(conn, 200) =~ "Edit Test mix"
    end
  end

  describe "update test_mix" do
    setup [:create_test_mix]

    test "redirects when data is valid", %{conn: conn, test_mix: test_mix} do
      conn = put(conn, Routes.test_mix_path(conn, :update, test_mix), test_mix: @update_attrs)
      assert redirected_to(conn) == Routes.test_mix_path(conn, :show, test_mix)

      conn = get(conn, Routes.test_mix_path(conn, :show, test_mix))
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, test_mix: test_mix} do
      conn = put(conn, Routes.test_mix_path(conn, :update, test_mix), test_mix: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Test mix"
    end
  end

  describe "delete test_mix" do
    setup [:create_test_mix]

    test "deletes chosen test_mix", %{conn: conn, test_mix: test_mix} do
      conn = delete(conn, Routes.test_mix_path(conn, :delete, test_mix))
      assert redirected_to(conn) == Routes.test_mix_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.test_mix_path(conn, :show, test_mix))
      end
    end
  end

  defp create_test_mix(_) do
    test_mix = test_mix_fixture()
    %{test_mix: test_mix}
  end
end
