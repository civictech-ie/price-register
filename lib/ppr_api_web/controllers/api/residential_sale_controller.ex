defmodule PprApiWeb.API.ResidentialSaleController do
  use PprApiWeb, :controller

  alias PprApi.ResidentialSales

  action_fallback PprApiWeb.FallbackController

  def index(conn, _params) do
    residential_sales = ResidentialSales.list_residential_sales(limit: 100)
    render(conn, :index, residential_sales: residential_sales)
  end
end
