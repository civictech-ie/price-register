defmodule PriceRegisterWeb.API.MetadataView do
  use PriceRegisterWeb, :view

  def render("metadata.json", %{metadata: metadata}) do
    %{
      after: metadata.after,
      before: metadata.before,
      limit: metadata.limit,
      updated_at: metadata.updated_at,
      total_count: metadata.total_count
    }
  end
end
