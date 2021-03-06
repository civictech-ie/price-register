defmodule PriceRegisterWeb.SaleView do
  use PriceRegisterWeb, :view

  alias PriceRegister.Cldr

  def format_date(nil), do: ""

  def format_date(%Date{year: year, month: month, day: day}) do
    [day, month, year]
    |> Enum.map(&Integer.to_string/1)
    |> Enum.map(fn str -> String.pad_leading(str, 2, "0") end)
    |> Enum.join("/")
  end

  def format_number(nil), do: ""

  def format_number(number) do
    number |> Cldr.Number.to_string!(locale: "en")
  end

  def format_currency(nil), do: ""

  def format_currency(price) do
    price
    |> Decimal.new()
    |> Decimal.div(100)
    |> Cldr.Number.to_string!(locale: "en", currency: "EUR")
  end
end
