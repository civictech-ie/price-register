defmodule PprApi.PropertyRegisterTest do
  use PprApiWeb.ConnCase, async: true
  import Mock

  alias PprApi.PropertyRegister

  describe "has_the_register_been_updated_since?/1" do
    test "returns true when no previous time provided" do
      assert PropertyRegister.has_the_register_been_updated_since?(nil)
    end

    test "returns true when register was updated after given time" do
      html_response = """
      <div class="well">
        <h4>REGISTER LAST UPDATED - 01/01/2023 12:00:00</h4>
      </div>
      """

      with_mock HTTPoison,
        get: fn _ -> {:ok, %{body: html_response}} end do
        assert PropertyRegister.has_the_register_been_updated_since?(~U[2022-12-31 12:00:00Z])
      end
    end

    test "returns false when register was updated before given time" do
      html_response = """
      <div class="well">
        <h4>REGISTER LAST UPDATED - 01/01/2023 12:00:00</h4>
      </div>
      """

      with_mock HTTPoison,
        get: fn _ -> {:ok, %{body: html_response}} end do
        refute PropertyRegister.has_the_register_been_updated_since?(~U[2023-01-02 12:00:00Z])
      end
    end

    test "returns false when HTTP request fails" do
      with_mock HTTPoison,
        get: fn _ -> {:error, %HTTPoison.Error{reason: :timeout}} end do
        refute PropertyRegister.has_the_register_been_updated_since?(~U[2023-01-01 12:00:00Z])
      end
    end
  end
end
