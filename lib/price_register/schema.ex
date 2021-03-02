defmodule PriceRegister.Schema do
  @moduledoc """
  Use binary ids and autogenerate them, for now
  """

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @derive {Phoenix.Param, key: :id}
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
