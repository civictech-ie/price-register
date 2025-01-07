defmodule PprApi.Pagination do
  import Ecto.Query

  @default_limit 250
  @max_limit 1000

  def default_limit, do: @default_limit
  def max_limit, do: @max_limit
end
