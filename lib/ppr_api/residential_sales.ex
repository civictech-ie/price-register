defmodule PprApi.ResidentialSales do
  import Ecto.Query, warn: false
  alias PprApi.Repo
  alias PprApi.ResidentialSales.ResidentialSale
  alias PprApi.FingerprintHelper
  alias PprApi.Pagination

  @doc """
  Returns the list of residential_sales ordered by date of sale.
  """
  def list_residential_sales(opts \\ []) do
    ResidentialSale
    |> order_by([rs], desc: rs.date_of_sale, desc: rs.inserted_at, desc: rs.id)
    |> Pagination.paginate(Repo, opts)
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
  Gets a single residential_sale.

  Raises `Ecto.NoResultsError` if the Residential sale does not exist.
  """
  def get_residential_sale!(id), do: Repo.get!(ResidentialSale, id)

  @doc """
  Inserts residential sales in batches of 1000.
  """

  def upsert_rows(rows) do
    # Define the batch size
    batch_size = 1000

    # Split rows into chunks of batch_size
    rows
    |> Enum.chunk_every(batch_size)
    |> Enum.reduce(0, fn chunk, acc ->
      # Process each chunk and get the count of inserted rows
      inserted = upsert_batch(chunk)

      # Add to the total count
      acc + inserted
    end)
  end

  defp upsert_batch(rows) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Add fingerprints and timestamps
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
end
