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
    field :source_row, :string

    timestamps()
  end

  @doc false
  def changeset(sale, attrs) do
    sale
    |> cast(attrs |> generate_source_row, [
      :date,
      :price,
      :full_market,
      :vat_inclusive,
      :description,
      :size_description,
      :address,
      :postal_code,
      :county,
      :source_row
    ])
    |> validate_required([
      :date,
      :price,
      :full_market,
      :vat_inclusive,
      :address,
      :county,
      :source_row
    ])
    |> unique_constraint(:source_row)
  end

  defp generate_source_row(%{date: %Date{} = date, index: index} = attrs) do
    year_str = date.year |> Integer.to_string()
    month_str = date.month |> Integer.to_string() |> String.pad_leading(2, "0")
    index_str = index |> Integer.to_string()

    attrs |> Map.put(:source_row, "#{year_str}-#{month_str}-#{index_str}")
  end

  defp generate_source_row(attrs), do: attrs
end
