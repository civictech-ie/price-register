alias PriceRegister.Properties

defmodule PriceRegister.RegisterParser do
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
    {:ok, property} =
      row
      |> convert_values
      |> parse_property
      |> Properties.upsert_property()

    IO.inspect(property)

    {:ok, _sale} = row |> convert_values |> parse_sale(property) |> Properties.upsert_sale()
  end

  defp convert_values(row) when is_list(row) do
    row |> Enum.map(fn str -> :iconv.convert("cp1252", "utf-8", str) end)
  end

  defp parse_property([
         _date,
         address,
         postal_code,
         county,
         _price,
         _not_market,
         _vat_exclusive,
         _desc,
         _size_desc
       ]) do
    %{
      address: address |> parse_text,
      postal_code: postal_code |> parse_text,
      county: county |> parse_text
    }
  end

  defp parse_sale(
         [
           date_str,
           _address,
           _postal_code,
           _county,
           price_str,
           not_market_str,
           vat_exclusive_str,
           desc_str,
           size_desc_str
         ],
         property
       ) do
    %{
      date: date_str |> parse_date,
      price: price_str |> parse_price,
      market_price: !(not_market_str |> normalise_text |> parse_boolean),
      vat_inclusive: !(vat_exclusive_str |> normalise_text |> parse_boolean),
      description: desc_str |> parse_text,
      size_description: size_desc_str |> parse_text,
      property_id: property.id
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
