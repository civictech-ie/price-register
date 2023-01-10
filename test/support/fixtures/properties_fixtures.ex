defmodule PriceRegister.PropertiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PriceRegister.Properties` context.
  """

  @doc """
  Generate a sale.
  """
  def sale_fixture(attrs \\ %{}) do
    {:ok, sale} =
      attrs
      |> Enum.into(%{
        address: "some address",
        county: "some county",
        date_of_sale: ~D[2023-01-07],
        description_of_property: "some description_of_property",
        eircode: "some eircode",
        not_full_market_price: true,
        price_in_cents: 42,
        property_size_description: "some property_size_description",
        vat_exclusive: true
      })
      |> PriceRegister.Properties.create_sale()

    sale
  end
end
