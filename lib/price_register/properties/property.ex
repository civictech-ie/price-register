defmodule PriceRegister.Properties.Property do
  use PriceRegister.Schema
  import Ecto.Changeset

  alias PriceRegister.Properties.Sale

  schema "properties" do
    field :address, :string
    field :county, :string
    field :postal_code, :string
    field :slug, :string
    has_many :sales, Sale

    timestamps()
  end

  @doc false
  def changeset(property, attrs) do
    property
    |> cast(attrs |> Map.put(:slug, generate_slug(attrs)), [
      :slug,
      :address,
      :postal_code,
      :county
    ])
    |> validate_required([:address, :slug])
  end

  defp generate_slug(%{address: nil}), do: nil
  defp generate_slug(%{address: ""}), do: nil

  defp generate_slug(%{address: address, postal_code: postal_code, county: county})
       when is_binary(address) and is_binary(county) do
    [address, postal_code, county]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&String.trim/1)
    |> Enum.join(" ")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/(\s|-)+/, "-")
  end

  defp generate_slug(_params), do: nil
end
