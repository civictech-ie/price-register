defmodule PprApi.Fetcher do
  alias PprApi.{ResidentialSales, Fetches}
  alias PprApi.Fetches.Fetch
  alias NimbleCSV.RFC4180, as: CSV

  @base_url "https://propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/"
  @wait_time 2_000

  @doc """
  Fetches from PPR, month by month, from fetch.starts_on up to the current month.
  Only works if fetch is in the "starting" state.
  Updates `Fetch` record as it progresses, marking success or error on completion.
  """
  def run_fetch(%Fetch{status: "starting"} = fetch) do
    try do
      fetch
      |> Fetches.mark_fetch_as_fetching()
      |> fetch_months_recursively(fetch.starts_on)
      # Mark success at the end
      |> Fetches.mark_fetch_success()
    rescue
      e ->
        # On error, record the message
        Fetches.mark_fetch_error(fetch, Exception.message(e))
    end
  end

  def run_fetch(%Fetch{status: status} = _fetch) do
    {:error, "Cannot run fetch because its current state is '#{status}'."}
  end

  # We recursively fetch from `current_date` until we reach today's month
  defp fetch_months_recursively(%Fetch{} = fetch, %Date{} = current_date) do
    if Mix.env() != :test do
      Process.sleep(@wait_time)
    end

    current_date
    |> fetch_data_for_month()
    |> parse_csv()
    |> upsert_rows()
    |> update_fetch_progress(fetch, current_date)

    next_month =
      current_date
      |> Date.end_of_month()
      |> Date.add(1)
      |> Date.beginning_of_month()

    # Keep going if we're still behind the current month
    if Date.compare(next_month, Date.utc_today() |> Date.beginning_of_month()) == :lt do
      fetch_months_recursively(fetch, next_month)
    end

    fetch
  end

  # Builds the URL and fetches the CSV data for a given Date
  defp fetch_data_for_month(%Date{} = date) do
    %{body: body} =
      date
      |> url_for_month()
      |> HTTPoison.get!(%{}, hackney: [:insecure])

    body
  end

  defp url_for_month(%Date{year: year, month: month}) do
    year_str = Integer.to_string(year)
    month_str = month |> Integer.to_string() |> String.pad_leading(2, "0")
    csv_file = "PPR-#{year_str}-#{month_str}.csv"

    "#{@base_url}#{csv_file}/$FILE/#{csv_file}"
  end

  # Parses CSV data into a list of maps that match the ResidentialSale fields
  defp parse_csv(csv_data) do
    csv_data
    |> CSV.parse_string(skip_headers: true)
    |> Enum.map(&parse_row/1)
  end

  # Convert a single CSV row into a map (with the same keys as ResidentialSale)
  defp parse_row(row_data) do
    keys = [
      :date_of_sale,
      :address,
      :county,
      :eircode,
      :price_in_euros,
      :not_full_market_price,
      :vat_exclusive,
      :description_of_property,
      :property_size_description
    ]

    row_data
    |> decode_cp1252()
    |> Enum.zip(keys)
    |> Enum.into(%{}, fn {raw_value, key} ->
      {key, parse_column(key, raw_value)}
    end)
  end

  defp decode_cp1252(row) do
    Enum.map(row, &Mbcs.decode!(&1, :cp1252))
  end

  # Pattern-match on certain fields, else treat as text
  defp parse_column(:date_of_sale, value), do: value |> normalise_text() |> parse_date()
  defp parse_column(:price_in_euros, value), do: value |> normalise_text() |> parse_price()

  defp parse_column(:not_full_market_price, value),
    do: value |> normalise_text() |> parse_boolean()

  defp parse_column(:vat_exclusive, value), do: value |> normalise_text() |> parse_boolean()
  defp parse_column(_other_key, value), do: parse_text(value)

  defp parse_text(value) do
    value
    |> to_string()
    |> String.trim()
  end

  # Date strings come in as DD/MM/YYYY
  defp parse_date(date_str) do
    [day, month, year] =
      date_str
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    Date.new!(year, month, day)
  end

  # Price strings might have "€" or commas
  defp parse_price("€" <> rest), do: parse_price(rest)

  defp parse_price(str) do
    str
    |> String.replace(",", "")
    |> Decimal.new()
  end

  # Convert "yes"/"no" to booleans
  defp parse_boolean("yes"), do: true
  defp parse_boolean("no"), do: false
  defp parse_boolean(other), do: parse_boolean(normalise_text(other))

  defp normalise_text(str), do: str |> String.downcase() |> String.trim()

  defp upsert_rows(rows) do
    # Upsert rows into the database, returning the count of upserted rows
    ResidentialSales.upsert_rows(rows)
  end

  defp update_fetch_progress(count, fetch, current_month) do
    fetch
    |> Fetches.update_fetch_progress(%{
      status: "fetching",
      current_month: current_month,
      increment_by: count
    })
  end
end
