defmodule PriceRegister.Fetcher do
  @moduledoc """
  The Fetcher module is responsible for fetching the data from the property price register.
  """

  alias Phoenix.PubSub
  alias PriceRegister.Properties
  alias NimbleCSV.RFC4180, as: CSV

  @base_url "https://propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/"
  @first_date ~D[2010-01-01]
  @wait_time 2_000

  @table :fetcher_status
  @topic "fetcher_status"

  @doc """
  Fetches the data from the property price register.
  """
  def fetch() do
    fetch_month_and_keep_going(@first_date)
  end

  defp fetch_month_and_keep_going(%Date{} = date) do
    # slow down the requests to avoid being blocked
    Process.sleep(@wait_time)

    fetch_and_insert_a_month(date)
    next_month = date |> Date.end_of_month() |> Date.add(1)

    if next_month < Date.utc_today() do
      fetch_month_and_keep_going(next_month)
    end
  end

  defp fetch_and_insert_a_month(date) do
    update_fetcher_status("Fetching #{Date.to_string(date)}")

    fetch_data_for_month(date)
    |> parse_csv
    |> insert_data_if_different(date)
  end

  # if data for this month is different to what we have in the database, delete all the data for this month and insert the new data
  defp insert_data_if_different(data, date) do
    if data_is_different?(data, date) do
      update_fetcher_status("Inserting #{Date.to_string(date)}")
      Properties.delete_sales_for_month(date)
      insert_data(data)
    end
  end

  defp data_is_different?(prospective_data, date) do
    existing_data = Properties.list_sales_for_month(date)

    different_length?(prospective_data, existing_data) ||
      different_data?(prospective_data, existing_data)
  end

  defp different_data?(prospective_data, existing_data) do
    prospective_data =
      Enum.sort_by(prospective_data, fn row ->
        {row.price_in_cents, row.date_of_sale, row.address}
      end)

    existing_data =
      Enum.sort_by(existing_data, fn row ->
        {row.price_in_cents, row.date_of_sale, row.address}
      end)

    check_row_is_different_or_keep_going(0, prospective_data, existing_data)
  end

  defp different_length?(prospective_data, existing_data) do
    length(prospective_data) != length(existing_data)
  end

  defp check_row_is_different_or_keep_going(_index, [], []) do
    false
  end

  defp check_row_is_different_or_keep_going(index, [prospective_row | prospective_data], [
         existing_row | existing_data
       ]) do
    if different_row?(prospective_row, existing_row) do
      true
    else
      check_row_is_different_or_keep_going(index + 1, prospective_data, existing_data)
    end
  end

  defp different_row?(prospective_row, existing_row) do
    # run through each column in row_a and check if they are different
    if Enum.any?(prospective_row, fn {key, value} -> value != Map.get(existing_row, key) end) do
      IO.puts("mismatch found!!!")
      IO.inspect(prospective_row)
      IO.inspect(existing_row)
      true
    else
      false
    end
  end

  defp insert_data(data) do
    data
    |> set_timestamps()
    |> Properties.insert_sales_in_batches()
  end

  defp fetch_data_for_month(date) do
    %{body: body} =
      url_for_month(date)
      |> HTTPoison.get!(%{}, hackney: [:insecure])

    body
  end

  defp parse_csv(body) when is_binary(body) do
    body
    |> CSV.parse_string(skip_headers: true)
    |> raw_data_to_sale_map()
  end

  def url_for_month(%Date{year: year, month: month}) do
    year_str = year |> Integer.to_string()
    month_str = month |> Integer.to_string() |> String.pad_leading(2, "0")

    @base_url <> "PPR-#{year_str}-#{month_str}.csv/$FILE/PPR-#{year_str}-#{month_str}.csv"
  end

  defp raw_data_to_sale_map(rows) when is_list(rows) do
    rows
    |> Enum.map(&row_to_sale_map/1)
  end

  # takes a row of data and converts it into a map
  defp row_to_sale_map(row) do
    row
    |> convert_values()
    |> Enum.zip([
      :date_of_sale,
      :address,
      :county,
      :eircode,
      :price_in_cents,
      :not_full_market_price,
      :vat_exclusive,
      :description_of_property,
      :property_size_description
    ])
    |> Enum.into(%{}, fn {value, key} -> {key, value} end)
    |> Map.update!(:date_of_sale, &parse_date/1)
    |> Map.update!(:price_in_cents, &parse_price/1)
    |> Map.update!(:not_full_market_price, &parse_boolean/1)
    |> Map.update!(:vat_exclusive, &parse_boolean/1)
    |> Map.update!(:description_of_property, &parse_text/1)
    |> Map.update!(:property_size_description, &parse_text/1)
  end

  defp convert_values(row) when is_list(row) do
    row |> Enum.map(fn str -> Mbcs.decode!(str, :cp1252) end)
  end

  defp parse_date(date_str) do
    [day, month, year] =
      date_str |> normalise_text() |> String.split("/") |> Enum.map(&String.to_integer/1)

    Date.new!(year, month, day)
  end

  defp parse_price("€" <> price_str)
       when is_binary(price_str) do
    price_str
    |> normalise_text()
    |> String.replace(",", "")
    |> String.replace(".", "")
    |> String.to_integer()
  end

  def normalise_text(str), do: str |> String.downcase() |> String.trim()

  defp parse_boolean("no"), do: false

  defp parse_boolean("yes"), do: true

  defp parse_boolean(str), do: str |> normalise_text() |> parse_boolean()

  defp parse_text(text_str) do
    text_str
    |> to_string
    |> String.trim()
  end

  defp set_timestamps(sales) do
    sales
    |> Enum.map(fn sale -> Map.put(sale, :inserted_at, DateTime.utc_now()) end)
    |> Enum.map(fn sale -> Map.put(sale, :updated_at, DateTime.utc_now()) end)
  end

  defp update_fetcher_status(str) do
    :ets.insert(@table, {:status, str})
    PubSub.broadcast(PriceRegister.PubSub, @topic, %{status: str})
  end
end
