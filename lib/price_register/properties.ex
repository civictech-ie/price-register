defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias PriceRegister.Repo

  alias Ecto.Changeset
  alias PriceRegister.Properties.Sale

  def sales_count(starts_on = %Date{}, ends_on = %Date{}) do
    Repo.one(
      from s in Sale,
        where: s.date >= ^starts_on,
        where: s.date <= ^ends_on,
        select: fragment("count(*)")
    )
  end

  def sales_count() do
    Repo.one(from s in Sale, select: fragment("count(*)"))
  end

  # no page
  def list_sales() do
    Sale
    |> order_by({:desc, :inserted_at})
    |> Repo.paginate(include_total_count: false, total_count_limit: :infinity)
  end

  def insert_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  def get_sale!(date, address, postal_code, county, price) do
    Repo.one(
      from s in Sale,
        where: s.date == ^date,
        where: s.address == ^address,
        where: s.postal_code == ^postal_code,
        where: s.county == ^county,
        where: s.price == ^price,
        limit: 1
    )
  end

  def get_sale!(id), do: Repo.get!(Sale, id)
end
