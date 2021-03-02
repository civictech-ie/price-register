defmodule PriceRegisterWeb.SaleView do
  use PriceRegisterWeb, :view
  alias PriceRegisterWeb.SaleView
  alias PriceRegisterWeb.MetadataView

  def render("index.json", %{sales: sales, metadata: metadata}) do
    %{
      metadata: render_one(metadata, MetadataView, "metadata.json"),
      sales: render_many(sales, SaleView, "sale.json")
    }
  end

  def render("show.json", %{sale: sale}) do
    render_one(sale, SaleView, "sale.json")
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
