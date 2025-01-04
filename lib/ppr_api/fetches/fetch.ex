defmodule PprApi.Fetches.Fetch do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fetches" do
    field :status, :string, default: "starting"
    field :starts_on, :date
    field :current_month, :date
    field :total_rows, :integer, default: 0
    field :error_message, :string
    field :started_at, :utc_datetime
    field :finished_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(fetch, attrs) do
    fetch
    |> cast(attrs, [
      :status,
      :starts_on,
      :current_month,
      :total_rows,
      :error_message,
      :started_at,
      :finished_at
    ])
    |> validate_required([:starts_on])
    |> validate_inclusion(:status, ["starting", "fetching", "success", "error"])
  end
end
