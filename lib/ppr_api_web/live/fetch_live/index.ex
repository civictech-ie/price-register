defmodule PprApiWeb.FetchLive.Index do
  use PprApiWeb, :live_view

  alias PprApi.Fetches
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to a PubSub topic for "fetches" updates
      PprApiWeb.Endpoint.subscribe("fetches_topic")
    end

    # Initial assignment
    socket =
      socket
      |> assign(:fetches, list_fetches_with_urls())

    {:ok, socket}
  end

  defp list_fetches_with_urls do
    Fetches.list_fetches()
    |> Enum.map(fn fetch ->
      %{fetch: fetch, csv_url: Fetches.get_csv_download_url(fetch)}
    end)
  end

  @impl true
  def handle_info(%Broadcast{topic: "fetches_topic", event: "fetches_updated"}, socket) do
    # When we receive the broadcast, re-fetch data from the DB
    socket = assign(socket, :fetches, list_fetches_with_urls())
    {:noreply, socket}
  end
end
