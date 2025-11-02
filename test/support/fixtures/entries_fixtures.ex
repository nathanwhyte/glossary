defmodule Glossary.EntriesFixtures do
  @moduledoc """
  Test fixtures for Glossary.Entries context.
  """

  alias Glossary.Entries

  @doc """
  Generate an entry with default or custom attributes.
  """
  def entry_fixture(attrs \\ %{}) do
    {:ok, entry} =
      attrs
      |> Enum.into(%{
        title: "Test Entry",
        description: "Test Description",
        body: "Test Body",
        status: :Draft
      })
      |> Entries.create_entry()

    entry
  end

  @doc """
  Generate a published entry.
  """
  def published_entry_fixture(attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{status: :published}))
  end

  @doc """
  Generate a draft entry.
  """
  def draft_entry_fixture(attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{status: :draft}))
  end

  @doc """
  Generate an archived entry.
  """
  def archived_entry_fixture(attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{status: :archived}))
  end

  @doc """
  Generate an entry with a specific title.
  """
  def entry_with_title(title, attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{title: title}))
  end

  @doc """
  Generate an entry with a specific body.
  """
  def entry_with_body(body, attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{body: body}))
  end
end
