defmodule PriceRegisterWeb.MetadataView do
  use PriceRegisterWeb, :view

  def render("metadata.json", %{metadata: metadata}) do
    %{
      after: metadata.after,
      before: metadata.before,
      limit: metadata.limit
    }
  end
end
