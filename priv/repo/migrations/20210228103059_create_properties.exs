defmodule PriceRegister.Repo.Migrations.CreateProperties do
  use Ecto.Migration

  def change do
    create table(:properties, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :address, :text, null: false
      add :postal_code, :text
      add :county, :text, null: false
      add :slug, :text, null: false

      timestamps()
    end


    create index(:properties, [:slug], unique: true)
    create index(:properties, [:postal_code])
    create index(:properties, [:county])
    create index(:properties, [:address])
    create index(:properties, [:postal_code, :county, :address], unique: true)
  end
end
