defmodule PriceRegisterWeb.MetadataView do
  use PriceRegisterWeb, :view
  alias PriceRegisterWeb.MetadataView

  def render("metadata.json", %{metadata: metadata}) do
    %{
      after: metadata.after,
      before: metadata.before,
      limit: metadata.limit,
      total_count: metadata.total_count
    }
  end
end
