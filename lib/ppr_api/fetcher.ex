defmodule PprApi.Fetcher do
  alias PprApi.{ResidentialSales, Fetches}
  alias PprApi.Fetches.Fetch
  alias NimbleCSV.RFC4180, as: CSV

  @base_url "https://propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/"
  @wait_time 5_000

  defp csv_persistence_enabled? do
    System.get_env("SAVE_FETCH_CSV") == "true"
  end

  defp csv_file_path_for(%Fetch{id: id}) do
    # If you prefer a different path or want to read from another env var, change here:
    Path.join("/data", "full_fetch_#{id}.csv")
  end

  defp write_csv_headers(io_device) do
    headers = [
      "date_of_sale",
      "address",
      "county",
      "eircode",
      "price_in_euros",
      "not_full_market_price",
      "vat_exclusive",
      "description_of_property",
      "property_size_description"
    ]

    IO.write(io_device, CSV.dump_to_iodata([headers]))
  end

  defp write_csv_rows(rows, io_device) do
    # Convert each row map back into a list matching the columns, then dump them via NimbleCSV
    row_lists =
      Enum.map(rows, fn row ->
        [
          date_to_string(row.date_of_sale),
          row.address,
          row.county,
          row.eircode,
          Decimal.to_string(row.price_in_euros),
          bool_to_string(row.not_full_market_price),
          bool_to_string(row.vat_exclusive),
          row.description_of_property,
          row.property_size_description
        ]
      end)

    IO.write(io_device, CSV.dump_to_iodata(row_lists))
  end

  defp date_to_string(%Date{} = d), do: "#{d.day}/#{d.month}/#{d.year}"
  defp bool_to_string(true), do: "yes"
  defp bool_to_string(false), do: "no"

  @doc """
  Fetches from PPR, month by month, from fetch.starts_on up to the current month.
  Only works if fetch is in the "starting" state.
  Updates `Fetch` record as it progresses, marking success or error on completion.

  (Minimal addition) If SAVE_FETCH_CSV="true", writes all fetched rows to a single CSV on disk at /data.
  """
  def run_fetch(%Fetch{status: "starting"} = fetch) do
    try do
      # Mark as fetching:
      fetch = Fetches.mark_fetch_as_fetching(fetch)

      if csv_persistence_enabled?() do
        file_path = csv_file_path_for(fetch)
        {:ok, io_device} = File.open(file_path, [:write])

        write_csv_headers(io_device)

        fetch_months_recursively_with_csv(fetch, fetch.starts_on, io_device)

        File.close(io_device)
      else
        fetch_months_recursively(fetch, fetch.starts_on)
      end

      # Mark success
      Fetches.mark_fetch_success(fetch)
    rescue
      e ->
        Fetches.mark_fetch_error(fetch, Exception.message(e))
    end
  end

  def run_fetch(%Fetch{status: status} = _fetch) do
    {:error, "Cannot run fetch because its current state is '#{status}'."}
  end

  defp fetch_months_recursively(%Fetch{} = fetch, %Date{} = current_date) do
    Process.sleep(@wait_time)

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

    if Date.compare(next_month, Date.utc_today() |> Date.beginning_of_month()) in [:lt, :eq] do
      fetch_months_recursively(fetch, next_month)
    end

    fetch
  end

  defp fetch_months_recursively_with_csv(%Fetch{} = fetch, %Date{} = current_date, io_device) do
    Process.sleep(@wait_time)

    rows =
      current_date
      |> fetch_data_for_month()
      |> parse_csv()

    upsert_rows(rows)
    write_csv_rows(rows, io_device)
    update_fetch_progress(length(rows), fetch, current_date)

    next_month =
      current_date
      |> Date.end_of_month()
      |> Date.add(1)
      |> Date.beginning_of_month()

    if Date.compare(next_month, Date.utc_today() |> Date.beginning_of_month()) in [:lt, :eq] do
      fetch_months_recursively_with_csv(fetch, next_month, io_device)
    end

    fetch
  end

  # The rest: unchanged code

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

  defp parse_csv(csv_data) do
    csv_data
    |> CSV.parse_string(skip_headers: true)
    |> Enum.map(&parse_row/1)
  end

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

  defp parse_column(:date_of_sale, value), do: value |> normalise_text() |> parse_date()
  defp parse_column(:price_in_euros, value), do: value |> normalise_text() |> parse_price()

  defp parse_column(:not_full_market_price, value),
    do: value |> normalise_text() |> parse_boolean()

  defp parse_column(:vat_exclusive, value),
    do: value |> normalise_text() |> parse_boolean()

  defp parse_column(_other_key, value), do: parse_text(value)

  defp parse_text(value) do
    value
    |> to_string()
    |> String.trim()
  end

  defp parse_date(date_str) do
    [day, month, year] =
      date_str
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    Date.new!(year, month, day)
  end

  defp parse_price("€" <> rest), do: parse_price(rest)

  defp parse_price(str) do
    str |> String.replace(",", "") |> Decimal.new()
  end

  defp parse_boolean("yes"), do: true
  defp parse_boolean("no"), do: false
  defp parse_boolean(other), do: parse_boolean(normalise_text(other))
  defp normalise_text(str), do: str |> String.downcase() |> String.trim()

  defp upsert_rows(rows), do: ResidentialSales.upsert_rows(rows)

  defp update_fetch_progress(count, fetch, current_month) do
    Fetches.update_fetch_progress(fetch, %{
      status: "fetching",
      current_month: current_month,
      increment_by: count
    })
  end
end
