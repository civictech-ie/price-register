defmodule PprApiWeb.UpController do
  use PprApiWeb, :controller

  def index(conn, _params) do
    text(conn, "ok")
  end
end
