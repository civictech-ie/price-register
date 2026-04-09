defmodule PprApi.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Configure AppSignal logger handler
    Appsignal.Logger.Handler.add("ppr_api")

    children = [
      PprApiWeb.Telemetry,
      PprApi.Repo,
      {DNSCluster, query: Application.get_env(:ppr_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PprApi.PubSub},
      {Finch, name: PprApi.Finch},
      PprApiWeb.Endpoint,
      PprApi.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PprApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    PprApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
