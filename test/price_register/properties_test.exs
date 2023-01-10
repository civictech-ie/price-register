defmodule PriceRegister.PropertiesTest do
  use PriceRegister.DataCase

  alias PriceRegister.Properties

  describe "sales" do
    alias PriceRegister.Properties.Sale

    import PriceRegister.PropertiesFixtures

    @invalid_attrs %{address: nil, county: nil, date_of_sale: nil, description_of_property: nil, eircode: nil, not_full_market_price: nil, price_in_cents: nil, property_size_description: nil, vat_exclusive: nil}

    test "list_sales/0 returns all sales" do
      sale = sale_fixture()
      assert Properties.list_sales() == [sale]
    end

    test "get_sale!/1 returns the sale with given id" do
      sale = sale_fixture()
      assert Properties.get_sale!(sale.id) == sale
    end

    test "create_sale/1 with valid data creates a sale" do
      valid_attrs = %{address: "some address", county: "some county", date_of_sale: ~D[2023-01-07], description_of_property: "some description_of_property", eircode: "some eircode", not_full_market_price: true, price_in_cents: 42, property_size_description: "some property_size_description", vat_exclusive: true}

      assert {:ok, %Sale{} = sale} = Properties.create_sale(valid_attrs)
      assert sale.address == "some address"
      assert sale.county == "some county"
      assert sale.date_of_sale == ~D[2023-01-07]
      assert sale.description_of_property == "some description_of_property"
      assert sale.eircode == "some eircode"
      assert sale.not_full_market_price == true
      assert sale.price_in_cents == 42
      assert sale.property_size_description == "some property_size_description"
      assert sale.vat_exclusive == true
    end

    test "create_sale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Properties.create_sale(@invalid_attrs)
    end

    test "update_sale/2 with valid data updates the sale" do
      sale = sale_fixture()
      update_attrs = %{address: "some updated address", county: "some updated county", date_of_sale: ~D[2023-01-08], description_of_property: "some updated description_of_property", eircode: "some updated eircode", not_full_market_price: false, price_in_cents: 43, property_size_description: "some updated property_size_description", vat_exclusive: false}

      assert {:ok, %Sale{} = sale} = Properties.update_sale(sale, update_attrs)
      assert sale.address == "some updated address"
      assert sale.county == "some updated county"
      assert sale.date_of_sale == ~D[2023-01-08]
      assert sale.description_of_property == "some updated description_of_property"
      assert sale.eircode == "some updated eircode"
      assert sale.not_full_market_price == false
      assert sale.price_in_cents == 43
      assert sale.property_size_description == "some updated property_size_description"
      assert sale.vat_exclusive == false
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
