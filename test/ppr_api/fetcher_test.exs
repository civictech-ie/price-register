defmodule PprApi.FetcherTest do
  use PprApi.DataCase
  import PprApi.Fixtures
  import Mock

  alias PprApi.Fetcher

  describe "run_fetch/1" do
    test "successfully processes fetch and updates status" do
      fetch = fetch_fixture(%{status: "starting"})

      with_mock HTTPoison,
        get!: fn _, _, _ ->
          %{body: "date,address,county\n01/01/2023,123 The Coombe,Dublin"}
        end do
        Fetcher.run_fetch(fetch)
        updated_fetch = Repo.reload!(fetch)

        assert updated_fetch.status == "success"
        assert updated_fetch.finished_at != nil
      end
    end

    test "handles errors appropriately" do
      fetch = fetch_fixture(%{status: "starting"})

      with_mock HTTPoison,
        get!: fn _, _, _ -> raise "Network error" end do
        Fetcher.run_fetch(fetch)
        updated_fetch = Repo.reload!(fetch)

        assert updated_fetch.status == "error"
        assert updated_fetch.error_message == "Network error"
      end
    end
  end
end
