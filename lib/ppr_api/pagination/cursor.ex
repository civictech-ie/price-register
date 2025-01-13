defmodule PprApi.Pagination.Cursor do
  alias PprApi.ResidentialSales.ResidentialSale

  def encode_cursor(nil, _opts), do: nil

  # "date" sort => "YYYY-MM-DD-<id>"
  def encode_cursor(%ResidentialSale{id: id, date_of_sale: date}, %{"sort" => {"date", _dir}}) do
    # Convert date to ISO8601, then combine with ID
    value_str = Date.to_iso8601(date)
    combined = "#{value_str}|#{id}"
    Base.url_encode64(combined, padding: false)
  end

  # "price" sort => "<price_in_euros>-<id>"
  def encode_cursor(%ResidentialSale{id: id, price_in_euros: price}, %{"sort" => {"price", _dir}}) do
    value_str = to_string(price)
    combined = "#{value_str}|#{id}"
    Base.url_encode64(combined, padding: false)
  end

  def encode_cursor(_entry, _opts), do: nil

  def decode_cursor(nil, _field), do: nil

  def decode_cursor(encoded, "date") do
    with {:ok, decoded} <- Base.url_decode64(encoded, padding: false),
         [val_str, raw_id] <- String.split(decoded, "|", parts: 2),
         {:ok, date} <- Date.from_iso8601(val_str),
         {id, ""} <- Integer.parse(raw_id) do
      {date, id}
    else
      _ -> nil
    end
  end

  def decode_cursor(encoded, "price") do
    with {:ok, decoded} <- Base.url_decode64(encoded, padding: false),
         [val_str, raw_id] <- String.split(decoded, "|", parts: 2),
         {price, ""} <- Integer.parse(val_str),
         {id, ""} <- Integer.parse(raw_id) do
      {price, id}
    else
      _ -> nil
    end
  end

  def decode_cursor(_encoded, _field), do: nil
end
