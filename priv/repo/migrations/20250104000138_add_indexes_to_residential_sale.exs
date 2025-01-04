defmodule PprApi.Repo.Migrations.AddIndexesToResidentialSale do
  use Ecto.Migration

  def change do
    create index(:residential_sales, [:date_of_sale, :inserted_at, :id])
    create index(:residential_sales, [:price_in_euros])
    create index(:residential_sales, [:county])
    create index(:residential_sales, [:county, :address])
    create index(:residential_sales, [:eircode])
  end
end
