defmodule PprApi.Fetches do
  @moduledoc """
  The Fetches context.
  """

  import Ecto.Query
  alias PprApi.ResidentialSales
  alias PprApi.Repo
  alias PprApi.PropertyRegister
  alias PprApi.Fetches.Fetch
  alias PprApiWeb.Endpoint

  @first_month_on_record ~D[2010-01-01]

  @doc """
  List 50 fetch records, most recent first.
  """
  def list_fetches do
    from(f in Fetch,
      order_by: [desc: f.started_at],
      limit: 50
    )
    |> Repo.all()
  end

  def get_latest_successful_fetch do
    from(f in Fetch,
      where: f.status == "success",
      order_by: [desc: f.finished_at],
      limit: 1
    )
    |> Repo.one()
  end

  def get_latest_successful_full_fetch do
    from(f in Fetch,
      where: f.status == "success" and f.starts_on == ^@first_month_on_record,
      order_by: [desc: f.finished_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Fetch the latest updates from the Property Register.
  Starts syncing from the month of the latest sale in the db.
  Uses update_due? to decide if it should fetch, unless force is true.
  """
  def fetch_latest_sales(force \\ false) do
    if force || update_due?() do
      fetch_since(ResidentialSales.latest_sale_date())
    else
      {:ok, :no_update_needed}
    end
  end

  @doc """
  Fetch everything from Property Register since 2010.
  """
  def fetch_all_sales(force \\ false) do
    if force || update_due?() do
      fetch_since(nil)
    else
      {:ok, :no_update_needed}
    end
  end

  defp update_due? do
    time_of_latest_fetch()
    |> PropertyRegister.has_the_register_been_updated_since?()
  end

  defp time_of_latest_fetch do
    query =
      from(f in Fetch,
        where: f.status in ["starting", "success", "fetching"],
        order_by: [desc: f.started_at],
        limit: 1
      )

    case Repo.one(query) do
      nil ->
        nil

      fetch ->
        fetch.started_at
    end
  end

  defp fetch_since(starts_on) do
    fetch =
      %Fetch{}
      |> Fetch.changeset(%{
        starts_on: starts_on || @first_month_on_record,
        current_month: starts_on,
        started_at: DateTime.utc_now()
      })
      |> Repo.insert!()

    broadcast_updates()

    Task.start(fn ->
      PprApi.Fetcher.run_fetch(fetch)
    end)

    {:ok, fetch}
  end

  @doc """
    Mark the fetch as fetching.
    Can only be called once on a fetch of status 'starting'.
  """
  def mark_fetch_as_fetching(%Fetch{status: "starting"} = fetch) do
    updated_fetch =
      fetch
      |> Fetch.changeset(%{status: "fetching"})
      |> Repo.update!()

    broadcast_updates()
    updated_fetch
  end

  @doc """
  Update a fetch record's progress, typically called from within the running task.
  Only should be called when the fetch is 'fetching'.
  """
  def update_fetch_progress(%Fetch{status: "fetching"} = fetch, attrs) do
    updated_fetch =
      from(f in Fetch,
        where: f.id == ^fetch.id,
        update: [
          set: [current_month: ^attrs[:current_month]],
          inc: [total_rows: ^attrs[:increment_by]]
        ]
      )
      |> Repo.update_all([])

    broadcast_updates()
    updated_fetch
  end

  @doc """
  Mark a fetch as successfully completed, setting status and finished time.
  """
  def mark_fetch_success(%Fetch{status: "fetching"} = fetch) do
    updated_fetch =
      fetch
      |> Fetch.changeset(%{
        status: "success",
        finished_at: DateTime.utc_now()
      })
      |> Repo.update!()

    broadcast_updates()
    updated_fetch
  end

  @doc """
  Mark a fetch as failed, capturing any error message and finishing time.
  """
  def mark_fetch_error(%Fetch{} = fetch, error_message) do
    updated_fetch =
      fetch
      |> Fetch.changeset(%{
        status: "error",
        error_message: error_message,
        finished_at: DateTime.utc_now()
      })
      |> Repo.update!()

    broadcast_updates()
    updated_fetch
  end

  @doc """
  Get the CSV download URL for a fetch if it exists in storage.
  Returns nil if CSV saving is disabled or if fetch hasn't completed.
  """
  def get_csv_download_url(%Fetch{status: "success", starts_on: starts_on, started_at: started_at}) do
    if csv_saving_enabled?() do
      storage = storage_adapter()
      path = storage.generate_path(starts_on, started_at)

      case storage.presigned_url(path) do
        {:ok, url} -> url
        {:error, _} -> nil
      end
    else
      nil
    end
  end

  def get_csv_download_url(_fetch), do: nil

  defp csv_saving_enabled? do
    case System.get_env("SAVE_FETCH_CSV") do
      "true" -> true
      _ -> false
    end
  end

  defp storage_adapter do
    Application.get_env(:ppr_api, :storage_adapter, PprApi.Storage.LocalDisk)
  end

  defp broadcast_updates do
    Endpoint.broadcast("fetches_topic", "fetches_updated", %{})
  end
end
