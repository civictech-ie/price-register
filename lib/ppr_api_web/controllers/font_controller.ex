defmodule PprApiWeb.FontController do
  use PprApiWeb, :controller
  alias HTTPoison

  def get_font(conn, %{"font_name" => font_name}) do
    url = "https://static.civictech.ie/#{font_name}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: font_body}} ->
        conn
        |> put_resp_content_type("font/woff")
        |> put_resp_header("access-control-allow-origin", "*")
        |> send_resp(200, font_body)

      {:error, %HTTPoison.Error{reason: reason}} ->
        send_resp(conn, 500, "Failed to fetch font: #{reason}")
    end
  end
end
