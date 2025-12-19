defmodule GlossaryWeb.FilesController do
  use GlossaryWeb, :controller

  @doc """
  Serves files from S3-compatible storage buckets.

  Route: `/:bucket_name/*path`
  - `bucket_name` is the first URL segment (e.g., "scripts", "context")
  - `path` is the remaining path segments joined (e.g., "script.sh", "subdir/file.txt")
  """
  def show(conn, %{"bucket_name" => bucket_name, "path" => path_segments}) do
    # Join path segments back into a single key
    key = Enum.join(path_segments, "/")

    case Glossary.Garage.get_object(bucket_name, key) do
      {:ok, content} ->
        content_type = detect_content_type(key)

        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=3600")
        |> send_resp(200, content)

      {:error, %{status_code: 404}} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "File not found"})

      {:error, reason} ->
        require Logger
        Logger.error("Error fetching file from S3 storage: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Internal server error"})
    end
  end

  # Detects content type based on file extension.
  defp detect_content_type(filename) do
    extension =
      filename
      |> String.downcase()
      |> Path.extname()
      |> String.trim_leading(".")

    case extension do
      "sh" -> "text/x-sh"
      "bash" -> "text/x-sh"
      "txt" -> "text/plain"
      "json" -> "application/json"
      "html" -> "text/html"
      "htm" -> "text/html"
      "css" -> "text/css"
      "js" -> "application/javascript"
      "xml" -> "application/xml"
      "pdf" -> "application/pdf"
      "zip" -> "application/zip"
      "png" -> "image/png"
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "gif" -> "image/gif"
      "svg" -> "image/svg+xml"
      "ico" -> "image/x-icon"
      _ -> "text/plain"
    end
  end
end
