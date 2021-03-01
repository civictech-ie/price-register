defmodule PriceRegister.PropertiesTest do
  use PriceRegister.DataCase

  alias PriceRegister.Properties

  describe "properties" do
    alias PriceRegister.Properties.Property

    @valid_attrs %{address: "some address", county: "some county", postal_code: "some postal_code"}
    @update_attrs %{address: "some updated address", county: "some updated county", postal_code: "some updated postal_code"}
    @invalid_attrs %{address: nil, county: nil, postal_code: nil}

    def property_fixture(attrs \\ %{}) do
      {:ok, property} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Properties.create_property()

      property
    end

    test "list_properties/0 returns all properties" do
      property = property_fixture()
      assert Properties.list_properties() == [property]
    end

    test "get_property!/1 returns the property with given id" do
      property = property_fixture()
      assert Properties.get_property!(property.id) == property
    end

    test "create_property/1 with valid data creates a property" do
      assert {:ok, %Property{} = property} = Properties.create_property(@valid_attrs)
      assert property.address == "some address"
      assert property.county == "some county"
      assert property.postal_code == "some postal_code"
    end

    test "create_property/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Properties.create_property(@invalid_attrs)
    end

    test "update_property/2 with valid data updates the property" do
      property = property_fixture()
      assert {:ok, %Property{} = property} = Properties.update_property(property, @update_attrs)
      assert property.address == "some updated address"
      assert property.county == "some updated county"
      assert property.postal_code == "some updated postal_code"
    end

    test "update_property/2 with invalid data returns error changeset" do
      property = property_fixture()
      assert {:error, %Ecto.Changeset{}} = Properties.update_property(property, @invalid_attrs)
      assert property == Properties.get_property!(property.id)
    end

    test "delete_property/1 deletes the property" do
      property = property_fixture()
      assert {:ok, %Property{}} = Properties.delete_property(property)
      assert_raise Ecto.NoResultsError, fn -> Properties.get_property!(property.id) end
    end

    test "change_property/1 returns a property changeset" do
      property = property_fixture()
      assert %Ecto.Changeset{} = Properties.change_property(property)
    end
  end

  describe "sales" do
    alias PriceRegister.Properties.Sale

    @valid_attrs %{date: ~D[2010-04-17], description: "some description", market_price: true, price: 42, size_description: "some size_description", vat_inclusive: true}
    @update_attrs %{date: ~D[2011-05-18], description: "some updated description", market_price: false, price: 43, size_description: "some updated size_description", vat_inclusive: false}
    @invalid_attrs %{date: nil, description: nil, market_price: nil, price: nil, size_description: nil, vat_inclusive: nil}

    def sale_fixture(attrs \\ %{}) do
      {:ok, sale} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Properties.create_sale()

      sale
    end

    test "list_sales/0 returns all sales" do
      sale = sale_fixture()
      assert Properties.list_sales() == [sale]
    end

    test "get_sale!/1 returns the sale with given id" do
      sale = sale_fixture()
      assert Properties.get_sale!(sale.id) == sale
    end

    test "create_sale/1 with valid data creates a sale" do
      assert {:ok, %Sale{} = sale} = Properties.create_sale(@valid_attrs)
      assert sale.date == ~D[2010-04-17]
      assert sale.description == "some description"
      assert sale.market_price == true
      assert sale.price == 42
      assert sale.size_description == "some size_description"
      assert sale.vat_inclusive == true
    end

    test "create_sale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Properties.create_sale(@invalid_attrs)
    end

    test "update_sale/2 with valid data updates the sale" do
      sale = sale_fixture()
      assert {:ok, %Sale{} = sale} = Properties.update_sale(sale, @update_attrs)
      assert sale.date == ~D[2011-05-18]
      assert sale.description == "some updated description"
      assert sale.market_price == false
      assert sale.price == 43
      assert sale.size_description == "some updated size_description"
      assert sale.vat_inclusive == false
    end

    test "update_sale/2 with invalid data returns error changeset" do
      sale = sale_fixture()
      assert {:error, %Ecto.Changeset{}} = Properties.update_sale(sale, @invalid_attrs)
      assert sale == Properties.get_sale!(sale.id)
    end

    test "delete_sale/1 deletes the sale" do
      sale = sale_fixture()
      assert {:ok, %Sale{}} = Properties.delete_sale(sale)
      assert_raise Ecto.NoResultsError, fn -> Properties.get_sale!(sale.id) end
    end

    test "change_sale/1 returns a sale changeset" do
      sale = sale_fixture()
      assert %Ecto.Changeset{} = Properties.change_sale(sale)
    end
  end
end
