defmodule PriceRegisterWeb.SaleController do
  use PriceRegisterWeb, :controller

  alias PriceRegister.Properties

  def index(conn, %{"after" => after_cursor})
      when is_binary(after_cursor) and byte_size(after_cursor) > 0 do
    request_path = "GET " <> "/api/sales?after=" <> after_cursor
    %{entries: sales, metadata: metadata} = Properties.list_sales(after: after_cursor)
    render(conn, "index.html", sales: sales, metadata: metadata, request_path: request_path)
  end

  def index(conn, %{"before" => before_cursor})
      when is_binary(before_cursor) and byte_size(before_cursor) > 0 do
    request_path = "GET " <> "/api/sales?before=" <> before_cursor
    %{entries: sales, metadata: metadata} = Properties.list_sales(before: before_cursor)
    render(conn, "index.html", sales: sales, metadata: metadata, request_path: request_path)
  end

  def index(conn, _params) do
    request_path = "GET " <> "/api/sales"
    %{entries: sales, metadata: metadata} = Properties.list_sales()
    render(conn, "index.html", sales: sales, metadata: metadata, request_path: request_path)
  end

  def show(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)

    metadata = %{
      before: "",
      after: "",
      total_count: 0
    }

    request_path = "GET " <> "/api/sales/" <> id
    render(conn, "show.html", sale: sale, metadata: metadata, request_path: request_path)
  end
end
