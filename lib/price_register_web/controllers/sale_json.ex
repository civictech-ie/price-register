defmodule PriceRegisterWeb.SaleJSON do
  alias PriceRegister.Properties.Sale

  @doc """
  Renders a list of sales.
  """
  def index(%{sales: sales, metadata: metadata}) do
    %{data: for(sale <- sales, do: data(sale)), metadata: metadata}
  end

  @doc """
  Renders a single sale.
  """
  def show(%{sale: sale}) do
    %{data: data(sale)}
  end

  defp data(%Sale{} = sale) do
    %{
      id: sale.id,
      date_of_sale: sale.date_of_sale,
      address: sale.address,
      county: sale.county,
      eircode: sale.eircode,
      price_in_cents: sale.price_in_cents,
      not_full_market_price: sale.not_full_market_price,
      vat_exclusive: sale.vat_exclusive,
      description_of_property: sale.description_of_property,
      property_size_description: sale.property_size_description
    }
  end
end
