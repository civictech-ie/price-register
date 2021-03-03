defmodule PriceRegister.Properties.Sale do
  use PriceRegister.Schema
  import Ecto.Changeset

  schema "sales" do
    field :date, :date
    field :address, :string, default: ""
    field :postal_code, :string, default: ""
    field :county, :string, default: ""
    field :price, :integer
    field :description, :string, default: ""
    field :full_market, :boolean, default: false
    field :size_description, :string, default: ""
    field :vat_inclusive, :boolean, default: false

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
