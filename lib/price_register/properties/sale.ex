defmodule PriceRegister.Properties.Sale do
  use PriceRegister.Schema
  import Ecto.Changeset

  schema "sales" do
    field :date, :date
    field :description, :string
    field :full_market, :boolean, default: false
    field :price, :integer
    field :size_description, :string
    field :vat_inclusive, :boolean, default: false
    field :address, :string
    field :postal_code, :string
    field :county, :string

    timestamps()
  end

  @doc false
  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [
      :date,
      :price,
      :full_market,
      :vat_inclusive,
      :description,
      :size_description,
      :address,
      :postal_code,
      :county
    ])
    |> validate_required([
      :date,
      :price,
      :full_market,
      :vat_inclusive,
      :address,
      :county
    ])
  end
end
