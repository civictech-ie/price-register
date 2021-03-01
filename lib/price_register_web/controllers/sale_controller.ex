defmodule PriceRegisterWeb.SaleController do
  use PriceRegisterWeb, :controller

  alias PriceRegister.Properties
  alias PriceRegister.Properties.Sale

  action_fallback PriceRegisterWeb.FallbackController

  def index(conn, _params) do
    sales = Properties.list_sales()
    render(conn, "index.json", sales: sales)
  end

  def create(conn, %{"sale" => sale_params}) do
    with {:ok, %Sale{} = sale} <- Properties.create_sale(sale_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.sale_path(conn, :show, sale))
      |> render("show.json", sale: sale)
    end
  end

  def show(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)
    render(conn, "show.json", sale: sale)
  end

  def update(conn, %{"id" => id, "sale" => sale_params}) do
    sale = Properties.get_sale!(id)

    with {:ok, %Sale{} = sale} <- Properties.update_sale(sale, sale_params) do
      render(conn, "show.json", sale: sale)
    end
  end

  def delete(conn, %{"id" => id}) do
    sale = Properties.get_sale!(id)

    with {:ok, %Sale{}} <- Properties.delete_sale(sale) do
      send_resp(conn, :no_content, "")
    end
  end
end
