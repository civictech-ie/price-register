defmodule PprApi.ResidentialSales do
  import Ecto.Query, warn: false
  alias PprApi.Repo
  alias PprApi.Fetches
  alias PprApi.Fetches.Fetch
  alias PprApi.ResidentialSales.ResidentialSale
  alias PprApi.FingerprintHelper

  @doc """
  Lists residential sales with keyset pagination.
  Accepts options like:
    %{
      "sort" => "date-desc" | "date-asc" | "price-desc" | "price-asc",
      "after" => <base64 cursor> | "before" => <base64 cursor>,
      "limit" => "10" | "1000"
    }

  The keyset cursor is a Base64:
  - For a date sort, `sort_value` is the "YYYY-MM-DD" string.
  - For a price sort, `sort_value` is the stringified price in euros.
  """
  def list_residential_sales(opts \\ []) do
    opts = parse_opts(opts)

    entries =
      ResidentialSale
      |> apply_cursor(opts)
      |> apply_order(opts)
      |> apply_limit(opts)
      |> Repo.all()
      |> apply_corrective_flip(opts)

    has_next_page? = check_if_next_page?(entries, opts)
    has_prev_page? = check_if_prev_page?(entries, opts)

    after_entry =
      if has_next_page? do
        List.last(entries)
      else
        nil
      end

    before_entry =
      if has_prev_page? do
        List.first(entries)
      else
        nil
      end

    %{
      entries: entries,
      metadata: %{
        after_cursor: encode_cursor(after_entry, opts),
        before_cursor: encode_cursor(before_entry, opts),
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
      {%Fetch{} = fetch} -> fetch.total_rows
      _ -> 0
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
    |> Map.put("cursor", {decode_cursor(value, sort_field), "after"})
  end

  defp parse_cursor(%{"before" => value, "sort" => {sort_field, _sort_direction}} = opts) do
    opts
    |> Map.delete("before")
    |> Map.put("cursor", {decode_cursor(value, sort_field), "before"})
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

  # APPLY CORRECTIVE FLIP
  # if we're paginating backwards, we need to flip the order of the results
  defp apply_corrective_flip(entries, %{"cursor" => {_cursor, "before"}}) do
    Enum.reverse(entries)
  end

  defp apply_corrective_flip(entries, _opts), do: entries

  # ENCODE & DECODE

  defp encode_cursor(nil, _opts), do: nil

  # "date" sort => "YYYY-MM-DD-<id>"
  defp encode_cursor(%ResidentialSale{id: id, date_of_sale: date}, %{"sort" => {"date", _dir}}) do
    # Convert date to ISO8601, then combine with ID
    value_str = Date.to_iso8601(date)
    combined = "#{value_str}|#{id}"
    Base.url_encode64(combined, padding: false)
  end

  # "price" sort => "<price_in_euros>-<id>"
  defp encode_cursor(%ResidentialSale{id: id, price_in_euros: price}, %{"sort" => {"price", _dir}}) do
    value_str = to_string(price)
    combined = "#{value_str}|#{id}"
    Base.url_encode64(combined, padding: false)
  end

  # peek functions

  defp check_if_next_page?([], _opts), do: false

  defp check_if_next_page?(entries, opts) do
    # 1) Get the last entry in the current page
    last_entry = List.last(entries)
    encoded_cursor = encode_cursor(last_entry, opts)

    # 2) Build new opts with "after" that last entry
    new_opts =
      opts
      |> Map.delete("cursor")
      # just to be safe
      |> Map.delete("before")
      |> Map.put("after", encoded_cursor)

    # 3) Run the same pipeline with limit(1)
    ResidentialSale
    |> apply_cursor(new_opts)
    |> apply_order(new_opts)
    |> limit(1)
    |> Repo.exists?()
  end

  defp check_if_prev_page?([], _opts), do: false

  defp check_if_prev_page?(entries, opts) do
    # 1) Get the first entry in the current page
    first_entry = List.first(entries)
    encoded_cursor = encode_cursor(first_entry, opts)

    # 2) Build new opts with "before" that first entry
    new_opts =
      opts
      |> Map.delete("cursor")
      # just to be safe
      |> Map.delete("after")
      |> Map.put("before", encoded_cursor)

    # 3) Run the same pipeline with limit(1)
    ResidentialSale
    |> apply_cursor(new_opts)
    |> apply_order(new_opts)
    |> limit(1)
    |> Repo.exists?()
  end

  # fallback if sort or fields are unexpected
  defp encode_cursor(_entry, _opts), do: nil

  defp decode_cursor(nil, _field), do: nil

  defp decode_cursor(encoded, "date") do
    with {:ok, decoded} <- Base.url_decode64(encoded, padding: false),
         [val_str, raw_id] <- String.split(decoded, "|", parts: 2),
         {:ok, date} <- Date.from_iso8601(val_str),
         {id, ""} <- Integer.parse(raw_id) do
      {date, id}
    else
      _ -> nil
    end
  end

  defp decode_cursor(encoded, "price") do
    with {:ok, decoded} <- Base.url_decode64(encoded, padding: false),
         [val_str, raw_id] <- String.split(decoded, "|", parts: 2),
         {price, ""} <- Integer.parse(val_str),
         {id, ""} <- Integer.parse(raw_id) do
      {price, id}
    else
      _ -> nil
    end
  end

  defp decode_cursor(_encoded, _field), do: nil
end
