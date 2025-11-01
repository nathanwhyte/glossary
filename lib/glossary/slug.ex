defmodule Glossary.Slug do
  @moduledoc """
  Utilities for generating URL-friendly slugs from strings.
  """

  @doc """
  Converts a title or arbitrary string into a URL-friendly slug.
  """
  @spec slugify(term()) :: String.t()
  def slugify(title) when is_binary(title) do
    title
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/u, "")
    |> String.replace(~r/[\s-]+/u, "-")
    |> String.trim("-")
  end

  def slugify(_), do: ""
end
