defmodule TpanelWeb.PageController do
  use TpanelWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
