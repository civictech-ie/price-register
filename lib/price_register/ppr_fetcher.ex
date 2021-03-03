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
    Seeder.seed!()

    # schedule_fetch()
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch, @interval)
  end

  defp fetch_recent_sales() do
    [
      Date.utc_today() |> Date.beginning_of_month(),
      Date.utc_today() |> Date.add(-1 * @window) |> Date.beginning_of_month()
    ]
    |> Enum.uniq()
    |> Enum.each(fn date -> fetch_month(date) end)
  end

  defp fetch_month(%Date{} = date) do
    current_count = Properties.sales_count(Date.beginning_of_month(date), Date.end_of_month(date))

    year_str = date.year |> Integer.to_string()
    month_str = date.month |> Integer.to_string() |> String.pad_leading(2, "0")

    (@base_url <> "PPR-#{year_str}-#{month_str}.csv/$FILE/PPR-#{year_str}-#{month_str}.csv")
    |> HTTPoison.get!()
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
      case index < current_count do
        true ->
          # skip
          IO.puts("#{String.pad_leading(7, Integer.to_string(index))}: -")

        false ->
          # don't skip
          RegisterParser.import_row!(row)
          IO.puts("#{String.pad_leading(7, Integer.to_string(index))}: ·")
      end
    end)
  end
end
