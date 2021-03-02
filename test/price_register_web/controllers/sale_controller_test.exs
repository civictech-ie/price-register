defmodule PriceRegisterWeb.SaleControllerTest do
  use PriceRegisterWeb.ConnCase

  alias PriceRegister.Properties

  @create_attrs %{
    date: ~D[2010-04-17],
    description: "Second-Hand Dwelling house /Apartment",
    full_market: true,
    price: 360_000_00,
    size_description: "Greater than or equal to 38 sq metres and less than 125 sq metres",
    vat_inclusive: true,
    address: "25 Markievicz Heights, Sligo",
    county: "Sligo"
  }

  def fixture(:sale) do
    {:ok, sale} = Properties.upsert_sale(@create_attrs)
    sale
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all sales", %{conn: conn} do
      conn = get(conn, Routes.sale_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "show sale" do
    setup [:create_sale]

    test "renders sale when data is valid", %{conn: conn, sale: sale} do
      conn = get(conn, Routes.sale_path(conn, :show, sale.id))

      assert %{
               "date" => "2010-04-17",
               "address" => "25 Markievicz Heights, Sligo",
               "county" => "Sligo",
               "description" => "Second-Hand Dwelling house /Apartment",
               "full_market" => true,
               "price" => 360_000_00,
               "size_description" =>
                 "Greater than or equal to 38 sq metres and less than 125 sq metres",
               "vat_inclusive" => true
             } = json_response(conn, 200)["data"]
    end
  end

  defp create_sale(_) do
    sale = fixture(:sale)
    %{sale: sale}
  end
end
