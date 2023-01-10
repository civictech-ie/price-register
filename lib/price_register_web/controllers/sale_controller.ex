defmodule PriceRegisterWeb.SaleController do
  use PriceRegisterWeb, :controller

  alias PriceRegister.Properties

  action_fallback PriceRegisterWeb.FallbackController

  def index(conn, _params) do
    sales = Properties.list_sales()
    render(conn, :index, sales: sales)
  end

  def show(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)
    render(conn, :show, sale: sale)
  end
end
