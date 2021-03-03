alias PriceRegister.Properties

defmodule PriceRegister.RegisterParser do
  # dangerous: no duplicate protection at this level
  def import_row!(
        [
          _date,
          _address,
          _postal_code,
          _county,
          _price,
          _not_market,
          _vat_exclusive,
          _desc,
          _size_desc
        ] = row
      ) do
    {:ok, _sale} = row |> convert_values |> parse_sale |> Properties.insert_sale()
  end

  defp convert_values(row) when is_list(row) do
    row |> Enum.map(fn str -> Mbcs.decode!(str, :cp1252) end)
  end

  defp parse_sale([
         date_str,
         address_str,
         postal_code_str,
         county_str,
         price_str,
         not_market_str,
         vat_exclusive_str,
         desc_str,
         size_desc_str
       ]) do
    %{
      date: date_str |> parse_date,
      price: price_str |> parse_price,
      full_market: !(not_market_str |> normalise_text |> parse_boolean),
      vat_inclusive: !(vat_exclusive_str |> normalise_text |> parse_boolean),
      description: desc_str |> parse_text,
      size_description: size_desc_str |> parse_text,
      address: address_str |> parse_text,
      postal_code: postal_code_str |> parse_text,
      county: county_str |> parse_text
    }
  end

  defp parse_date(date_str) do
    [day, month, year] = date_str |> String.split("/") |> Enum.map(&String.to_integer/1)
    Date.new!(year, month, day)
  end

  defp parse_price("€" <> price_str)
       when is_binary(price_str) do
    price_str
    |> String.replace(",", "")
    |> String.replace(".", "")
    |> String.to_integer()
  end

  def normalise_text(str), do: str |> String.downcase() |> String.trim()

  defp parse_boolean("no"), do: false

  defp parse_boolean("yes"), do: true

  defp parse_text(text_str) do
    text_str
    |> to_string
    |> String.trim()
  end
end
