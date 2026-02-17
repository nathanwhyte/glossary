defmodule Glossary.EntriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossary.Entries` context.
  """

  @doc """
  Generate a entry.
  """
  def entry_fixture(%Glossary.Accounts.Scope{} = current_scope, attrs) do
    merged_attrs =
      attrs
      |> Enum.into(%{
        body: "some body",
        body_text: "some body",
        subtitle: "some subtitle",
        title: "some title",
        title_text: "some title"
      })

    {:ok, entry} = Glossary.Entries.create_entry(current_scope, merged_attrs)

    entry
  end

  def entry_fixture(attrs \\ %{}) do
    current_scope = Glossary.AccountsFixtures.user_scope_fixture()
    entry_fixture(current_scope, attrs)
  end
end
