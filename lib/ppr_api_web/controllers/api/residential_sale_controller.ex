defmodule PprApiWeb.API.ResidentialSaleController do
  use PprApiWeb, :controller

  alias PprApi.ResidentialSales

  action_fallback PprApiWeb.FallbackController

  def index(conn, params) do
    with {:ok, opts} <- parse_params(params) do
      %{entries: entries, metadata: metadata} =
        ResidentialSales.list_residential_sales(opts)

      render(conn, :index, entries: entries, metadata: metadata)
    end
  end

  defp parse_params(params) do
    defaults = %{
      "sort" => "date-desc",
      "before" => nil,
      "after" => nil,
      "limit" => 250
    }

    filtered_params =
      params
      |> Map.take(Map.keys(defaults))
      |> Enum.reject(fn
        {_key, nil} -> true
        {_key, value} when is_binary(value) -> String.trim(value) == ""
        {_key, _value} -> false
      end)
      |> Enum.into(%{})

    opts = Map.merge(defaults, filtered_params)

    case ResidentialSales.parse_sort(opts["sort"]) do
      {:ok, sort} -> {:ok, Map.put(opts, "sort", sort)}
      :error -> {:error, :bad_request}
    end
  end
end
