defmodule PriceRegister.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      PriceRegister.Repo,
      # Start the Telemetry supervisor
      PriceRegisterWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PriceRegister.PubSub},
      # Start the Endpoint (http/https)
      PriceRegisterWeb.Endpoint,
      # Start a worker by calling: PriceRegister.Worker.start_link(arg)
      # {PriceRegister.Worker, arg}
      PriceRegister.PPRFetcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PriceRegister.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PriceRegisterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
