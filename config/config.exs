# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :price_register,
  ecto_repos: [PriceRegister.Repo]

# Configures the endpoint
config :price_register, PriceRegisterWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PriceRegisterWeb.ErrorHTML, json: PriceRegisterWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PriceRegister.PubSub,
  live_view: [signing_salt: "y1LwZ2BI"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :price_register, PriceRegister.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.41",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure AppSignal

config :appsignal, :config,
  otp_app: :price_register,
  name: "priceregister.civictech.ie",
  push_api_key: "b3b191f4-40c7-41f8-b540-48e5eb9ab642",
  env: Mix.env()

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
