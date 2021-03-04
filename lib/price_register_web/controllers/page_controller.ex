defmodule PriceRegisterWeb.PageController do
  use PriceRegisterWeb, :controller

  def info(conn, _params) do
    render(conn, "info.html")
  end
end
