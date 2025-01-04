defmodule PprApi.FingerprintHelper do
  @moduledoc """
  Provides a shared function to compute the fingerprint for a residential sale row.
  """

  @doc """
  Computes the same fingerprint used in ResidentialSale.put_fingerprint/1,
  but for a plain map (row).
  """
  def compute_fingerprint(row) do
    data_string =
      [
        row[:date_of_sale] |> to_string(),
        row[:address],
        row[:county],
        row[:eircode],
        row[:price_in_euros] |> to_string(),
        row[:not_full_market_price] |> to_string(),
        row[:vat_exclusive] |> to_string(),
        row[:description_of_property],
        row[:property_size_description]
      ]
      # replace nil with ""
      |> Enum.map(&(&1 || ""))
      |> Enum.join("|")

    :crypto.hash(:sha256, data_string)
    |> Base.encode16(case: :lower)
  end
end
