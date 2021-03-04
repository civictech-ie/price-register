defmodule PriceRegister.FetchScheduler do
  use GenServer

  alias PriceRegister.SaleFetcher

  @interval 60_000
  @table_name :fetcher_status

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(state) do
    setup_ets()
    schedule_fetch()
    {:ok, state}
  end

  def handle_info(:fetch, _state) do
    SaleFetcher.fetch!()

    :ets.insert(@table_name, {"updated_at", DateTime.utc_now() |> DateTime.to_string()})

    schedule_fetch()

    {:noreply, []}
  end

  defp setup_ets do
    case :ets.whereis(@table_name) do
      :undefined ->
        :ets.new(@table_name, [:set, :protected, :named_table])

      _ ->
        nil
    end
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch, @interval)
  end
end
