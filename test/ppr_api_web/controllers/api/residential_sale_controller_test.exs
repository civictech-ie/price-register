defmodule PprApiWeb.API.ResidentialSaleControllerTest do
  use PprApiWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
  end
end
