defmodule PriceRegisterWeb.PropertyControllerTest do
  use PriceRegisterWeb.ConnCase

  alias PriceRegister.Properties
  alias PriceRegister.Properties.Property

  @create_attrs %{
    address: "some address",
    county: "some county",
    postal_code: "some postal_code"
  }
  @update_attrs %{
    address: "some updated address",
    county: "some updated county",
    postal_code: "some updated postal_code"
  }
  @invalid_attrs %{address: nil, county: nil, postal_code: nil}

  def fixture(:property) do
    {:ok, property} = Properties.create_property(@create_attrs)
    property
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all properties", %{conn: conn} do
      conn = get(conn, Routes.property_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create property" do
    test "renders property when data is valid", %{conn: conn} do
      conn = post(conn, Routes.property_path(conn, :create), property: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.property_path(conn, :show, id))

      assert %{
               "id" => id,
               "address" => "some address",
               "county" => "some county",
               "postal_code" => "some postal_code"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.property_path(conn, :create), property: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update property" do
    setup [:create_property]

    test "renders property when data is valid", %{conn: conn, property: %Property{id: id} = property} do
      conn = put(conn, Routes.property_path(conn, :update, property), property: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.property_path(conn, :show, id))

      assert %{
               "id" => id,
               "address" => "some updated address",
               "county" => "some updated county",
               "postal_code" => "some updated postal_code"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, property: property} do
      conn = put(conn, Routes.property_path(conn, :update, property), property: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete property" do
    setup [:create_property]

    test "deletes chosen property", %{conn: conn, property: property} do
      conn = delete(conn, Routes.property_path(conn, :delete, property))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.property_path(conn, :show, property))
      end
    end
  end

  defp create_property(_) do
    property = fixture(:property)
    %{property: property}
  end
end
