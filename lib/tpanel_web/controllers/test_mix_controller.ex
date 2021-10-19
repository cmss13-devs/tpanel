defmodule TpanelWeb.TestMixController do
  use TpanelWeb, :controller

  alias Tpanel.GitTools
  alias Tpanel.GitTools.TestMix

  def index(conn, _params) do
    testmixes = GitTools.list_testmixes()
    render(conn, "index.html", testmixes: testmixes)
  end

  def new(conn, _params) do
    changeset = GitTools.change_test_mix(%TestMix{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"test_mix" => test_mix_params}) do
    case GitTools.create_test_mix(test_mix_params) do
      {:ok, test_mix} ->
        conn
        |> put_flash(:info, "TestMix created successfully.")
        |> redirect(to: Routes.test_mix_path(conn, :show, test_mix))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    test_mix = GitTools.get_full_test_mix!(id)
    changeset = GitTools.change_test_mix(test_mix)
    render(conn, "show.html", test_mix: test_mix, changeset: changeset)
  end

  def update(conn, %{"id" => id, "test_mix" => test_mix_params}) do
    test_mix = GitTools.get_test_mix!(id)

    case GitTools.update_test_mix(test_mix, test_mix_params) do
      {:ok, test_mix} ->
        conn
        |> put_flash(:info, "TestMix updated successfully.")
        |> redirect(to: Routes.test_mix_path(conn, :show, test_mix))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", test_mix: test_mix, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    test_mix = GitTools.get_test_mix!(id)
    {:ok, _test_mix} = GitTools.delete_test_mix(test_mix)

    conn
    |> put_flash(:info, "TestMix deleted successfully.")
    |> redirect(to: Routes.test_mix_path(conn, :index))
  end
end
