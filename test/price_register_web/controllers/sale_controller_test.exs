defmodule PriceRegisterWeb.SaleControllerTest do
  use PriceRegisterWeb.ConnCase

  import PriceRegister.PropertiesFixtures

  alias PriceRegister.Properties.Sale

  @create_attrs %{
    address: "some address",
    county: "some county",
    date_of_sale: ~D[2023-01-07],
    description_of_property: "some description_of_property",
    eircode: "some eircode",
    not_full_market_price: true,
    price_in_cents: 42,
    property_size_description: "some property_size_description",
    vat_exclusive: true
  }
  @update_attrs %{
    address: "some updated address",
    county: "some updated county",
    date_of_sale: ~D[2023-01-08],
    description_of_property: "some updated description_of_property",
    eircode: "some updated eircode",
    not_full_market_price: false,
    price_in_cents: 43,
    property_size_description: "some updated property_size_description",
    vat_exclusive: false
  }
  @invalid_attrs %{address: nil, county: nil, date_of_sale: nil, description_of_property: nil, eircode: nil, not_full_market_price: nil, price_in_cents: nil, property_size_description: nil, vat_exclusive: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all sales", %{conn: conn} do
      conn = get(conn, ~p"/api/sales")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create sale" do
    test "renders sale when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/sales", sale: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/sales/#{id}")

      assert %{
               "id" => ^id,
               "address" => "some address",
               "county" => "some county",
               "date_of_sale" => "2023-01-07",
               "description_of_property" => "some description_of_property",
               "eircode" => "some eircode",
               "not_full_market_price" => true,
               "price_in_cents" => 42,
               "property_size_description" => "some property_size_description",
               "vat_exclusive" => true
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/sales", sale: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update sale" do
    setup [:create_sale]

    test "renders sale when data is valid", %{conn: conn, sale: %Sale{id: id} = sale} do
      conn = put(conn, ~p"/api/sales/#{sale}", sale: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/sales/#{id}")

      assert %{
               "id" => ^id,
               "address" => "some updated address",
               "county" => "some updated county",
               "date_of_sale" => "2023-01-08",
               "description_of_property" => "some updated description_of_property",
               "eircode" => "some updated eircode",
               "not_full_market_price" => false,
               "price_in_cents" => 43,
               "property_size_description" => "some updated property_size_description",
               "vat_exclusive" => false
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, sale: sale} do
      conn = put(conn, ~p"/api/sales/#{sale}", sale: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete sale" do
    setup [:create_sale]

    test "deletes chosen sale", %{conn: conn, sale: sale} do
      conn = delete(conn, ~p"/api/sales/#{sale}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/sales/#{sale}")
      end
    end
  end

  defp create_sale(_) do
    sale = sale_fixture()
    %{sale: sale}
  end
end
