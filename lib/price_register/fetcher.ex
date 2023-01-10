defmodule PriceRegister.Fetcher do
  use GenServer

  alias Phoenix.PubSub

  @topic :fetcher
  @interval 5_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(state) do
    schedule_fetch()
    {:ok, state}
  end

  defp schedule_fetch() do
    Process.send_after(self(), :fetch, @interval)
  end

  defp schedule_finish() do
    Process.send_after(self(), :finish, @interval)
  end

  def handle_info(:fetch, state) do
    fetch()
    schedule_finish()
    {:noreply, state}
  end

  def handle_info(:finish, state) do
    finish()
    schedule_fetch()
    {:noreply, state}
  end

  defp fetch() do
    PubSub.broadcast(PriceRegister.PubSub, "fetcher", %{status: "Fetching..."})
  end

  defp finish() do
    PubSub.broadcast(PriceRegister.PubSub, "fetcher", %{status: "Idling..."})
  end
end
