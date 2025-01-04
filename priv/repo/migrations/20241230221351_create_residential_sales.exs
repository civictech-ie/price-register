defmodule PprApi.Repo.Migrations.CreateResidentialSales do
  use Ecto.Migration

  def change do
    create table(:residential_sales) do
      add :date_of_sale, :date, null: false
      add :address, :string, null: false
      add :county, :string, null: false
      add :eircode, :string, null: true
      add :price_in_euros, :decimal, null: false
      add :not_full_market_price, :boolean, null: false, default: false
      add :vat_exclusive, :boolean, null: false, default: false
      add :description_of_property, :string, null: true
      add :property_size_description, :string, null: true

      timestamps(type: :utc_datetime)
    end
  end
end
