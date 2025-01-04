defmodule PprApi.Pagination do
  import Ecto.Query

  @default_per_page 250
  @max_per_page 1000

  def parse_pagination_params(params) do
    page =
      case Map.get(params, "page", "1") do
        value when is_binary(value) -> String.to_integer(value)
        value when is_integer(value) -> value
      end

    per_page =
      case Map.get(params, "per_page", @default_per_page) do
        value when is_binary(value) -> String.to_integer(value)
        value when is_integer(value) -> value
      end
      |> min(@max_per_page)

    [page: page, per_page: per_page]
  end

  def paginate(query, repo, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, @default_per_page) |> min(@max_per_page)

    total_count = repo.aggregate(query, :count)

    entries =
      query
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> repo.all()

    %{
      entries: entries,
      metadata: %{
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: ceil(total_count / per_page)
      }
    }
  end
end
