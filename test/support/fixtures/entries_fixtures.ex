defmodule Glossary.EntriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossary.Entries` context.
  """

  @doc """
  Generate a entry.
  """
  def entry_fixture(attrs \\ %{}) do
    {:ok, entry} =
      attrs
      |> Enum.into(%{
        body: "some body",
        body_text: "some body",
        subtitle: "some subtitle",
        title: "some title",
        title_text: "some title"
      })
      |> Glossary.Entries.create_entry()

    entry
  end
end
