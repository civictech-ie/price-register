defmodule PprApi.Storage.R2 do
  @moduledoc """
  Handles uploading CSV files to Cloudflare R2 storage.
  R2 uses S3-compatible API via ex_aws_s3.
  """

  require Logger

  @doc """
  Upload CSV content to R2.

  ## Parameters
    - path: The file path/key in the bucket (e.g., "fetches/2023-01-01.csv")
    - content: The CSV content as a string

  ## Returns
    - {:ok, path} on success
    - {:error, reason} on failure
  """
  def upload(path, content) when is_binary(content) do
    bucket = bucket_name()

    case ExAws.S3.put_object(bucket, path, content, content_type: "text/csv")
         |> ExAws.request() do
      {:ok, _response} ->
        Logger.info("Successfully uploaded CSV to R2: #{path}")
        {:ok, path}

      {:error, reason} = error ->
        Logger.error("Failed to upload CSV to R2: #{path}, reason: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Download a file from R2.

  ## Parameters
    - path: The file path/key in the bucket

  ## Returns
    - {:ok, content} if file exists
    - {:error, :not_found} if file doesn't exist
  """
  def download(path) do
    bucket = bucket_name()

    case ExAws.S3.get_object(bucket, path) |> ExAws.request() do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, {:http_error, 404, _}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Append content to an existing file in R2 by downloading, appending, and re-uploading.
  If file doesn't exist, creates it with the content.

  ## Parameters
    - path: The file path/key in the bucket
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
        {:error, reason} -> raise "Failed to download existing file: #{inspect(reason)}"
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

  defp bucket_name do
    Application.get_env(:ppr_api, :r2_bucket) ||
      raise """
      R2 bucket not configured!
      Set the R2_BUCKET environment variable.
      """
  end
end
