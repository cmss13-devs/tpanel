defmodule Tpanel.Repo do
  use Ecto.Repo,
    otp_app: :tpanel,
    adapter: Ecto.Adapters.Postgres
end
