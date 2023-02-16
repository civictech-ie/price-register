defmodule PriceRegister.Repo.Migrations.AddSourceRowToSales do
  use Ecto.Migration

  def change do
    alter table(:sales) do
      # source row is the year/month CSV + the row number, should be unique
      add :source_row, :text, null: false, unique: true, index: true
    end
  end
end
