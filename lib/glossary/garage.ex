defmodule Glossary.Garage do
  @moduledoc """
  Service module for interacting with S3-compatible storage.

  Provides functions to upload, download, and check existence of objects
  in S3-compatible storage buckets.
  """

  # Builds ExAws configuration from application config for Garage.
  defp build_config do
    garage_config = Application.get_env(:glossary, :garage, [])

    endpoint =
      Keyword.get(garage_config, :endpoint) ||
        System.get_env("S3_PROVIDER_ENDPOINT") ||
        nil

    if is_nil(endpoint) do
      raise """
      S3 storage endpoint not configured. Please set S3_PROVIDER_ENDPOINT environment variable
      or configure it in config/runtime.exs.
      """
    end

    access_key =
      Keyword.get(garage_config, :access_key_id) ||
        System.get_env("S3_PROVIDER_ACCESS_KEY") ||
        ""

    secret_key =
      Keyword.get(garage_config, :secret_access_key) ||
        System.get_env("S3_PROVIDER_SECRET_KEY") ||
        ""

    region =
      Keyword.get(garage_config, :region) ||
        System.get_env("S3_PROVIDER_REGION") ||
        "garage"

    uri = URI.parse(endpoint)
    host = uri.host
    port = uri.port || if uri.scheme == "https", do: 443, else: 80
    scheme = uri.scheme || "http"

    # Override S3 service config for custom endpoint
    Application.put_env(:ex_aws, :s3,
      scheme: scheme,
      host: host,
      port: port
    )

    [
      access_key_id: access_key,
      secret_access_key: secret_key,
      region: region,
      host: host,
      port: port,
      scheme: scheme
    ]
  end

  @doc """
  Fetches an object from an S3-compatible storage bucket.

  Returns `{:ok, content}` on success or `{:error, reason}` on failure.
  """
  def get_object(bucket, key) do
    config = build_config()

    ExAws.S3.get_object(bucket, key)
    |> ExAws.request(config)
    |> case do
      {:ok, %{body: content}} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Checks if an object exists in an S3-compatible storage bucket.

  Returns `true` if the object exists, `false` otherwise.
  """
  def object_exists?(bucket, key) do
    case get_object(bucket, key) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end
end
