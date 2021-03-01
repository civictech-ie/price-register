defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias PriceRegister.Repo

  alias PriceRegister.Properties.Sale
  alias PriceRegister.Properties.Property

  def list_properties do
    Repo.all(Property)
  end

  def get_property!(id), do: Repo.get!(Property, id)

  def upsert_property(attrs \\ %{}) do
    %Property{}
    |> Property.changeset(attrs)
    |> Repo.insert(
      returning: true,
      on_conflict: {:replace, [:address, :postal_code, :county]},
      conflict_target: [:slug]
    )
  end

  def upsert_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert(
      returning: true,
      on_conflict: :nothing,
      conflict_target: [:date, :property_id, :price]
    )
  end

  def create_property(attrs \\ %{}) do
    %Property{}
    |> Property.changeset(attrs)
    |> Repo.insert()
  end

  def update_property(%Property{} = property, attrs) do
    property
    |> Property.changeset(attrs)
    |> Repo.update()
  end

  def delete_property(%Property{} = property) do
    Repo.delete(property)
  end

  def change_property(%Property{} = property, attrs \\ %{}) do
    Property.changeset(property, attrs)
  end

  def list_sales do
    Repo.all(Sale)
  end

  def get_sale!(id), do: Repo.get!(Sale, id)

  def create_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert()
  end

  def update_sale(%Sale{} = sale, attrs) do
    sale
    |> Sale.changeset(attrs)
    |> Repo.update()
  end

  def delete_sale(%Sale{} = sale) do
    Repo.delete(sale)
  end

  def change_sale(%Sale{} = sale, attrs \\ %{}) do
    Sale.changeset(sale, attrs)
  end
end
