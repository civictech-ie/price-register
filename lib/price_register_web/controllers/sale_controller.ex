defmodule PriceRegisterWeb.SaleController do
  use PriceRegisterWeb, :controller

  alias PriceRegister.Properties

  action_fallback PriceRegisterWeb.FallbackController

  def index(conn, %{"after" => after_cursor}) do
    %{entries: sales, metadata: metadata} = Properties.list_sales(after: after_cursor)
    render(conn, :index, sales: sales, metadata: metadata)
  end

  def index(conn, %{"before" => before_cursor}) do
    %{entries: sales, metadata: metadata} = Properties.list_sales(before: before_cursor)
    render(conn, :index, sales: sales, metadata: metadata)
  end

  def index(conn, _params) do
    %{entries: sales, metadata: metadata} = Properties.list_sales()
    render(conn, :index, sales: sales, metadata: metadata)
  end

  def show(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)
    render(conn, :show, sale: sale)
  end
end
