defmodule PprApiWeb.API.ResidentialSaleController do
  use PprApiWeb, :controller

  alias PprApi.ResidentialSales

  action_fallback PprApiWeb.FallbackController

  def index(conn, params) do
    opts =
      params
      |> parse_params()

    %{entries: entries, metadata: metadata} =
      ResidentialSales.list_residential_sales(opts)

    render(conn, :index, entries: entries, metadata: metadata)
  end

  defp parse_params(params) do
    defaults = %{
      "sort" => "date-desc",
      "before" => nil,
      "after" => nil,
      "limit" => 250
    }

    defaults
    |> Map.merge(Map.take(params, Map.keys(defaults)))
    |> Enum.reject(fn
      {_key, nil} -> true
      {_key, value} when is_binary(value) -> String.trim(value) == ""
      {_key, _value} -> false
    end)
    |> Enum.into(%{})
  end
end
