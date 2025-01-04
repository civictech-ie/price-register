defmodule PprApiWeb.ResidentialSaleLive.Index do
  use PprApiWeb, :live_view
  alias PprApi.ResidentialSales
  alias PprApi.Pagination

  def mount(_params, _session, socket) do
    opts = [page: 1, per_page: 250]

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
    opts = Pagination.parse_pagination_params(params)

    %{entries: residential_sales, metadata: metadata} =
      ResidentialSales.list_residential_sales(opts)

    socket =
      socket
      |> assign(:residential_sales, residential_sales)
      |> assign(:metadata, metadata)
      |> assign(:api_path, generate_api_path(params))

    {:noreply, socket}
  end

  def handle_event("nav", %{"page" => page}, socket) do
    params = %{
      "page" => page,
      "per_page" => socket.assigns.metadata.per_page
    }

    {:noreply, push_patch(socket, to: ~p"/residential/sales?#{params}")}
  end

  defp generate_api_path(params) do
    ~p"/api/v1/residential/sales?#{params}"
  end
end
