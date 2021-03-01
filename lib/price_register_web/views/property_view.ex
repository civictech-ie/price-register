defmodule PriceRegisterWeb.PropertyView do
  use PriceRegisterWeb, :view
  alias PriceRegisterWeb.PropertyView

  def render("index.json", %{properties: properties}) do
    %{data: render_many(properties, PropertyView, "property.json")}
  end

  def render("show.json", %{property: property}) do
    %{data: render_one(property, PropertyView, "property.json")}
  end

  def render("property.json", %{property: property}) do
    %{id: property.id,
      address: property.address,
      postal_code: property.postal_code,
      county: property.county}
  end
end
