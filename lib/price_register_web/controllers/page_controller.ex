defmodule PriceRegisterWeb.PageController do
  use PriceRegisterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
