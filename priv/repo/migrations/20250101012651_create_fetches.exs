defmodule PprApi.Repo.Migrations.CreateFetches do
  use Ecto.Migration

  def change do
    create table(:fetches) do
      add :status, :string, default: "fetching", null: false
      add :starts_on, :date, null: false
      add :current_month, :date
      add :total_rows, :integer, default: 0
      add :error_message, :text
      add :started_at, :utc_datetime
      add :finished_at, :utc_datetime

      timestamps()
    end
  end
end
