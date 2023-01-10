defmodule PriceRegisterWeb.FetcherLive do
  use PriceRegisterWeb, :live_view

  alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    socket = assign(socket, :status, "Idle")

    # subscribe to fetcher topic
    PubSub.subscribe(PriceRegister.PubSub, "fetcher")

    {:ok, socket}
  end

  def handle_info(%{status: status}, socket) do
    {:noreply, assign(socket, :status, status)}
  end

  def render(assigns) do
    ~H"""
    <p>Status: <%= @status %></p>
    """
  end
end
