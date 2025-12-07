defmodule PprApi.Fixtures do
  alias PprApi.Repo
  alias PprApi.Fetches.Fetch
  alias PprApi.ResidentialSales.ResidentialSale

  def fetch_fixture(attrs \\ %{}) do
    {:ok, fetch} =
      attrs
      |> Enum.into(%{
        status: "starting",
        starts_on: ~D[2023-01-01],
        started_at: DateTime.utc_now()
      })
      |> then(&Fetch.changeset(%Fetch{}, &1))
      |> Repo.insert()

    fetch
  end

  def residential_sale_fixture(attrs \\ %{}) do
    {:ok, sale} =
      attrs
      |> Enum.into(%{
        date_of_sale: ~D[2023-01-01],
        address: "123 Test St",
        county: "Dublin",
        price_in_euros: Decimal.new("100000"),
        not_full_market_price: false,
        vat_exclusive: false
      })
      |> then(&ResidentialSale.changeset(%ResidentialSale{}, &1))
      |> Repo.insert()

    sale
  end
end
