alias NimbleCSV.RFC4180, as: CSV
alias PriceRegister.RegisterParser

PriceRegister.Repo.delete_all(PriceRegister.Properties.Sale)

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
