defmodule PprApi.FetcherTest do
  use PprApi.DataCase
  import PprApi.Fixtures
  import Mock

  alias PprApi.Fetcher

  describe "run_fetch/1" do
    @tag timeout: 30_000
    test "successfully processes fetch and updates status" do
      # Use current month so it only fetches one month
      current_month = Date.utc_today() |> Date.beginning_of_month()
      fetch = fetch_fixture(%{status: "starting", starts_on: current_month})

      csv_data = """
      Date of Sale (dd/mm/yyyy),Address,County,Eircode,Price (€),Not Full Market Price,VAT Exclusive,Description of Property,Property Size Description
      01/01/2023,123 The Coombe,Dublin,D08 XYZ1,100000.00,No,No,Second-Hand Dwelling house /Apartment,greater than or equal to 38 sq metres and less than 125 sq metres
      """

      with_mock HTTPoison,
        get: fn _url, _headers, _opts ->
          {:ok,
           %HTTPoison.Response{
             status_code: 200,
             headers: [{"content-type", "application/octet-stream"}],
             body: csv_data
           }}
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
        get: fn _url, _headers, _opts ->
          {:error, %HTTPoison.Error{reason: :timeout, id: nil}}
        end do
        Fetcher.run_fetch(fetch)
        updated_fetch = Repo.reload!(fetch)

        assert updated_fetch.status == "error"
        assert String.contains?(updated_fetch.error_message, "timeout")
      end
    end
  end
end
