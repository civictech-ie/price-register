defmodule PprApi.Repo do
  use Ecto.Repo,
    otp_app: :ppr_api,
    adapter: Ecto.Adapters.Postgres
end
