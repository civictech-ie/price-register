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
      |> assign(:fetches, Fetches.list_fetches())

    {:ok, socket}
  end

  @impl true
  def handle_info(%Broadcast{topic: "fetches_topic", event: "fetches_updated"}, socket) do
    # When we receive the broadcast, re-fetch data from the DB
    socket = assign(socket, :fetches, Fetches.list_fetches())
    {:noreply, socket}
  end
end
