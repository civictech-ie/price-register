defmodule PriceRegister.Repo do
  use Ecto.Repo,
    otp_app: :price_register,
    adapter: Ecto.Adapters.Postgres
end
