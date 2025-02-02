defmodule PprApiWeb.API.ResidentialSaleJSON do
  alias PprApi.ResidentialSales.ResidentialSale

  @doc """
  Renders a list of residential_sales.
  """
  def index(%{entries: residential_sales, metadata: metadata}) do
    %{
      data: for(residential_sale <- residential_sales, do: data(residential_sale)),
      metadata: metadata
    }
  end

  def show(%{entry: residential_sale}) do
    %{
      data: data(residential_sale)
    }
  end

  def data(%ResidentialSale{} = residential_sale) do
    %{
      date_of_sale: residential_sale.date_of_sale,
      address: residential_sale.address,
      county: residential_sale.county,
      eircode: residential_sale.eircode,
      price_in_euros: residential_sale.price_in_euros |> Decimal.to_string(),
      not_full_market_price: residential_sale.not_full_market_price,
      vat_exclusive: residential_sale.vat_exclusive,
      description_of_property: residential_sale.description_of_property,
      property_size_description: residential_sale.property_size_description
    }
  end
end
