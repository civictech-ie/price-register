defmodule PprApiWeb.API.ResidentialSaleControllerTest do
  use PprApiWeb.ConnCase
  import PprApi.Fixtures

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp insert_priced_sales(prices) do
    for {price, index} <- Enum.with_index(prices) do
      residential_sale_fixture(%{
        price_in_euros: Decimal.new(price),
        address: "#{index} Price St"
      })
    end
  end

  describe "index" do
    test "returns the first page sorted by date desc by default", %{conn: conn} do
      residential_sale_fixture(%{date_of_sale: ~D[2023-01-01], address: "1 Old St"})
      residential_sale_fixture(%{date_of_sale: ~D[2023-01-02], address: "2 New St"})

      conn = get(conn, ~p"/api/v1/residential/sales")
      %{"data" => data, "metadata" => metadata} = json_response(conn, 200)

      assert Enum.map(data, & &1["date_of_sale"]) == ["2023-01-02", "2023-01-01"]
      assert metadata["sort"] == "date-desc"
      assert metadata["before_cursor"] == nil
      assert metadata["after_cursor"] == nil
    end

    test "sorts by price when requested", %{conn: conn} do
      insert_priced_sales(["300000", "100000", "200000"])

      conn = get(conn, ~p"/api/v1/residential/sales", sort: "price-asc")
      %{"data" => data, "metadata" => metadata} = json_response(conn, 200)

      assert Enum.map(data, & &1["price_in_euros"]) == ["100000", "200000", "300000"]
      assert metadata["sort"] == "price-asc"
    end

    test "paginates forwards with after and back with before", %{conn: conn} do
      insert_priced_sales(["100000", "200000", "300000"])

      page1_conn = get(conn, ~p"/api/v1/residential/sales", sort: "price-asc", limit: "2")
      %{"data" => page1, "metadata" => page1_meta} = json_response(page1_conn, 200)
      assert Enum.map(page1, & &1["price_in_euros"]) == ["100000", "200000"]

      page2_conn =
        get(conn, ~p"/api/v1/residential/sales",
          sort: "price-asc",
          limit: "2",
          after: page1_meta["after_cursor"]
        )

      %{"data" => page2, "metadata" => page2_meta} = json_response(page2_conn, 200)
      assert Enum.map(page2, & &1["price_in_euros"]) == ["300000"]
      assert page2_meta["after_cursor"] == nil

      back_conn =
        get(conn, ~p"/api/v1/residential/sales",
          sort: "price-asc",
          limit: "2",
          before: page2_meta["before_cursor"]
        )

      %{"data" => back, "metadata" => back_meta} = json_response(back_conn, 200)
      assert Enum.map(back, & &1["price_in_euros"]) == ["100000", "200000"]
      assert back_meta["before_cursor"] == nil
    end

    test "an invalid cursor falls back to the first page", %{conn: conn} do
      insert_priced_sales(["100000", "200000"])

      conn = get(conn, ~p"/api/v1/residential/sales", sort: "price-asc", after: "not-a-cursor")
      %{"data" => data} = json_response(conn, 200)

      assert Enum.map(data, & &1["price_in_euros"]) == ["100000", "200000"]
    end

    test "returns 400 for an invalid sort", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/residential/sales", sort: "chickens-desc")
      assert json_response(conn, 400)
    end

    test "sets a public cache-control header on success", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/residential/sales")

      assert json_response(conn, 200)
      assert get_resp_header(conn, "cache-control") == ["public, max-age=60"]
    end

    test "does not set the public cache-control header on errors", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/residential/sales", sort: "chickens-desc")

      assert json_response(conn, 400)
      refute get_resp_header(conn, "cache-control") == ["public, max-age=60"]
    end
  end
end
