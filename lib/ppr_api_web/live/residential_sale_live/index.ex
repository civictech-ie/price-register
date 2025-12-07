defmodule PprApiWeb.ResidentialSaleLive.Index do
  use PprApiWeb, :live_view
  alias PprApi.ResidentialSales

  def mount(params, _session, socket) do
    if not connected?(socket) do
      opts = parse_params(params)

      %{entries: residential_sales, metadata: metadata} =
        ResidentialSales.list_residential_sales(opts)

      socket =
        socket
        |> assign(:residential_sales, residential_sales)
        |> assign(:metadata, metadata)
        |> assign(:api_path, generate_api_path(opts))

      {:ok, socket}
    else
      {:ok,
       socket
       |> assign(:residential_sales, [])
       |> assign(:metadata, %{})
       |> assign(:api_path, "")}
    end
  end

  def handle_params(params, _url, socket) do
    opts = parse_params(params)

    %{entries: residential_sales, metadata: metadata} =
      ResidentialSales.list_residential_sales(opts)

    socket =
      socket
      |> assign(:residential_sales, residential_sales)
      |> assign(:metadata, metadata)
      |> assign(:api_path, generate_api_path(opts))

    {:noreply, socket}
  end

  def handle_event("previous", _params, socket) do
    params =
      socket.assigns.metadata
      |> Map.delete(:after_cursor)
      |> Map.delete(:total_rows)
      |> rename_key(:before_cursor, :before)

    {:noreply, push_patch(socket, to: ~p"/residential/sales?#{params}")}
  end

  def handle_event("next", _params, socket) do
    params =
      socket.assigns.metadata
      |> Map.delete(:before_cursor)
      |> Map.delete(:total_rows)
      |> rename_key(:after_cursor, :after)

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

  # Helper function to rename a key in a map
  defp rename_key(map, old_key, new_key) do
    if Map.has_key?(map, old_key) do
      value = Map.get(map, old_key)

      map
      |> Map.delete(old_key)
      |> Map.put(new_key, value)
    else
      map
    end
  end
end
