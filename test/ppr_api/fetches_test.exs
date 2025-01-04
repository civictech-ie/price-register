defmodule PprApi.FetchesTest do
  use PprApi.DataCase
  import PprApi.Fixtures
  import Mock

  alias PprApi.Fetches
  alias PprApi.PropertyRegister

  describe "list_fetches/0" do
    test "returns all fetches" do
      fetch1 = fetch_fixture()
      fetch2 = fetch_fixture()

      fetches = Fetches.list_fetches()
      assert [fetch1.id, fetch2.id] == Enum.map(fetches, & &1.id)
    end
  end

  describe "fetch_latest_sales/1" do
    test "creates new fetch when update is due" do
      with_mock PropertyRegister, has_the_register_been_updated_since?: fn _ -> true end do
        {:ok, fetch} = Fetches.fetch_latest_sales()
        assert fetch.status == "starting"
        assert fetch.starts_on != nil
      end
    end

    test "skips fetch when no update is due" do
      with_mock PropertyRegister, has_the_register_been_updated_since?: fn _ -> false end do
        assert {:ok, :no_update_needed} = Fetches.fetch_latest_sales()
      end
    end
  end

  describe "mark_fetch_as_fetching/1" do
    test "updates fetch status from starting to fetching" do
      fetch = fetch_fixture(%{status: "starting"})
      updated_fetch = Fetches.mark_fetch_as_fetching(fetch)
      assert updated_fetch.status == "fetching"
    end
  end
end
