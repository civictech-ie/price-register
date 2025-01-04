defmodule PprApi.PropertyRegister do
  alias Floki
  alias Timex

  @url "https://propertypriceregister.ie"

  def has_the_register_been_updated_since?(nil), do: true

  def has_the_register_been_updated_since?(time) do
    case fetch_last_update_time() do
      {:ok, last_update_time} ->
        DateTime.compare(DateTime.from_naive!(last_update_time, "Etc/UTC"), time) == :gt

      {:error, _} ->
        false
    end
  end

  defp fetch_last_update_time do
    case HTTPoison.get(@url) do
      {:ok, %{body: body}} ->
        parse_last_update_time(body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_last_update_time(html) do
    {:ok, document} = Floki.parse_document(html)

    case Floki.find(document, "div.well h4") do
      [update_time | _] ->
        update_time
        |> Floki.text()
        |> String.replace("REGISTER LAST UPDATED - ", "")
        |> Timex.parse!("{0D}/{0M}/{YYYY} {h24}:{m}:{s}")
        |> then(&{:ok, &1})

      _ ->
        {:error, :timestamp_not_found}
    end
  end
end
