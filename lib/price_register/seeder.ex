defmodule PriceRegister.Seeder do
  alias NimbleCSV.RFC4180, as: CSV
  alias PriceRegister.RegisterParser
  alias PriceRegister.Properties

  # hardcoded from seeds.csv file
  @rows 462_185
  @first_date ~D[2010-01-01]
  @last_date ~D[2021-02-19]

  def seed! do
    current_count = Properties.sales_count(@first_date, @last_date)

    "./priv/repo/seeds.csv"
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.with_index()
    |> Stream.map(fn {[
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
          IO.puts("#{String.pad_leading(Integer.to_string(index), 7, "0")}: -")

        false ->
          # don't skip
          RegisterParser.import_row!(row)
          IO.puts("#{String.pad_leading(Integer.to_string(index), 7, "0")}: ·")
      end
    end)
    |> Stream.run()
  end
end
