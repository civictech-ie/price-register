defmodule PriceRegister.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias PriceRegister.Repo
  alias PriceRegister.Properties.Sale

  @doc """
  Returns the count of sales
  """
  def sales_count do
    Repo.aggregate(Sale, :count, :id)
  end

  @doc """
  Returns the list of sales.

  ## Examples

      iex> list_sales()
      [%Sale{}, ...]

  """
  def list_sales() do
    %{
      entries: entries,
      metadata: %{after: after_key, before: before_key, limit: limit, total_count: total_count}
    } =
      Sale
      |> order_by({:desc, :inserted_at})
      |> Repo.paginate(include_total_count: true, total_count_limit: :infinity)

    %{
      entries: entries,
      metadata: %{
        after: after_key,
        before: before_key,
        limit: limit,
        total_count: total_count,
        updated_at: get_updated_at()
      }
    }
  end

  def list_sales(after: after_cursor) do
    %{
      entries: entries,
      metadata: %{after: after_key, before: before_key, limit: limit, total_count: total_count}
    } =
      Sale
      |> order_by({:desc, :inserted_at})
      |> Repo.paginate(
        after: after_cursor,
        include_total_count: true,
        total_count_limit: :infinity
      )

    %{
      entries: entries,
      metadata: %{
        after: after_key,
        before: before_key,
        limit: limit,
        total_count: total_count,
        updated_at: get_updated_at()
      }
    }
  end

  def list_sales(before: before_cursor) do
    %{
      entries: entries,
      metadata: %{after: after_key, before: before_key, limit: limit, total_count: total_count}
    } =
      Sale
      |> order_by({:desc, :inserted_at})
      |> Repo.paginate(
        before: before_cursor,
        include_total_count: true,
        total_count_limit: :infinity
      )

    %{
      entries: entries,
      metadata: %{
        after: after_key,
        before: before_key,
        limit: limit,
        total_count: total_count,
        updated_at: get_updated_at()
      }
    }
  end

  @doc """
  Returns the list of sales between the beginning and end of the given month
  """

  def list_sales_for_month(date) do
    beginning_of_month = date |> Date.beginning_of_month()
    end_of_month = date |> Date.end_of_month()
    Repo.all(
      from s in Sale,
      where: s.date_of_sale >= ^beginning_of_month and s.date_of_sale <= ^end_of_month
    )
  end

  def insert_sales(sales) do
    Repo.insert_all(Sale, sales)
  end

  def insert_sales_in_batches(sales) do
    Repo.transaction(fn ->
      Enum.each(Enum.chunk_every(sales, 1000), fn chunk ->
        Repo.insert_all(Sale, chunk)
      end)
    end)
  end

  @doc """
  Gets a single sale.

  Raises `Ecto.NoResultsError` if the Sale does not exist.

  ## Examples

      iex> get_sale!(123)
      %Sale{}

      iex> get_sale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_sale!(id), do: Repo.get!(Sale, id)

  @doc """
  Creates a sale.

  ## Examples

      iex> create_sale(%{field: value})
      {:ok, %Sale{}}

      iex> create_sale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_sale(attrs \\ %{}) do
    %Sale{}
    |> Sale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sale.

  ## Examples

      iex> update_sale(sale, %{field: new_value})
      {:ok, %Sale{}}

      iex> update_sale(sale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_sale(%Sale{} = sale, attrs) do
    sale
    |> Sale.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sale.

  ## Examples

      iex> delete_sale(sale)
      {:ok, %Sale{}}

      iex> delete_sale(sale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_sale(%Sale{} = sale) do
    Repo.delete(sale)
  end

  @doc """
  Deletes the sales between the beginning and end of the given month
  """

  def delete_sales_for_month(date) do
    beginning_of_month = date |> Date.beginning_of_month()
    end_of_month = date |> Date.end_of_month()
    Repo.delete_all(
      from s in Sale,
      where: s.date_of_sale >= ^beginning_of_month and s.date_of_sale <= ^end_of_month
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sale changes.

  ## Examples

      iex> change_sale(sale)
      %Ecto.Changeset{data: %Sale{}}

  """
  def change_sale(%Sale{} = sale, attrs \\ %{}) do
    Sale.changeset(sale, attrs)
  end

  defp get_updated_at do
    Repo.aggregate(Sale, :max, :updated_at)
  end
end
