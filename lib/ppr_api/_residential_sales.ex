# defmodule PprApi.ResidentialSales do
#   import Ecto.Query, warn: false
#   alias PprApi.Repo
#   alias PprApi.Fetches
#   alias PprApi.Fetches.Fetch
#   alias PprApi.ResidentialSales.ResidentialSale
#   alias PprApi.FingerprintHelper

#   def list_residential_sales(opts \\ []) do
#     opts = parse_opts(opts)

#     entries =
#       ResidentialSale
#       |> apply_cursor(opts)
#       |> apply_order(opts)
#       |> apply_limit(opts)
#       |> Repo.all()

#     entries =
#       case opts["cursor"] do
#         {_value, "before"} -> Enum.reverse(entries)
#         _ -> entries
#       end

#     after_entry = hd(Enum.reverse(entries))
#     before_entry = hd(entries)

#     %{
#       entries: entries,
#       metadata: %{
#         after_cursor: encode_cursor(after_entry),
#         before_cursor: encode_cursor(before_entry),
#         limit: opts["limit"],
#         sort:
#           opts["sort"]
#           |> Tuple.to_list()
#           |> Enum.join("-"),
#         total_rows: total_residential_sales()
#       }
#     }
#   end

#   @doc """
#   Returns the date of the most recent residential sale.
#   """
#   def latest_sale_date do
#     ResidentialSale
#     |> select([s], max(s.date_of_sale))
#     |> Repo.one()
#   end

#   @doc """
#   Returns the current count of residential sales.
#   """
#   def total_residential_sales do
#     case Fetches.get_latest_successful_fetch() do
#       {%Fetch{} = fetch} -> fetch.total_rows
#       _ -> 0
#     end
#   end

#   @doc """
#   Gets a single residential_sale.
#   Raises `Ecto.NoResultsError` if the Residential sale does not exist.
#   """
#   def get_residential_sale!(id), do: Repo.get!(ResidentialSale, id)

#   @doc """
#   Inserts residential sales in batches of 1000.
#   """
#   def upsert_rows(rows) do
#     batch_size = 1000

#     rows
#     |> Enum.chunk_every(batch_size)
#     |> Enum.reduce(0, fn chunk, acc ->
#       inserted = upsert_batch(chunk)
#       acc + inserted
#     end)
#   end

#   defp upsert_batch(rows) do
#     now = DateTime.utc_now() |> DateTime.truncate(:second)

#     rows_with_fingerprints =
#       Enum.map(rows, fn row ->
#         row
#         |> Map.put(:fingerprint, FingerprintHelper.compute_fingerprint(row))
#         |> Map.put(:inserted_at, now)
#         |> Map.put(:updated_at, now)
#       end)

#     # Remove duplicate fingerprints within the batch
#     unique_rows = remove_duplicate_fingerprints(rows_with_fingerprints)

#     # Perform the bulk upsert, counting only inserted rows
#     {rows_inserted, _} =
#       Repo.insert_all(
#         ResidentialSale,
#         unique_rows,
#         on_conflict: [set: [updated_at: now]],
#         conflict_target: :fingerprint
#       )

#     rows_inserted
#   end

#   # Helper to remove duplicate fingerprints, keeping the first occurrence
#   defp remove_duplicate_fingerprints(rows_with_fingerprints) do
#     rows_with_fingerprints
#     |> Enum.reduce(%{}, fn row, acc ->
#       Map.put_new(acc, row.fingerprint, row)
#     end)
#     |> Map.values()
#   end

#   # parsing stuff
#   #
#   # e.g. %{"before" => "706867", "limit" => "100", "sort" => "date-desc"}

#   defp parse_opts(opts) do
#     opts
#     |> parse_cursor()
#     |> parse_limit()
#     |> parse_sort()
#   end

#   defp parse_cursor(opts) do
#     case Enum.find(["after", "before"], &Map.has_key?(opts, &1)) do
#       nil ->
#         opts

#       key ->
#         opts
#         |> Map.delete(key)
#         |> Map.put("cursor", {opts[key], key})
#     end
#   end

#   defp parse_limit(opts) when is_map(opts) do
#     opts
#     |> Map.put("limit", parse_limit(opts["limit"]))
#   end

#   defp parse_limit(limit) when is_number(limit) do
#     limit
#   end

#   defp parse_limit(limit) when is_binary(limit) do
#     case Integer.parse(limit) do
#       {num, _} -> num
#     end
#   end

#   defp parse_sort(opts) when is_map(opts) do
#     opts
#     |> Map.update("sort", nil, fn sort ->
#       case String.split(sort, "-") do
#         [field, direction] -> {field, direction}
#         _ -> nil
#       end
#     end)
#   end

#   defp apply_cursor(query, %{
#          "cursor" => {cursor_value, cursor_direction},
#          "sort" => {_sort_field, sort_direction}
#        }) do
#     case determine_operator(sort_direction, cursor_direction) do
#       :lt -> query |> where([s], s.id < ^cursor_value)
#       :gt -> query |> where([s], s.id > ^cursor_value)
#     end
#   end

#   defp apply_cursor(query, _opts) do
#     query
#   end

#   defp determine_operator(sort_direction, cursor_direction) do
#     case {sort_direction, cursor_direction} do
#       {"asc", "before"} -> :lt
#       {"asc", "after"} -> :gt
#       {"desc", "before"} -> :gt
#       {"desc", "after"} -> :lt
#     end
#   end

#   defp apply_order(query, opts) do
#     query |> order_by(desc: :id)
#   end

#   defp apply_limit(query, opts) do
#     query |> limit(^opts["limit"])
#   end

#   defp encode_cursor(entry) do
#     entry.id
#   end

#   defp decode_cursor(cursor) do
#     cursor
#     |> Integer.parse()
#     |> elem(0)
#   end
# end
