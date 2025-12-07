defmodule PprApi.Storage.LocalDisk do
  @moduledoc """
  Handles saving CSV files to local disk for development.
  Uses the same interface as R2 for consistency.
  """

  require Logger

  @csv_dir System.get_env("FETCH_CSV_DIR") || "./priv/fetches"

  @doc """
  Upload CSV content to local disk.

  ## Parameters
    - path: The file path relative to csv_dir (e.g., "fetches/2023-01-01.csv")
    - content: The CSV content as a string

  ## Returns
    - {:ok, path} on success
    - {:error, reason} on failure
  """
  def upload(path, content) when is_binary(content) do
    full_path = Path.join(@csv_dir, path)
    dir = Path.dirname(full_path)

    File.mkdir_p!(dir)

    case File.write(full_path, content) do
      :ok ->
        Logger.info("Successfully saved CSV to disk: #{full_path}")
        {:ok, path}

      {:error, reason} = error ->
        Logger.error("Failed to save CSV to disk: #{full_path}, reason: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Download a file from local disk.

  ## Parameters
    - path: The file path relative to csv_dir

  ## Returns
    - {:ok, content} if file exists
    - {:error, :not_found} if file doesn't exist
  """
  def download(path) do
    full_path = Path.join(@csv_dir, path)

    case File.read(full_path) do
      {:ok, content} -> {:ok, content}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Append content to an existing file on disk.
  If file doesn't exist, creates it with the content.

  ## Parameters
    - path: The file path relative to csv_dir
    - content: The content to append

  ## Returns
    - {:ok, path} on success
    - {:error, reason} on failure
  """
  def append(path, content) when is_binary(content) do
    existing_content =
      case download(path) do
        {:ok, body} -> body
        {:error, :not_found} -> ""
        {:error, reason} -> raise "Failed to read existing file: #{inspect(reason)}"
      end

    new_content = existing_content <> content
    upload(path, new_content)
  end

  @doc """
  Generate the full path for a CSV file based on date range.

  ## Parameters
    - starts_on: Start date
    - started_at: End datetime

  ## Returns
    - String path like "fetches/2023-01-01-2023-02-01.csv"
  """
  def generate_path(starts_on, started_at) do
    end_date = DateTime.to_date(started_at)
    "fetches/#{Date.to_string(starts_on)}-#{Date.to_string(end_date)}.csv"
  end
end
