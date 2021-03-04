defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  @table_name :fetcher_status

  import Ecto.Query, warn: false
  alias PriceRegister.Repo

  alias PriceRegister.Properties.Sale

  def most_recent_date do
    Repo.one(
      from s in Sale,
        order_by: {:desc, :date},
        select: fragment("date"),
        limit: 1
    )
  end

  def most_recent_update do
    Repo.one(
      from s in Sale,
        order_by: {:desc, :updated_at},
        select: fragment("updated_at"),
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

  def list_sales() do
    %{
      entries: entries,
      metadata: %{after: after_key, before: before_key, limit: limit, total_count: total_count}
    } =
      Sale
      |> order_by({:desc, :source_row})
      |> Repo.paginate(include_total_count: true, total_count_limit: :infinity)

    %{
      entries: entries,
      metadata: %{
        after: after_key,
        before: before_key,
        limit: limit,
        total_count: total_count,
        updated_at: get_updated_at()
      }
    }
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

  defp get_updated_at() do
    case :ets.lookup(@table_name, "updated_at") do
      [{"update_at", updated_at}] ->
        updated_at

      alt ->
        case most_recent_update() do
          %DateTime{} = dt -> dt |> DateTime.to_string()
          %NaiveDateTime{} = ndt -> ndt |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_string()
          _ -> nil
        end
    end
  end
end
