defmodule PprApi.PropertyRegister do
  alias Floki
  alias Timex

  @url "https://www.propertypriceregister.ie/website/npsra/pprweb.nsf/PPR"

  def has_the_register_been_updated_since?(nil), do: true

  def has_the_register_been_updated_since?(time) do
    time_in_zone = Timex.to_datetime(time, "Europe/Dublin")

    case fetch_last_update_time() do
      {:ok, last_update_time} ->
        DateTime.compare(last_update_time, time_in_zone) == :gt

      {:error, _} ->
        false
    end
  end

  defp fetch_last_update_time do
    case HTTPoison.get(@url, [], hackney: [insecure: true]) do
      {:ok, %{body: html}} ->
        parse_last_update_time(html)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_last_update_time(html) do
    with {:ok, document} <- Floki.parse_document(html),
         [update_time | _] <- Floki.find(document, "#LastUpdated"),
         update_time_text = Floki.text(update_time),
         [_, datetime_str] <-
           Regex.run(~r/(\d{2}\/\d{2}\/\d{4} \d{2}:\d{2}:\d{2})/, update_time_text),
         {:ok, naive_datetime} <-
           Timex.parse(datetime_str, "{0D}/{0M}/{YYYY} {h24}:{m}:{s}"),
         local_datetime <-
           Timex.to_datetime(naive_datetime, "Europe/Dublin") do
      {:ok, local_datetime |> Timex.to_datetime("Europe/Dublin")}
    else
      _error ->
        {:error, :timestamp_not_found}
    end
  end
end
