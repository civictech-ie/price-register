defmodule PriceRegister.Repo.Migrations.CreateSales do
  use Ecto.Migration

  def change do
    create table(:sales, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :address, :text, default: "", null: false
      add :postal_code, :text, default: "", null: false
      add :county, :text, default: "", null: false
      add :date, :date, null: false
      add :price, :bigint, null: false
      add :full_market, :boolean, default: false, null: false
      add :vat_inclusive, :boolean, default: false, null: false
      add :description, :text, default: "", null: false
      add :size_description, :text, default: "", null: false
      add :source_row, :text, null: false

      timestamps()
    end

    create index(:sales, [:inserted_at])
    create index(:sales, [:source_row], unique: true)
    create index(:sales, [:updated_at])
    create index(:sales, [:price])
    create index(:sales, [:date])
    create index(:sales, [:full_market])
    create index(:sales, [:vat_inclusive])
    create index(:sales, [:postal_code])
    create index(:sales, [:county])
    create index(:sales, [:address])
    create index(:sales, [:inserted_at, :date])
    create index(:sales, [:address, :county, :postal_code, :price, :date])
  end
end
