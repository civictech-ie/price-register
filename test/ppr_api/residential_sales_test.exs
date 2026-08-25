defmodule PprApi.ResidentialSalesTest do
  use PprApi.DataCase
  import PprApi.Fixtures

  alias PprApi.ResidentialSales
  alias PprApi.ResidentialSales.ResidentialSale

  describe "list_residential_sales/0" do
    test "returns all sales ordered by date" do
      sale1 = residential_sale_fixture(%{date_of_sale: ~D[2023-01-01]})
      sale2 = residential_sale_fixture(%{date_of_sale: ~D[2023-01-02]})

      %{entries: sales, metadata: _metadata} =
        ResidentialSales.list_residential_sales(%{
          "sort" => "date-desc",
          "before" => nil,
          "after" => nil,
          "limit" => 2
        })

      assert [sale2.id, sale1.id] == Enum.map(sales, & &1.id)
    end
  end

  defp list(opts) do
    ResidentialSales.list_residential_sales(Map.merge(%{"after" => nil, "before" => nil}, opts))
  end

  defp ids(%{entries: entries}), do: Enum.map(entries, & &1.id)

  defp insert_dated_sales(dates) do
    for {date, index} <- Enum.with_index(dates) do
      residential_sale_fixture(%{date_of_sale: date, address: "#{index} Date St"})
    end
  end

  defp insert_priced_sales(prices) do
    for {price, index} <- Enum.with_index(prices) do
      residential_sale_fixture(%{
        price_in_euros: Decimal.new(price),
        address: "#{index} Price St"
      })
    end
  end

  describe "list_residential_sales/1 pagination" do
    test "paginates forwards and backwards by date desc" do
      [d1, d2, d3, d4, d5] =
        insert_dated_sales([
          ~D[2023-01-01],
          ~D[2023-01-02],
          ~D[2023-01-03],
          ~D[2023-01-04],
          ~D[2023-01-05]
        ])

      page1 = list(%{"sort" => "date-desc", "limit" => 2})
      assert ids(page1) == [d5.id, d4.id]
      assert page1.metadata.before_cursor == nil
      assert page1.metadata.after_cursor != nil
      assert page1.metadata.sort == "date-desc"
      assert page1.metadata.limit == 2

      page2 = list(%{"sort" => "date-desc", "limit" => 2, "after" => page1.metadata.after_cursor})
      assert ids(page2) == [d3.id, d2.id]
      assert page2.metadata.before_cursor != nil
      assert page2.metadata.after_cursor != nil

      page3 = list(%{"sort" => "date-desc", "limit" => 2, "after" => page2.metadata.after_cursor})
      assert ids(page3) == [d1.id]
      assert page3.metadata.after_cursor == nil
      assert page3.metadata.before_cursor != nil

      back_to_page2 =
        list(%{"sort" => "date-desc", "limit" => 2, "before" => page3.metadata.before_cursor})

      assert ids(back_to_page2) == [d3.id, d2.id]

      back_to_page1 =
        list(%{"sort" => "date-desc", "limit" => 2, "before" => page2.metadata.before_cursor})

      assert ids(back_to_page1) == [d5.id, d4.id]
      assert back_to_page1.metadata.before_cursor == nil
    end

    test "paginates forwards and backwards by date asc" do
      [d1, d2, d3] = insert_dated_sales([~D[2023-01-01], ~D[2023-01-02], ~D[2023-01-03]])

      page1 = list(%{"sort" => "date-asc", "limit" => 2})
      assert ids(page1) == [d1.id, d2.id]
      assert page1.metadata.before_cursor == nil

      page2 = list(%{"sort" => "date-asc", "limit" => 2, "after" => page1.metadata.after_cursor})
      assert ids(page2) == [d3.id]
      assert page2.metadata.after_cursor == nil

      back = list(%{"sort" => "date-asc", "limit" => 2, "before" => page2.metadata.before_cursor})
      assert ids(back) == [d1.id, d2.id]
    end

    test "paginates forwards and backwards by price desc" do
      [p100, p200, p300] = insert_priced_sales(["100000", "200000", "300000"])

      page1 = list(%{"sort" => "price-desc", "limit" => 2})
      assert ids(page1) == [p300.id, p200.id]
      assert page1.metadata.sort == "price-desc"

      page2 =
        list(%{"sort" => "price-desc", "limit" => 2, "after" => page1.metadata.after_cursor})

      assert ids(page2) == [p100.id]
      assert page2.metadata.after_cursor == nil

      back =
        list(%{"sort" => "price-desc", "limit" => 2, "before" => page2.metadata.before_cursor})

      assert ids(back) == [p300.id, p200.id]
    end

    test "paginates forwards and backwards by price asc" do
      [p100, p200, p300] = insert_priced_sales(["100000", "200000", "300000"])

      page1 = list(%{"sort" => "price-asc", "limit" => 2})
      assert ids(page1) == [p100.id, p200.id]

      page2 = list(%{"sort" => "price-asc", "limit" => 2, "after" => page1.metadata.after_cursor})
      assert ids(page2) == [p300.id]
      assert page2.metadata.after_cursor == nil

      back =
        list(%{"sort" => "price-asc", "limit" => 2, "before" => page2.metadata.before_cursor})

      assert ids(back) == [p100.id, p200.id]
    end

    test "breaks ties on the sort value by id without skipping rows" do
      sales = insert_dated_sales(List.duplicate(~D[2023-05-05], 4))
      sorted_ids = sales |> Enum.map(& &1.id) |> Enum.sort()

      asc_page1 = list(%{"sort" => "date-asc", "limit" => 2})

      asc_page2 =
        list(%{"sort" => "date-asc", "limit" => 2, "after" => asc_page1.metadata.after_cursor})

      assert ids(asc_page1) ++ ids(asc_page2) == sorted_ids
      assert asc_page2.metadata.after_cursor == nil

      desc_page1 = list(%{"sort" => "date-desc", "limit" => 2})

      desc_page2 =
        list(%{"sort" => "date-desc", "limit" => 2, "after" => desc_page1.metadata.after_cursor})

      assert ids(desc_page1) ++ ids(desc_page2) == Enum.reverse(sorted_ids)
    end

    test "accepts an already-parsed sort tuple without falling back to the default" do
      [p100, p200, p300] = insert_priced_sales(["100000", "200000", "300000"])

      result = list(%{"sort" => {"price", "asc"}, "limit" => 10})

      assert ids(result) == [p100.id, p200.id, p300.id]
      assert result.metadata.sort == "price-asc"
    end

    test "honours before even when after is present with a nil value" do
      [_d1, d2, d3, d4, d5] =
        insert_dated_sales([
          ~D[2023-01-01],
          ~D[2023-01-02],
          ~D[2023-01-03],
          ~D[2023-01-04],
          ~D[2023-01-05]
        ])

      page1 = list(%{"sort" => "date-desc", "limit" => 2})
      page2 = list(%{"sort" => "date-desc", "limit" => 2, "after" => page1.metadata.after_cursor})
      assert ids(page2) == [d3.id, d2.id]

      back =
        ResidentialSales.list_residential_sales(%{
          "sort" => "date-desc",
          "limit" => 2,
          "after" => nil,
          "before" => page2.metadata.before_cursor
        })

      assert ids(back) == [d5.id, d4.id]
    end

    test "after wins when both after and before cursors are given" do
      insert_dated_sales([~D[2023-01-01], ~D[2023-01-02], ~D[2023-01-03], ~D[2023-01-04]])

      page1 = list(%{"sort" => "date-desc", "limit" => 2})
      page2 = list(%{"sort" => "date-desc", "limit" => 2, "after" => page1.metadata.after_cursor})

      conflicting =
        ResidentialSales.list_residential_sales(%{
          "sort" => "date-desc",
          "limit" => 2,
          "after" => page1.metadata.after_cursor,
          "before" => page2.metadata.before_cursor
        })

      assert ids(conflicting) == ids(page2)
    end

    test "invalid cursors fall back to the first page in sort order" do
      [d1, d2, d3] = insert_dated_sales([~D[2023-01-01], ~D[2023-01-02], ~D[2023-01-03]])

      for invalid_opts <- [
            %{"after" => "not!!a!!cursor"},
            %{"before" => "not!!a!!cursor"},
            %{"before" => Base.url_encode64("garbage|nope", padding: false)}
          ] do
        result = list(Map.merge(%{"sort" => "date-desc", "limit" => 3}, invalid_opts))

        assert ids(result) == [d3.id, d2.id, d1.id]
        assert result.metadata.before_cursor == nil
      end
    end

    test "a price cursor is not decoded as a date cursor" do
      [p100, p200, p300] = insert_priced_sales(["100000", "200000", "300000"])

      page1 = list(%{"sort" => "price-asc", "limit" => 2})

      result = list(%{"sort" => "date-asc", "limit" => 3, "after" => page1.metadata.after_cursor})

      assert Enum.sort(ids(result)) == Enum.sort([p100.id, p200.id, p300.id])
    end

    test "limit of zero returns no entries and no cursors" do
      insert_dated_sales([~D[2023-01-01], ~D[2023-01-02]])

      result = list(%{"sort" => "date-desc", "limit" => 0})

      assert result.entries == []
      assert result.metadata.limit == 0
      assert result.metadata.after_cursor == nil
      assert result.metadata.before_cursor == nil

      negative = list(%{"sort" => "date-desc", "limit" => -5})
      assert negative.entries == []
    end

    test "applies the current-snapshot constraint to pages and peeks alike" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      stale = residential_sale_fixture(%{date_of_sale: ~D[2023-01-01], address: "Stale House"})
      [fresh1, fresh2] = insert_dated_sales([~D[2023-01-02], ~D[2023-01-03]])

      fetch_fixture(%{
        status: "success",
        starts_on: ~D[2010-01-01],
        started_at: now,
        finished_at: now,
        total_rows: 2
      })

      from(s in ResidentialSale, where: s.id == ^stale.id)
      |> Repo.update_all(set: [updated_at: DateTime.add(now, -3600, :second)])

      result = list(%{"sort" => "date-desc", "limit" => 2})

      assert ids(result) == [fresh2.id, fresh1.id]
      # the stale row must not show up as a phantom next page via the peek query
      assert result.metadata.after_cursor == nil
      assert result.metadata.total_rows == 2
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
          county: "Dublin",
          price_in_euros: Decimal.new("100000"),
          not_full_market_price: false,
          vat_exclusive: false
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
          county: existing.county,
          price_in_euros: existing.price_in_euros,
          not_full_market_price: existing.not_full_market_price,
          vat_exclusive: existing.vat_exclusive
        },
        %{
          date_of_sale: existing.date_of_sale,
          address: existing.address,
          county: existing.county,
          price_in_euros: existing.price_in_euros,
          not_full_market_price: existing.not_full_market_price,
          vat_exclusive: existing.vat_exclusive
        }
      ]

      count = ResidentialSales.upsert_rows(rows)
      assert count == 1
    end
  end
end
