defmodule PprApi.ResidentialSales do
  import Ecto.Query, warn: false
  alias PprApi.Repo
  alias PprApi.ResidentialSales.ResidentialSale
  alias PprApi.FingerprintHelper
  alias PprApi.Pagination
  alias PprApi.Pagination.Cursor

  def list_residential_sales(opts \\ []) do
    entries =
      ResidentialSale
      |> apply_cursor(opts)
      |> apply_limit(opts["limit"])
      |> Repo.all()

    %{
      entries: entries,
      metadata: generate_metadata(entries, opts)
    }
  end

  @doc """
  Returns the date of the most recent residential sale.
  """
  def latest_sale_date do
    ResidentialSale
    |> select([s], max(s.date_of_sale))
    |> Repo.one()
  end

  @doc """
  Returns the current count of residential sales.
  """
  def total_residential_sales do
    case Fetches.get_latest_successful_fetch() do
      {:ok, fetch} -> fetch.total_rows
      {:error, _reason} -> 0
    end
  end

  @doc """
  Gets a single residential_sale.
  Raises `Ecto.NoResultsError` if the Residential sale does not exist.
  """
  def get_residential_sale!(id), do: Repo.get!(ResidentialSale, id)

  @doc """
  Inserts residential sales in batches of 1000.
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

    # Remove duplicate fingerprints within the batch
    unique_rows = remove_duplicate_fingerprints(rows_with_fingerprints)

    # Perform the bulk upsert, counting only inserted rows
    {rows_inserted, _} =
      Repo.insert_all(
        ResidentialSale,
        unique_rows,
        on_conflict: [set: [updated_at: now]],
        conflict_target: :fingerprint
      )

    rows_inserted
  end

  # Helper to remove duplicate fingerprints, keeping the first occurrence
  defp remove_duplicate_fingerprints(rows_with_fingerprints) do
    rows_with_fingerprints
    |> Enum.reduce(%{}, fn row, acc ->
      Map.put_new(acc, row.fingerprint, row)
    end)
    |> Map.values()
  end

  defp apply_cursor(query, opts) do
    case {opts["before"], opts["after"]} do
      {nil, nil} ->
        query

      {before_cursor, nil} ->
        apply_cursor(query, parse_sort_param(opts["sort"]), {:before, before_cursor})

      {nil, after_cursor} ->
        apply_cursor(query, parse_sort_param(opts["sort"]), {:after, after_cursor})
    end
  end

  def apply_cursor(query, {sort_field, sort_direction}, {cursor_direction, cursor}) do
    {:ok, {sort_value, sort_id}} = Cursor.decode_cursor(cursor, sort_field)
    operator = determine_operator(sort_direction, cursor_direction)

    case sort_field do
      :date_of_sale ->
        query |> where(^build_date_of_sale_condition(sort_value, sort_id, operator))

      :price_in_euros ->
        query |> where(^build_price_in_euros_condition(sort_value, sort_id, operator))

      _ ->
        query
    end
  end

  defp build_date_of_sale_condition(sort_value, sort_id, :gt) do
    dynamic(
      [m],
      m.date_of_sale > ^sort_value or
        (m.date_of_sale == ^sort_value and m.id > ^sort_id)
    )
  end

  defp build_date_of_sale_condition(sort_value, sort_id, :lt) do
    dynamic(
      [m],
      m.date_of_sale < ^sort_value or
        (m.date_of_sale == ^sort_value and m.id < ^sort_id)
    )
  end

  defp build_price_in_euros_condition(sort_value, sort_id, :gt) do
    dynamic(
      [m],
      m.price_in_euros > ^sort_value or
        (m.price_in_euros == ^sort_value and m.id > ^sort_id)
    )
  end

  defp build_price_in_euros_condition(sort_value, sort_id, :lt) do
    dynamic(
      [m],
      m.price_in_euros < ^sort_value or
        (m.price_in_euros == ^sort_value and m.id < ^sort_id)
    )
  end

  defp determine_operator("asc", :after), do: :gt
  defp determine_operator("asc", :before), do: :lt
  defp determine_operator("desc", :after), do: :lt
  defp determine_operator("desc", :before), do: :gt

  defp apply_sorting(query, "price", "asc"),
    do: order_by(query, [rs], asc: rs.price_in_euros, asc: rs.id)

  defp apply_sorting(query, "price", "desc"),
    do: order_by(query, [rs], desc: rs.price_in_euros, desc: rs.id)

  defp apply_sorting(query, "date", "asc"),
    do: order_by(query, [rs], asc: rs.date_of_sale, asc: rs.id)

  defp apply_sorting(query, "date", "desc"),
    do: order_by(query, [rs], desc: rs.date_of_sale, desc: rs.id)

  defp apply_cursor(query, _), do: query

  defp apply_limit(query, limit \\ 250)

  defp apply_limit(query, limit) when is_integer(limit) do
    effective_limit = Enum.min([limit, Pagination.max_limit()])
    limit(query, ^effective_limit)
  end

  defp apply_limit(query, limit) when is_binary(limit) do
    apply_limit(query, String.to_integer(limit))
  end

  defp parse_sort_param(sort_param) do
    case String.split(sort_param, "-") do
      [field, direction] -> {field, direction}
      [field] -> {field, "desc"}
    end
  end

  # Generate either an 'after' or 'before' cursor based on the position of the entry
  defp generate_cursor(nil, _), do: nil

  defp generate_cursor(entry, sort_field) do
    Cursor.encode_cursor(entry, sort_field)
  end

  defp generate_metadata(entries, opts) do
    {sort_field, _direction} = parse_sort_param(opts["sort"])
    after_cursor = generate_cursor(List.last(entries), sort_field)
    before_cursor = generate_cursor(List.first(entries), sort_field)

    %{
      after: after_cursor,
      before: before_cursor
    }
  end
end
