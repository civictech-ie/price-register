defmodule PprApiWeb.ResidentialSaleController do
  use PprApiWeb, :controller
  alias PprApi.ResidentialSales

  def index(conn, params) do
    opts = parse_pagination_params(params)

    %{entries: residential_sales, metadata: metadata} =
      ResidentialSales.list_residential_sales(opts)

    api_path = generate_api_path(conn, params)

    render(conn, "index.html",
      residential_sales: residential_sales,
      metadata: metadata,
      api_path: api_path
    )
  end

  defp parse_pagination_params(params) do
    limit =
      case Map.get(params, "limit", 250) do
        value when is_binary(value) -> String.to_integer(value)
        value when is_integer(value) -> value
      end

    include_total_count =
      case Map.get(params, "include_total_count", false) do
        value when is_binary(value) -> String.to_existing_atom(value)
        value when is_boolean(value) -> value
      end

    [
      limit: limit,
      after: Map.get(params, "after"),
      before: Map.get(params, "before"),
      include_total_count: include_total_count
    ]
  end

  defp generate_api_path(conn, params) do
    query_params = URI.encode_query(params)
    api_path = ~p"/api/v1/residential/sales"
    "#{api_path}?#{query_params}"
  end
end
