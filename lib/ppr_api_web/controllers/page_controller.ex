defmodule PprApiWeb.PageController do
  use PprApiWeb, :controller

  def info(conn, _params) do
    render(conn, "info.html")
  end
end
