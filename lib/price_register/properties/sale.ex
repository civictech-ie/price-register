defmodule PriceRegister.Properties.Sale do
  use PriceRegister.Schema
  import Ecto.Changeset

  schema "sales" do
    field :address, :string
    field :county, :string
    field :date_of_sale, :date
    field :description_of_property, :string
    field :eircode, :string
    field :not_full_market_price, :boolean, default: false
    field :price_in_cents, :integer
    field :property_size_description, :string
    field :vat_exclusive, :boolean, default: false
    field :source_row, :string

    timestamps()
  end

  @doc false
  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [
      :date_of_sale,
      :address,
      :county,
      :eircode,
      :price_in_cents,
      :not_full_market_price,
      :vat_exclusive,
      :description_of_property,
      :property_size_description,
      :source_row
    ])
    |> validate_required([
      :date_of_sale,
      :address,
      :county,
      :eircode,
      :price_in_cents,
      :not_full_market_price,
      :vat_exclusive,
      :description_of_property,
      :property_size_description,
      :source_row
    ])
  end
end
