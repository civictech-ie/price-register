defmodule PriceRegister.FetchScheduler do
  use GenServer

  alias PriceRegister.SaleFetcher

  @interval 60_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(state) do
    seed_database()
    {:ok, state}
  end

  def handle_info(:fetch, _state) do
    SaleFetcher.fetch!()

    schedule_fetch()

    {:noreply, []}
  end

  defp seed_database() do
    schedule_fetch()
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch, @interval)
  end
end
