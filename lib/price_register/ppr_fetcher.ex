defmodule PriceRegister.PPRFetcher do
  use GenServer

  alias NimbleCSV.RFC4180, as: CSV
  alias PriceRegister.RegisterParser
  alias PriceRegister.Seeder
  alias PriceRegister.Properties

  @interval 60_000
  # how many days back should we hunt for unimported rows?
  @window 21

  @base_url "https://propertypriceregister.ie/website/npsra/ppr/npsra-ppr.nsf/Downloads/"

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(state) do
    seed_database()
    {:ok, state}
  end

  def handle_info(:fetch, _state) do
    fetch_recent_sales()

    schedule_fetch()

    {:noreply, []}
  end

  defp seed_database() do
    case Properties.sales_count() do
      0 -> Seeder.seed!()
      _ -> nil
    end

    schedule_fetch()
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch, @interval)
  end

  defp fetch_recent_sales() do
    [
      Date.utc_today(),
      Date.utc_today() |> Date.add(-1 * @window)
    ]
    |> Enum.map(fn date ->
      year = date.year |> Integer.to_string()
      month = date.month |> Integer.to_string() |> String.pad_leading(2, "0")
      {year, month}
    end)
    |> Enum.uniq()
    |> Enum.each(fn {year, month} ->
      fetch_month(year, month)
    end)
  end

  defp fetch_month(year, month) when is_binary(year) and is_binary(month) do
    (@base_url <> "PPR-#{year}-#{month}.csv/$FILE/PPR-#{year}-#{month}.csv")
    |> HTTPoison.get!()
    |> CSV.parse_string()
    |> Enum.map(fn [
                     _date,
                     _address,
                     _postal_code,
                     _county,
                     _price,
                     _not_market,
                     _vat_exclusive,
                     _desc,
                     _size_desc
                   ] = row ->
      RegisterParser.import_row!(row)
    end)
  end
end
