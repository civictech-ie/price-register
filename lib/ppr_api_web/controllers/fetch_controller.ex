defmodule PprApiWeb.FetchController do
  use PprApiWeb, :controller

  alias PprApi.Fetches

  # Render the main fetch page with buttons
  def index(conn, _params) do
    fetches = Fetches.list_fetches()
    render(conn, :index, fetches: fetches)
  end
end
