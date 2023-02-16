defmodule PriceRegisterWeb.SaleHTML do
  use PriceRegisterWeb, :html

  alias PriceRegister.Cldr

  embed_templates "sale_html/*"

  def format_currency(nil), do: ""

  def format_currency(price) do
    price
    |> Decimal.new()
    |> Decimal.div(100)
    |> Cldr.Number.to_string!(locale: "en", currency: "EUR")
  end
end
