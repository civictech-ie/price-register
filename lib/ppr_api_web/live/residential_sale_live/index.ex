defmodule PprApiWeb.ResidentialSaleLive.Index do
  use PprApiWeb, :live_view
  alias PprApi.ResidentialSales
  alias PprApi.Pagination

  def mount(params, _session, socket) do
    opts =
      params
      |> parse_params()

    %{entries: residential_sales, metadata: metadata} =
      ResidentialSales.list_residential_sales(opts)

    socket =
      socket
      |> assign(:residential_sales, residential_sales)
      |> assign(:metadata, metadata)
      |> assign(:api_path, generate_api_path(opts))

    {:ok, socket}
  end

  def handle_params(params, _url, socket) do
    opts =
      params
      |> parse_params()

    %{entries: residential_sales, metadata: metadata} =
      ResidentialSales.list_residential_sales(opts)

    socket =
      socket
      |> assign(:residential_sales, residential_sales)
      |> assign(:metadata, metadata)
      |> assign(:api_path, generate_api_path(opts))

    {:ok, socket}

    {:noreply, socket}
  end

  def handle_event("navigate", %{"direction" => direction, "cursor" => cursor}, socket) do
    params = %{
      direction => cursor
    }

    {:noreply, push_patch(socket, to: ~p"/residential/sales?#{params}")}
  end

  defp generate_api_path(opts) do
    ~p"/api/v1/residential/sales?#{opts}"
  end

  # takes params and returns a map of only keys in the defaults,
  # and uses the default values if they are not present
  defp parse_params(params) do
    defaults = %{
      "sort" => "date-desc",
      "before" => nil,
      "after" => nil,
      "limit" => Pagination.default_limit()
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
