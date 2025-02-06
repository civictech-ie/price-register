defmodule PprApi.ResidentialSales do
  import Ecto.Query, warn: false
  alias PprApi.Repo
  alias PprApi.Fetches
  alias PprApi.Fetches.Fetch
  alias PprApi.ResidentialSales.ResidentialSale
  alias PprApi.FingerprintHelper
  alias PprApi.Pagination.Cursor

  @doc """
  Lists residential sales with keyset pagination.
  Options:
    %{
      "sort" => "date-desc" | "date-asc" | "price-desc" | "price-asc",
      "after" => <base64 cursor> | "before" => <base64 cursor>,
      "limit" => "10" | "1000"
    }
  """
  def list_residential_sales(opts \\ []) do
    opts = parse_opts(opts)

    {before_entry, entries, after_entry} = get_sales_and_peek(opts)

    %{
      entries: entries,
      metadata: %{
        after_cursor: Cursor.encode_cursor(after_entry, opts),
        before_cursor: Cursor.encode_cursor(before_entry, opts),
        limit: opts["limit"],
        sort:
          opts["sort"]
          |> Tuple.to_list()
          |> Enum.join("-"),
        total_rows: total_residential_sales()
      }
    }
  end

  @doc """
  Returns the date of the most recent sale.
  """
  def latest_sale_date do
    ResidentialSale
    |> select([s], max(s.date_of_sale))
    |> Repo.one()
  end

  @doc """
  Current count of residential sales.
  """
  def total_residential_sales do
    case Fetches.get_latest_successful_full_fetch() do
      %Fetch{total_rows: total_rows} ->
        total_rows

      _ ->
        0
    end
  end

  @doc """
  Gets a single residential sale by ID.
  Raises if it doesn’t exist.
  """
  def get_residential_sale!(id), do: Repo.get!(ResidentialSale, id)

  @doc """
  Inserts sales in batches of 1000. Skips duplicates.
  """
  def upsert_rows(rows) do
    batch_size = 1000

    rows
    |> Enum.chunk_every(batch_size)
    |> Enum.reduce(0, fn chunk, acc ->
      inserted = upsert_batch(chunk)
      acc + inserted
    end)
  end

  defp upsert_batch(rows) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows_with_fingerprints =
      Enum.map(rows, fn row ->
        row
        |> Map.put(:fingerprint, FingerprintHelper.compute_fingerprint(row))
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
      end)

    # remove duplicate fingerprints within the batch
    unique_rows = remove_duplicate_fingerprints(rows_with_fingerprints)

    # perform the bulk upsert
    {rows_inserted, _} =
      Repo.insert_all(
        ResidentialSale,
        unique_rows,
        on_conflict: [set: [updated_at: now]],
        conflict_target: :fingerprint
      )

    rows_inserted
  end

  defp remove_duplicate_fingerprints(rows_with_fingerprints) do
    rows_with_fingerprints
    |> Enum.reduce(%{}, fn row, acc ->
      Map.put_new(acc, row.fingerprint, row)
    end)
    |> Map.values()
  end

  # accepts a map of options and returns a map of options
  # that will be a bit more usable for the rest of the functions
  # e.g. "limit" => "10" -> "limit" => 10
  #      "sort" => "date-desc" -> "sort" => {"date", "desc"}
  #      "before" => "706867" -> "cursor" => {"706867", "before"}
  defp parse_opts(opts) do
    opts
    |> parse_sort()
    |> parse_cursor()
    |> parse_limit()
  end

  defp parse_sort(opts) when is_map(opts) do
    opts
    |> Map.update("sort", nil, fn sort ->
      case String.split(sort, "-") do
        [field, direction] -> {field, direction}
        _ -> nil
      end
    end)
  end

  # accepts %{"after" => cursor} = opts
  # returns %{"cursor" => {{value, id}, "after"}}
  # where value is the decoded value, depending on the sort field
  defp parse_cursor(%{"after" => value, "sort" => {sort_field, _sort_direction}} = opts) do
    opts
    |> Map.delete("after")
    |> Map.put("cursor", {Cursor.decode_cursor(value, sort_field), "after"})
  end

  defp parse_cursor(%{"before" => value, "sort" => {sort_field, _sort_direction}} = opts) do
    opts
    |> Map.delete("before")
    |> Map.put("cursor", {Cursor.decode_cursor(value, sort_field), "before"})
  end

  defp parse_cursor(opts), do: opts

  defp parse_limit(opts) when is_map(opts) do
    opts
    |> Map.put("limit", parse_limit(opts["limit"]))
  end

  defp parse_limit(limit) when is_number(limit) do
    limit
  end

  defp parse_limit(limit) when is_binary(limit) do
    case Integer.parse(limit) do
      {num, _} -> num
    end
  end

  # The Actual Query

  # if i'm ascending and paginating forwards (after), i want to get the entries
  # that are greater than the cursor value.
  #
  # if i'm ascending and paginating backwards (before), i want to get the entries
  # that are less than (but closest to) the cursor value.
  #
  # if i'm descending and paginating forwards (after), i want to get the entries
  # that are less than the cursor value
  #
  # if i'm descending and paginating backwards (before), i want to get the entries
  # that are greater than (but closest to) the cursor value
  #
  # before and after should follow the sort order, so should be independent of the
  # cursor direction. (i.e. if i've pressed previous, then the previous button should
  # still show me further in the previous direction.)

  defp get_sales_and_peek(opts) do
    last_fetch_time =
      case PprApi.Fetches.get_latest_successful_full_fetch() do
        %Fetch{started_at: started_at} -> started_at
        _ -> nil
      end

    query =
      ResidentialSale
      |> apply_cursor(opts)
      |> apply_order(opts)
      |> apply_limit(opts)

    query =
      if last_fetch_time do
        query |> where([s], s.updated_at >= ^last_fetch_time)
      else
        query
      end

    entries = Repo.all(query) |> apply_corrective_flip(opts)

    before_entry = set_peek_entry(:before, entries, opts)
    after_entry = set_peek_entry(:after, entries, opts)

    {before_entry, entries, after_entry}
  end

  defp apply_cursor(query, %{
         "cursor" => {{cursor_value, cursor_id}, direction},
         "sort" => {"date", order}
       }) do
    case {direction, order} do
      {"before", "asc"} -> query |> less_than_date(cursor_value, cursor_id)
      {"after", "asc"} -> query |> greater_than_date(cursor_value, cursor_id)
      {"before", "desc"} -> query |> greater_than_date(cursor_value, cursor_id)
      {"after", "desc"} -> query |> less_than_date(cursor_value, cursor_id)
    end
  end

  defp apply_cursor(query, %{
         "cursor" => {{cursor_value, cursor_id}, direction},
         "sort" => {"price", order}
       }) do
    case {direction, order} do
      {"before", "asc"} -> query |> less_than_price(cursor_value, cursor_id)
      {"after", "asc"} -> query |> greater_than_price(cursor_value, cursor_id)
      {"before", "desc"} -> query |> greater_than_price(cursor_value, cursor_id)
      {"after", "desc"} -> query |> less_than_price(cursor_value, cursor_id)
    end
  end

  defp apply_cursor(query, _opts), do: query

  defp greater_than_date(query, cursor_value, cursor_id) do
    query
    |> where([s], s.date_of_sale > ^cursor_value)
    |> or_where([s], s.date_of_sale == ^cursor_value and s.id > ^cursor_id)
  end

  defp less_than_date(query, cursor_value, cursor_id) do
    query
    |> where([s], s.date_of_sale < ^cursor_value)
    |> or_where([s], s.date_of_sale == ^cursor_value and s.id < ^cursor_id)
  end

  defp greater_than_price(query, cursor_value, cursor_id) do
    query
    |> where([s], s.price_in_euros > ^cursor_value)
    |> or_where([s], s.price_in_euros == ^cursor_value and s.id > ^cursor_id)
  end

  defp less_than_price(query, cursor_value, cursor_id) do
    query
    |> where([s], s.price_in_euros < ^cursor_value)
    |> or_where([s], s.price_in_euros == ^cursor_value and s.id < ^cursor_id)
  end

  # the sort order should be flipped if we're paginating backwards,
  # and then re-flipped after the query is perfromed

  defp apply_order(query, %{"sort" => {field, order}, "cursor" => {_cursor, direction}}) do
    case {field, order, direction} do
      {"date", "desc", "before"} -> query |> ascending_by(:date_of_sale)
      {"date", "desc", "after"} -> query |> descending_by(:date_of_sale)
      {"date", "asc", "before"} -> query |> descending_by(:date_of_sale)
      {"date", "asc", "after"} -> query |> ascending_by(:date_of_sale)
      {"price", "desc", "before"} -> query |> ascending_by(:price_in_euros)
      {"price", "desc", "after"} -> query |> descending_by(:price_in_euros)
      {"price", "asc", "before"} -> query |> descending_by(:price_in_euros)
      {"price", "asc", "after"} -> query |> ascending_by(:price_in_euros)
    end
  end

  defp apply_order(query, %{"sort" => {field, order}}) do
    case {field, order} do
      {"date", "desc"} -> query |> descending_by(:date_of_sale)
      {"date", "asc"} -> query |> ascending_by(:date_of_sale)
      {"price", "desc"} -> query |> descending_by(:price_in_euros)
      {"price", "asc"} -> query |> ascending_by(:price_in_euros)
    end
  end

  defp ascending_by(query, field) do
    query |> order_by(asc: ^field, asc: :id)
  end

  defp descending_by(query, field) do
    query |> order_by(desc: ^field, desc: :id)
  end

  defp apply_limit(query, opts) do
    query |> limit(^opts["limit"])
  end

  # if we're paginating backwards, we need to flip the order of the results
  defp apply_corrective_flip(entries, %{"cursor" => {_cursor, "before"}}) do
    Enum.reverse(entries)
  end

  defp apply_corrective_flip(entries, _opts), do: entries

  # PEEK QUERIES

  defp set_peek_entry(_dir, [], _opts), do: nil

  defp set_peek_entry(:before, [first_entry | _], %{"sort" => {field, order}}) do
    if has_entry_in_direction?(field, order, first_entry, :before),
      do: first_entry,
      else: nil
  end

  defp set_peek_entry(:after, entries, %{"sort" => {field, order}}) do
    last_entry = List.last(entries)

    if has_entry_in_direction?(field, order, last_entry, :after),
      do: last_entry,
      else: nil
  end

  defp has_entry_in_direction?(
         "date",
         order,
         %ResidentialSale{id: id, date_of_sale: date},
         direction
       ),
       do:
         has_entry_in_direction_date(ResidentialSale, order, date, id, direction)
         |> Repo.exists?()

  defp has_entry_in_direction?(
         "price",
         order,
         %ResidentialSale{id: id, price_in_euros: price},
         direction
       ),
       do:
         has_entry_in_direction_price(ResidentialSale, order, price, id, direction)
         |> Repo.exists?()

  # date
  defp has_entry_in_direction_date(queryable, "asc", date, id, :before),
    do: less_than_date(queryable, date, id)

  defp has_entry_in_direction_date(queryable, "asc", date, id, :after),
    do: greater_than_date(queryable, date, id)

  defp has_entry_in_direction_date(queryable, "desc", date, id, :before),
    do: greater_than_date(queryable, date, id)

  defp has_entry_in_direction_date(queryable, "desc", date, id, :after),
    do: less_than_date(queryable, date, id)

  # price
  defp has_entry_in_direction_price(queryable, "asc", price, id, :before),
    do: less_than_price(queryable, price, id)

  defp has_entry_in_direction_price(queryable, "asc", price, id, :after),
    do: greater_than_price(queryable, price, id)

  defp has_entry_in_direction_price(queryable, "desc", price, id, :before),
    do: greater_than_price(queryable, price, id)

  defp has_entry_in_direction_price(queryable, "desc", price, id, :after),
    do: less_than_price(queryable, price, id)
end
