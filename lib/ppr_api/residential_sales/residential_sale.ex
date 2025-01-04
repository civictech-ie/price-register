defmodule PprApi.ResidentialSales.ResidentialSale do
  use Ecto.Schema
  import Ecto.Changeset

  alias PprApi.FingerprintHelper

  schema "residential_sales" do
    field :address, :string
    field :date_of_sale, :date
    field :county, :string
    field :eircode, :string
    field :price_in_euros, :decimal
    field :not_full_market_price, :boolean, default: false
    field :vat_exclusive, :boolean, default: false
    field :description_of_property, :string
    field :property_size_description, :string
    field :fingerprint, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(residential_sale, attrs) do
    residential_sale
    |> cast(attrs, [
      :date_of_sale,
      :address,
      :county,
      :eircode,
      :price_in_euros,
      :not_full_market_price,
      :vat_exclusive,
      :description_of_property,
      :property_size_description
    ])
    |> put_fingerprint()
    |> validate_required([
      :date_of_sale,
      :address,
      :fingerprint
    ])
  end

  defp put_fingerprint(changeset) do
    row = %{
      date_of_sale: get_field(changeset, :date_of_sale),
      address: get_field(changeset, :address),
      county: get_field(changeset, :county),
      eircode: get_field(changeset, :eircode),
      price_in_euros: get_field(changeset, :price_in_euros),
      not_full_market_price: get_field(changeset, :not_full_market_price),
      vat_exclusive: get_field(changeset, :vat_exclusive),
      description_of_property: get_field(changeset, :description_of_property),
      property_size_description: get_field(changeset, :property_size_description)
    }

    fingerprint = FingerprintHelper.compute_fingerprint(row)

    put_change(changeset, :fingerprint, fingerprint)
  end
end
