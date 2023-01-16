defmodule PriceRegisterWeb.FetcherLive do
  use PriceRegisterWeb, :live_view

  alias Phoenix.PubSub

  @table :fetcher_status
  @topic "fetcher_status"

  def mount(_params, _session, socket) do
    [status: status] = :ets.lookup(@table, :status)

    socket = assign(socket, :status, status)
    socket = assign(socket, :sales_count, PriceRegister.Properties.sales_count())

    PubSub.subscribe(PriceRegister.PubSub, @topic)

    {:ok, socket}
  end

  def handle_info(%{status: _status}, socket) do
    [status: status] = :ets.lookup(@table, :status)

    socket = assign(socket, :status, status)
    socket = assign(socket, :sales_count, PriceRegister.Properties.sales_count())

    {:noreply, assign(socket, :status, status)}
  end

  def render(assigns) do
    ~H"""
    <p>Status: <%= @status %></p>
    <p>Sales: <%= @sales_count %></p>
    """
  end
end
