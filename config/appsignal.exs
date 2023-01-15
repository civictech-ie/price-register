import Config

config :appsignal, :config,
  otp_app: :price_register,
  name: "priceregister.civictech.ie",
  push_api_key: "b3b191f4-40c7-41f8-b540-48e5eb9ab642",
  env: Mix.env()
