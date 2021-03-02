defmodule PriceRegister.Seeder do
  alias NimbleCSV.RFC4180, as: CSV
  alias PriceRegister.RegisterParser

  def seed! do
    "./priv/repo/seeds.csv"
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.map(fn [
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
    |> Stream.run()
  end
end
