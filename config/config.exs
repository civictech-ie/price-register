# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ppr_api,
  ecto_repos: [PprApi.Repo],
  generators: [timestamp_type: :utc_datetime],
  scheduler_enabled: true

# Configures the endpoint
config :ppr_api, PprApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: PprApiWeb.ErrorHTML, json: PprApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PprApi.PubSub,
  live_view: [signing_salt: "A5duZ7lj"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ppr_api, PprApi.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  ppr_api: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ppr_api, PprApi.Scheduler,
  jobs: [
    {"* * * * *", {PprApi.Fetches, :fetch_latest_sales, []}},
    {"0 1 * * 6", {PprApi.Fetches, :fetch_all_sales, [true]}}
  ]

config :ex_cldr, PprApi.Cldr,
  default_locale: "en",
  locales: ["en"],
  providers: [Cldr.Number]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
