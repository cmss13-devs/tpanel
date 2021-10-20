defmodule TpanelWeb.PageController do
  use TpanelWeb, :controller

  def index(conn, _params) do
    new_path = Routes.test_mix_path(conn, :index)
    redirect(conn, to: new_path)
    |> halt()
  end
end
