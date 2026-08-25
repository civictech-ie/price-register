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
  def list_residential_sales(opts \\ %{}) do
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
  #      "before" => <cursor> -> "cursor" => {{value, id}, "before"}
  def parse_sort(sort) when is_binary(sort) do
    case String.split(sort, "-") do
      [field, direction] when field in ["date", "price"] and direction in ["asc", "desc"] ->
        {:ok, {field, direction}}

      _ ->
        :error
    end
  end

  # an already-parsed sort tuple passes through unchanged, so callers that
  # parse the sort themselves (e.g. the API controller) aren't re-parsed
  # into the default
  def parse_sort({field, direction})
      when field in ["date", "price"] and direction in ["asc", "desc"],
      do: {:ok, {field, direction}}

  def parse_sort(_), do: :error

  defp parse_opts(opts) do
    opts
    |> Map.update("sort", {"date", "desc"}, fn sort ->
      case parse_sort(sort) do
        {:ok, tuple} -> tuple
        :error -> {"date", "desc"}
      end
    end)
    |> parse_cursor()
    |> parse_limit()
  end

  # resolves the "after"/"before" params into a single "cursor" option.
  # "after" wins when both are present; nil and undecodable cursors are
  # dropped so the query falls back to the first page.
  defp parse_cursor(%{"sort" => {sort_field, _direction}} = opts) do
    cursor =
      case {opts["after"], opts["before"]} do
        {after_cursor, _} when is_binary(after_cursor) ->
          decode_cursor(after_cursor, sort_field, "after")

        {_, before_cursor} when is_binary(before_cursor) ->
          decode_cursor(before_cursor, sort_field, "before")

        _ ->
          nil
      end

    opts = Map.drop(opts, ["after", "before"])

    case cursor do
      nil -> opts
      cursor -> Map.put(opts, "cursor", cursor)
    end
  end

  defp decode_cursor(encoded, sort_field, direction) do
    case Cursor.decode_cursor(encoded, sort_field) do
      {value, id} -> {{value, id}, direction}
      nil -> nil
    end
  end

  @max_limit 1000
  @default_limit 250

  defp parse_limit(opts) when is_map(opts) do
    opts
    |> Map.put("limit", parse_limit(opts["limit"]))
  end

  defp parse_limit(limit) when is_number(limit) do
    limit |> min(@max_limit) |> max(0)
  end

  defp parse_limit(limit) when is_binary(limit) do
    case Integer.parse(limit) do
      {num, _} -> parse_limit(num)
      :error -> @default_limit
    end
  end

  defp parse_limit(_), do: @default_limit

  # The Actual Query

  # cursor predicates are PostgreSQL row-value comparisons, e.g.
  # (date_of_sale, id) < ($1, $2), so the planner can use the composite
  # (date_of_sale, id) / (price_in_euros, id) indexes as access conditions
  # instead of filtering every row.

  defp get_sales_and_peek(opts) do
    base_query = current_snapshot_query()

    entries =
      base_query
      |> apply_cursor(opts)
      |> apply_order(opts)
      |> apply_limit(opts)
      |> Repo.all()
      |> apply_corrective_flip(opts)

    before_entry = set_peek_entry(:before, entries, opts, base_query)
    after_entry = set_peek_entry(:after, entries, opts, base_query)

    {before_entry, entries, after_entry}
  end

  # restricts rows to the latest successful full fetch; the same base query
  # is used for the page query and the peek queries
  defp current_snapshot_query do
    case Fetches.get_latest_successful_full_fetch() do
      %Fetch{started_at: %DateTime{} = started_at} ->
        ResidentialSale |> where([s], s.updated_at >= ^started_at)

      _ ->
        ResidentialSale
    end
  end

  # if i'm ascending and paginating forwards (after), i want the entries
  # greater than the cursor; paginating backwards (before), the entries
  # less than it. descending flips both.
  defp apply_cursor(query, %{"cursor" => {{value, id}, direction}, "sort" => {field, order}}) do
    case cursor_operator(direction, order) do
      :gt -> row_greater_than(query, sort_column(field), value, id)
      :lt -> row_less_than(query, sort_column(field), value, id)
    end
  end

  defp apply_cursor(query, _opts), do: query

  defp cursor_operator("after", "asc"), do: :gt
  defp cursor_operator("before", "asc"), do: :lt
  defp cursor_operator("after", "desc"), do: :lt
  defp cursor_operator("before", "desc"), do: :gt

  defp row_greater_than(query, column, value, id) do
    query
    |> where([s], fragment("(?, ?) > (?, ?)", field(s, ^column), s.id, ^value, ^id))
  end

  defp row_less_than(query, column, value, id) do
    query
    |> where([s], fragment("(?, ?) < (?, ?)", field(s, ^column), s.id, ^value, ^id))
  end

  defp sort_column("date"), do: :date_of_sale
  defp sort_column("price"), do: :price_in_euros

  # the sort order is flipped while querying backwards (before), and the
  # rows are re-flipped after the query is performed
  defp apply_order(query, %{"sort" => {field, order}} = opts) do
    order =
      case opts do
        %{"cursor" => {_cursor, "before"}} -> flip_order(order)
        _ -> order
      end

    direction = order_direction(order)
    column = sort_column(field)

    order_by(query, [s], [{^direction, field(s, ^column)}, {^direction, s.id}])
  end

  defp flip_order("asc"), do: "desc"
  defp flip_order("desc"), do: "asc"

  defp order_direction("asc"), do: :asc
  defp order_direction("desc"), do: :desc

  defp apply_limit(query, opts) do
    query |> limit(^opts["limit"])
  end

  # if we're paginating backwards, we need to flip the order of the results
  defp apply_corrective_flip(entries, %{"cursor" => {_cursor, "before"}}) do
    Enum.reverse(entries)
  end

  defp apply_corrective_flip(entries, _opts), do: entries

  # PEEK QUERIES

  # a peek asks: is there at least one row beyond this edge entry in the
  # given direction? it reuses apply_cursor, so it runs the same row-value
  # comparison against the same snapshot as the page query.

  defp set_peek_entry(_direction, [], _opts, _base_query), do: nil

  defp set_peek_entry(:before, [first_entry | _], opts, base_query) do
    if has_entry_in_direction?(base_query, first_entry, "before", opts),
      do: first_entry,
      else: nil
  end

  defp set_peek_entry(:after, entries, opts, base_query) do
    last_entry = List.last(entries)

    if has_entry_in_direction?(base_query, last_entry, "after", opts),
      do: last_entry,
      else: nil
  end

  defp has_entry_in_direction?(base_query, entry, direction, %{"sort" => {field, _order} = sort}) do
    value = Map.fetch!(entry, sort_column(field))

    base_query
    |> apply_cursor(%{"cursor" => {{value, entry.id}, direction}, "sort" => sort})
    |> Repo.exists?()
  end
end
