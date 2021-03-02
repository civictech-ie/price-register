defmodule PriceRegisterWeb.SaleController do
  use PriceRegisterWeb, :controller

  alias PriceRegister.Properties

  action_fallback PriceRegisterWeb.FallbackController

  def index(conn, _params) do
    %{entries: sales, metadata: metadata} = Properties.list_sales()
    render(conn, "index.json", sales: sales, metadata: metadata)
  end

  def show(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)
    render(conn, "show.json", sale: sale)
  end
end
