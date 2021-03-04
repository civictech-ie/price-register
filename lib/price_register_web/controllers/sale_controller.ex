defmodule PriceRegisterWeb.SaleController do
  use PriceRegisterWeb, :controller

  alias PriceRegister.Properties

  def index(conn, _params) do
    request_path = "GET " <> "/api/sales"
    %{entries: sales, metadata: metadata} = Properties.list_sales()
    render(conn, "index.html", sales: sales, metadata: metadata, request_path: request_path)
  end

  def show(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)
    request_path = "GET " <> "/api/sales/#{id}"
    render(conn, "show.html", sale: sale, request_path: request_path)
  end
end
