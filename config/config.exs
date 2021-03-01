# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :price_register,
  ecto_repos: [PriceRegister.Repo]

# Configures the endpoint
config :price_register, PriceRegisterWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pw1lFD7096ubLTWrsyD56xVA/N1zL/by+Hmti3SBfQuqQK7+Ox8gPnPdkRu/PRZ4",
  render_errors: [view: PriceRegisterWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PriceRegister.PubSub,
  live_view: [signing_salt: "GAE1tmrz"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
