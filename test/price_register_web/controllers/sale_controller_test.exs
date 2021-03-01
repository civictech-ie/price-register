defmodule PriceRegisterWeb.SaleControllerTest do
  use PriceRegisterWeb.ConnCase

  alias PriceRegister.Properties
  alias PriceRegister.Properties.Sale

  @create_attrs %{
    date: ~D[2010-04-17],
    description: "some description",
    market_price: true,
    price: 42,
    size_description: "some size_description",
    vat_inclusive: true
  }
  @update_attrs %{
    date: ~D[2011-05-18],
    description: "some updated description",
    market_price: false,
    price: 43,
    size_description: "some updated size_description",
    vat_inclusive: false
  }
  @invalid_attrs %{date: nil, description: nil, market_price: nil, price: nil, size_description: nil, vat_inclusive: nil}

  def fixture(:sale) do
    {:ok, sale} = Properties.create_sale(@create_attrs)
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

  describe "create sale" do
    test "renders sale when data is valid", %{conn: conn} do
      conn = post(conn, Routes.sale_path(conn, :create), sale: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.sale_path(conn, :show, id))

      assert %{
               "id" => id,
               "date" => "2010-04-17",
               "description" => "some description",
               "market_price" => true,
               "price" => 42,
               "size_description" => "some size_description",
               "vat_inclusive" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.sale_path(conn, :create), sale: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update sale" do
    setup [:create_sale]

    test "renders sale when data is valid", %{conn: conn, sale: %Sale{id: id} = sale} do
      conn = put(conn, Routes.sale_path(conn, :update, sale), sale: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.sale_path(conn, :show, id))

      assert %{
               "id" => id,
               "date" => "2011-05-18",
               "description" => "some updated description",
               "market_price" => false,
               "price" => 43,
               "size_description" => "some updated size_description",
               "vat_inclusive" => false
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, sale: sale} do
      conn = put(conn, Routes.sale_path(conn, :update, sale), sale: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete sale" do
    setup [:create_sale]

    test "deletes chosen sale", %{conn: conn, sale: sale} do
      conn = delete(conn, Routes.sale_path(conn, :delete, sale))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.sale_path(conn, :show, sale))
      end
    end
  end

  defp create_sale(_) do
    sale = fixture(:sale)
    %{sale: sale}
  end
end
