defmodule PriceRegister.Repo.Migrations.CreateSales do
  use Ecto.Migration

  def change do
    create table(:sales, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :date, :date, null: false
      add :price, :bigint, null: false
      add :market_price, :boolean, default: false, null: false
      add :vat_inclusive, :boolean, default: false, null: false
      add :description, :text, default: "", null: false
      add :size_description, :text, default: "", null: false
      add :property_id, references(:properties, on_delete: :delete_all, type: :uuid), null: false

      timestamps()
    end

    create index(:sales, [:property_id])
    create index(:sales, [:price])
    create index(:sales, [:date])
    create index(:sales, [:market_price])
    create index(:sales, [:vat_inclusive])
    create index(:sales, [:property_id, :price, :date], unique: true)
  end
end
