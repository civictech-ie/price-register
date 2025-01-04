defmodule PprApi.ResidentialSalesTest do
  use PprApi.DataCase
  import PprApi.Fixtures

  alias PprApi.ResidentialSales

  describe "list_residential_sales/0" do
    test "returns all sales ordered by date" do
      sale1 = residential_sale_fixture(%{date_of_sale: ~D[2023-01-01]})
      sale2 = residential_sale_fixture(%{date_of_sale: ~D[2023-01-02]})

      %{entries: sales, metadata: _metadata} = ResidentialSales.list_residential_sales()
      assert [sale2.id, sale1.id] == Enum.map(sales, & &1.id)
    end
  end

  describe "latest_sale_date/0" do
    test "returns the most recent sale date" do
      residential_sale_fixture(%{date_of_sale: ~D[2023-01-01]})
      residential_sale_fixture(%{date_of_sale: ~D[2023-01-02]})

      assert ResidentialSales.latest_sale_date() == ~D[2023-01-02]
    end

    test "returns nil when no sales exist" do
      assert ResidentialSales.latest_sale_date() == nil
    end
  end

  describe "upsert_rows/1" do
    test "successfully inserts new records" do
      rows = [
        %{
          date_of_sale: ~D[2023-01-01],
          address: "78 The Coombe",
          price_in_euros: Decimal.new("100000")
        }
      ]

      count = ResidentialSales.upsert_rows(rows)
      assert count == 1
    end

    test "handles duplicate records" do
      existing = residential_sale_fixture()

      rows = [
        %{
          date_of_sale: existing.date_of_sale,
          address: existing.address,
          price_in_euros: existing.price_in_euros
        },
        %{
          date_of_sale: existing.date_of_sale,
          address: existing.address,
          price_in_euros: existing.price_in_euros
        }
      ]

      count = ResidentialSales.upsert_rows(rows)
      assert count == 1
    end
  end
end
