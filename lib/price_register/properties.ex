defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias PriceRegister.Repo

  alias Ecto.Changeset
  alias PriceRegister.Properties.Sale

  def most_recent_date do
    Repo.one(
      from s in Sale,
        order_by: {:desc, :date},
        select: fragment("date"),
        limit: 1
    )
  end

  def sales_count(starts_on = %Date{}, ends_on = %Date{}) do
    Repo.one(
      from s in Sale,
        where: s.date >= ^starts_on,
        where: s.date <= ^ends_on,
        select: fragment("count(*)")
    )
  end

  def sale_at_index(starts_on = %Date{}, ends_on = %Date{}, index) do
    Repo.one(
      from s in Sale,
        where: s.date >= ^starts_on,
        where: s.date <= ^ends_on,
        order_by: {:desc, :inserted_at},
        offset: ^index,
        limit: 1
    )
  end

  def sales_count() do
    Repo.one(from s in Sale, select: fragment("count(*)"))
  end

  # no page
  def list_sales() do
    Sale
    |> order_by({:desc, :inserted_at})
    |> Repo.paginate(include_total_count: true, total_count_limit: :infinity)
  end

  def insert_sale(attrs \\ %{}, index) do
    %Sale{}
    |> Sale.changeset(attrs |> Map.put(:index, index))
    |> Repo.insert(
      returning: true,
      on_conflict:
        {:replace,
         [
           :date,
           :address,
           :postal_code,
           :county,
           :price,
           :description,
           :full_market,
           :size_description,
           :vat_inclusive
         ]},
      conflict_target: [:source_row]
    )
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
