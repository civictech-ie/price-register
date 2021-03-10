use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :price_register, PriceRegister.Repo,
  database: "price_register_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

if System.get_env("GITHUB_ACTIONS") do
  config :price_register, PriceRegister.Repo,
    database: "price_register_test",
    username: "postgres",
    password: "postgres",
    hostname: System.get_env("DB_HOST", "localhost")
end

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :price_register, PriceRegisterWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
