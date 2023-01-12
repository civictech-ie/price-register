defmodule PriceRegister.Repo.Migrations.CreateSales do
  use Ecto.Migration

  def change do
    create table(:sales, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date_of_sale, :date, null: false, index: true
      add :address, :text
      add :county, :text, null: false, index: true
      add :eircode, :text, index: true
      add :price_in_cents, :bigint, null: false, index: true
      add :not_full_market_price, :boolean, default: false, null: false, index: true
      add :vat_exclusive, :boolean, default: false, null: false, index: true
      add :description_of_property, :text, index: true, null: false
      add :property_size_description, :text

      timestamps()
    end

    # enable gin_trgm extension
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    # add trigram index for address
    execute "CREATE INDEX sales_address_trgm_idx ON sales USING GIN (address gin_trgm_ops);"
  end
end
