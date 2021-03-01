defmodule PriceRegisterWeb.SaleView do
  use PriceRegisterWeb, :view
  alias PriceRegisterWeb.SaleView

  def render("index.json", %{sales: sales}) do
    %{data: render_many(sales, SaleView, "sale.json")}
  end

  def render("show.json", %{sale: sale}) do
    %{data: render_one(sale, SaleView, "sale.json")}
  end

  def render("sale.json", %{sale: sale}) do
    %{
      id: sale.id,
      date: sale.date,
      price: sale.price,
      address: sale.address,
      postal_code: sale.postal_code,
      county: sale.county,
      full_market: sale.full_market,
      vat_inclusive: sale.vat_inclusive,
      description: sale.description,
      size_description: sale.size_description
    }
  end
end
