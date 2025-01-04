defmodule PprApi.Repo.Migrations.AddFingerprintToResidentialSales do
  use Ecto.Migration

  def change do
    alter table(:residential_sales) do
      add :fingerprint, :string, null: false
    end

    create unique_index(:residential_sales, [:fingerprint])
  end
end
