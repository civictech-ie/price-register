defmodule PprApi.Pagination.Cursor do
  @moduledoc """
  Handles cursor encoding and decoding for pagination in residential sales queries.
  """

  alias PprApi.ResidentialSales.ResidentialSale

  # Imports Base module for encoding and decoding functions
  import Base, only: [encode64: 1, decode64: 1]

  @doc """
  Encodes a cursor value consisting of the primary sort field and the ID.
  Uses the primary sort field's value and ID to create a string, then encodes it.
  """
  def encode_cursor(%ResidentialSale{} = sale, sort_field) do
    value =
      case sort_field do
        "date" -> sale.date_of_sale |> Date.to_iso8601()
        "price" -> sale.price_in_euros |> Decimal.to_string()
        _ -> raise ArgumentError, "Unsupported sort field for cursor encoding"
      end

    [value, Integer.to_string(sale.id)]
    |> Enum.join("||")
    |> encode64()
  end

  @doc """
  Decodes a cursor string back into a map with appropriate fields based on the sort field.
  """
  def decode_cursor(cursor, sort_field) when is_binary(cursor) do
    with {:ok, decoded} <- decode64(cursor),
         parts = String.split(decoded, "||"),
         parsed <- parse_cursor_parts(parts, sort_field) do
      {:ok, parsed}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def decode_cursor(_, _), do: nil

  defp parse_cursor_parts([value, id], "date") do
    {Date.from_iso8601!(value), String.to_integer(id)}
  end

  defp parse_cursor_parts([value, id], "price") do
    {Decimal.new(value), String.to_integer(id)}
  end
end
