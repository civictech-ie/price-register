defmodule PriceRegister.SaleFetcher do
  alias NimbleCSV.RFC4180, as: CSV
  alias PriceRegister.RegisterParser
  alias PriceRegister.Seeder
  alias PriceRegister.Properties

  @base_url "https://propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/"

  @first_date ~D[2010-01-01]

  # a bit more eager the more work it has to do
  def fetch! do
    most_recent = most_recent_date()

    fetch_months(
      most_recent,
      (Date.diff(Date.utc_today(), most_recent) / (365 * 2) + 1) |> Kernel.round()
    )
  end

  def fetch_months(start_date, count \\ 1) do
    IO.puts("Fetching months: #{count}")
    # always re-fetch the most recent month
    start_date |> fetch_month()

    # fetch $count months
    0..count
    |> Enum.each(fn i ->
      date = add_n_months(start_date, i)

      # don't fetch future months
      if Date.diff(Date.utc_today(), date) > 0 do
        fetch_month(date)
      end
    end)
  end

  def fetch_month(%Date{} = date) do
    year_str = date.year |> Integer.to_string()
    month_str = date.month |> Integer.to_string() |> String.pad_leading(2, "0")

    IO.puts("Fetching... #{year_str} #{month_str}")

    get_csv_for_month!(month_str, year_str)
    |> CSV.parse_string()
    |> Enum.with_index()
    |> Enum.map(fn {[
                      _date,
                      _address,
                      _postal_code,
                      _county,
                      _price,
                      _not_market,
                      _vat_exclusive,
                      _desc,
                      _size_desc
                    ] = row, index} ->
      RegisterParser.import_row!(index, row)
    end)
  end

  defp get_csv_for_month!(month_str, year_str) do
    IO.puts(
      "Fetching csv: PPR-#{year_str}-#{month_str}.csv/$FILE/PPR-#{year_str}-#{month_str}.csv"
    )

    %{body: body} =
      (@base_url <> "PPR-#{year_str}-#{month_str}.csv/$FILE/PPR-#{year_str}-#{month_str}.csv")
      |> HTTPoison.get!(%{}, hackney: [:insecure])

    body
  end

  defp most_recent_date() do
    case Properties.most_recent_date() do
      %Date{} = date -> date
      _ -> @first_date
    end
  end

  defp add_n_months(date, 0), do: date

  defp add_n_months(date, 1) do
    date |> Date.end_of_month() |> Date.add(1)
  end

  defp add_n_months(date, n) when is_integer(n) do
    add_n_months(add_n_months(date, 1), n - 1)
  end
end
