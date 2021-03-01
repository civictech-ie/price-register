defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias PriceRegister.Repo

  alias PriceRegister.Properties.Sale

  def list_sales do
    Repo.all(Sale)
  end

  def upsert_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert(
      returning: true,
      on_conflict: :nothing,
      conflict_target: [:date, :address, :postal_code, :county, :price]
    )
  end

  def get_sale!(id), do: Repo.get!(Sale, id)
end
