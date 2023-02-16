import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :price_register, PriceRegisterWeb.Endpoint,
  url: [host: System.get_env("RENDER_EXTERNAL_HOSTNAME") || "localhost", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: :conn

# Configures Swoosh API Client
config :swoosh, :api_client, PriceRegister.Finch

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

config :appsignal, :config, active: true
