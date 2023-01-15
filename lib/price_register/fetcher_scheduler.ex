defmodule PriceRegister.FetcherScheduler do
  use GenServer

  alias Phoenix.PubSub
  alias PriceRegister.Fetcher

  @table :fetcher
  @topic "fetcher"
  @interval 1_800_000

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(state) do
    setup_ets_table_for_status_and_updated()
    # schedule_fetch()
    Process.send_after(self(), :fetch, 1_00)
    {:ok, state}
  end

  defp setup_ets_table_for_status_and_updated() do
    # if table doesn't exist, create it
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:set, :named_table, :protected])
      :ets.insert(@table, {:status, "Idle"})
      :ets.insert(@table, {:updated, nil})
    end
  end

  defp schedule_fetch() do
    Process.send_after(self(), :fetch, @interval)
  end

  def handle_info(:fetch, state) do
    update_fetcher_status(:fetch)
    run_fetch()
    update_fetcher_status(:idle)
    schedule_fetch()
    {:noreply, state}
  end

  defp run_fetch() do
    Fetcher.fetch()
  end

  defp update_fetcher_status(:idle) do
    :ets.insert(@table, {:status, "Idling..."})
    PubSub.broadcast(PriceRegister.PubSub, @topic, %{status: "Idling..."})
  end

  defp update_fetcher_status(:fetch) do
    :ets.insert(@table, {:status, "Fetching..."})
    PubSub.broadcast(PriceRegister.PubSub, @topic, %{status: "Fetching..."})
  end
end
