defmodule PprApi.Fetcher do
  alias PprApi.{ResidentialSales, Fetches}
  alias PprApi.Fetches.Fetch
  alias NimbleCSV.RFC4180, as: CSV

  @base_url "https://propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/"
  @wait_time 5_000
  @csv_dir System.get_env("FETCH_CSV_DIR") || "./priv/fetches"

  @doc """
  Fetches from PPR, month by month, from fetch.starts_on up to the current month.
  Only works if fetch is in the "starting" state.
  Updates `Fetch` record as it progresses, marking success or error on completion.
  """
  def run_fetch(%Fetch{status: "starting"} = fetch) do
    try do
      fetch
      |> Fetches.mark_fetch_as_fetching()
      |> fetch_months_recursively(fetch.starts_on, csv_saving_enabled?())
      |> Fetches.mark_fetch_success()
    rescue
      e ->
        Appsignal.set_error(e, __STACKTRACE__)
        Fetches.mark_fetch_error(fetch, Exception.message(e))
    end
  end

  def run_fetch(%Fetch{status: status} = _fetch) do
    {:error, "Cannot run fetch because its current state is '#{status}'."}
  end

  defp csv_saving_enabled? do
    case System.get_env("SAVE_FETCH_CSV") do
      "true" -> true
      _ -> false
    end
  end

  # We recursively fetch from `current_date` until we reach today's month
  defp fetch_months_recursively(%Fetch{} = fetch, %Date{} = current_date, save_csv) do
    Process.sleep(@wait_time)

    current_date
    |> fetch_data_for_month()
    |> parse_csv()
    |> upsert_rows(fetch, save_csv)
    |> update_fetch_progress(fetch, current_date)

    next_month =
      current_date
      |> Date.end_of_month()
      |> Date.add(1)
      |> Date.beginning_of_month()

    # Keep going if we're still behind the current month
    if Date.compare(next_month, Date.utc_today() |> Date.beginning_of_month()) in [:lt, :eq] do
      fetch_months_recursively(fetch, next_month, save_csv)
    end

    fetch
  end

  # Builds the URL and fetches the CSV data for a given Date, returns "" if not a CSV
  defp fetch_data_for_month(%Date{} = date) do
    case HTTPoison.get(url_for_month(date), %{}, hackney: [:insecure]) do
        {:ok, %HTTPoison.Response{status_code: 200, headers: headers, body: body}} ->
          if content_type_csv?(headers) do
            body
          else
            ""
          end
        {:ok, _response} ->
          ""
        {:error, reason} ->
          raise "Error fetching CSV for #{date}: #{inspect(reason)}"
      end
  end

  defp url_for_month(%Date{year: year, month: month}) do
    year_str = Integer.to_string(year)
    month_str = month |> Integer.to_string() |> String.pad_leading(2, "0")
    csv_file = "PPR-#{year_str}-#{month_str}.csv"

    "#{@base_url}#{csv_file}/$FILE/#{csv_file}"
  end

  # Parses CSV data into a list of maps that match the ResidentialSale fields
  defp parse_csv(""), do: []

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

  defp upsert_rows(rows, %Fetch{started_at: started_at, starts_on: starts_on}, true) do
    File.mkdir_p!(@csv_dir)

    filename =
      Path.join(
        @csv_dir,
        "#{Date.to_string(starts_on)}-#{DateTime.to_date(started_at) |> Date.to_string()}.csv"
      )

    columns = [
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

    unless File.exists?(filename) do
      # Convert column names (atoms) to strings for the header.
      header = [Enum.map(columns, &Atom.to_string/1)]
      header_iodata = CSV.dump_to_iodata(header)
      File.write!(filename, header_iodata)
    end

    data_rows =
      rows
      |> Enum.map(fn row ->
        Enum.map(columns, &format_value_for_csv(Map.get(row, &1)))
      end)

    data_iodata = CSV.dump_to_iodata(data_rows)
    File.write!(filename, data_iodata, [:append])

    upsert_rows(rows, %Fetch{}, false)
  end

  defp upsert_rows(rows, _fetch, false) do
    # Upsert rows into the database, returning the count of upserted rows
    ResidentialSales.upsert_rows(rows)
  end

  defp format_value_for_csv(value) do
    cond do
      is_nil(value) ->
        ""

      match?(%Decimal{}, value) ->
        Decimal.to_string(value)

      match?(%Date{}, value) ->
        Date.to_string(value)

      is_boolean(value) ->
        to_string(value)

      true ->
        to_string(value)
    end
  end

  defp update_fetch_progress(rows, fetch, current_month) do
    fetch
    |> Fetches.update_fetch_progress(%{
      status: "fetching",
      current_month: current_month,
      increment_by: rows
    })
  end

  defp content_type_csv?(headers) do
    headers
    |> Enum.any?(fn {key, val} ->
      String.downcase(key) == "content-type" and
        String.downcase(val) =~ "text/csv"
    end)
  end
end
