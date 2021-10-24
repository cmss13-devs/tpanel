defmodule Tpanel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Tpanel.Repo,
      # Start the Telemetry supervisor
      TpanelWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Tpanel.PubSub},
      # Start the Endpoint (http/https)
      TpanelWeb.Endpoint,
      # Start a worker by calling: Tpanel.Worker.start_link(arg)
      # {Tpanel.Worker, arg}
      {Registry, keys: :unique, name: ExecutorRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tpanel.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TpanelWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
