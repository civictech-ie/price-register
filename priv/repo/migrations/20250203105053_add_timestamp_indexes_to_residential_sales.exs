defmodule PprApi.Repo.Migrations.AddTimestampIndexesToResidentialSales do
  use Ecto.Migration

  def change do
    create index(:residential_sales, [:updated_at])
    create index(:residential_sales, [:inserted_at])
    create index(:residential_sales, [:date_of_sale, :id])
    create index(:residential_sales, [:price_in_euros, :id])
    create index(:residential_sales, [:updated_at, :id])
    create index(:residential_sales, [:inserted_at, :id])
  end
end
