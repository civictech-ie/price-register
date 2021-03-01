defmodule PriceRegister.Properties.Sale do
  use PriceRegister.Schema
  import Ecto.Changeset

  alias PriceRegister.Properties.Property

  schema "sales" do
    field :date, :date
    field :description, :string
    field :market_price, :boolean, default: false
    field :price, :integer
    field :size_description, :string
    field :vat_inclusive, :boolean, default: false
    belongs_to :property, Property, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [
      :date,
      :price,
      :market_price,
      :vat_inclusive,
      :description,
      :size_description,
      :property_id
    ])
    |> validate_required([
      :date,
      :price,
      :market_price,
      :vat_inclusive,
      :property_id
    ])
  end
end
