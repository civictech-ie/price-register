defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias PriceRegister.Repo

  alias PriceRegister.Properties.Sale

  def sales_count() do
    Repo.one(from s in Sale, select: fragment("count(*)"))
  end

  # no page
  def list_sales() do
    Sale
    |> order_by({:desc, :date})
    |> order_by({:asc_nulls_last, :county})
    |> order_by({:asc_nulls_last, :postal_code})
    |> order_by({:asc, :address})
    |> Repo.paginate(include_total_count: true, total_count_limit: :infinity)
  end

  def upsert_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert(
      returning: true,
      on_conflict: :nothing,
      conflict_target: [:date, :address, :postal_code, :county, :price]
    )
  end

  def get_sale!(id), do: Repo.get!(Sale, id)
end
