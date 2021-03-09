defmodule PriceRegister.PropertiesTest do
  use PriceRegister.DataCase

  alias PriceRegister.Properties
  alias PriceRegister.Properties.Sale

  describe "sales" do
    @valid_attrs %{
      date: ~D[2010-04-17],
      description: "Second-Hand Dwelling house /Apartment",
      full_market: true,
      price: 360_000_00,
      size_description: "Greater than or equal to 38 sq metres and less than 125 sq metres",
      vat_inclusive: true,
      address: "25 Markievicz Heights, Sligo",
      county: "Sligo"
    }

    @invalid_attrs %{
      date: nil,
      description: "Second-Hand Dwelling house /Apartment",
      full_market: true,
      price: 360_000_00,
      size_description: "Greater than or equal to 38 sq metres and less than 125 sq metres",
      vat_inclusive: true,
      address: "25 Markievicz Heights, Sligo",
      county: "Sligo"
    }

    def sale_fixture(attrs \\ %{}) do
      {:ok, sale} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Properties.insert_sale(Properties.sales_count())

      sale
    end

    test "list_sales/0 returns all sales" do
      sale = sale_fixture()
      %{entries: sales, metadata: _metadata} = Properties.list_sales()
      assert sales = [sale]
    end

    test "sales_count/0 returns sales count" do
      sale = sale_fixture()
      assert Properties.sales_count() == 1
    end

    test "get_sale!/1 returns the sale with given id" do
      sale = sale_fixture()
      assert Properties.get_sale!(sale.id) == sale
    end

    test "create_sale/1 with valid data creates a sale" do
      assert {:ok, %Sale{} = sale} =
               Properties.insert_sale(@valid_attrs, Properties.sales_count())

      assert sale.date == ~D[2010-04-17]
    end

    test "create_sale/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Properties.insert_sale(@invalid_attrs, Properties.sales_count())
    end
  end
end
