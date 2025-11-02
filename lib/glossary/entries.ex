defmodule Glossary.Entries do
  @moduledoc """
  The Entries context provides functions for managing glossary entries.
  """

  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @doc """
  Gets a single entry.
  """
  def get_entry!(id), do: Repo.get!(Entry, id)

  @doc """
  Gets a single entry or returns nil.
  """
  def get_entry(id), do: Repo.get(Entry, id)

  @doc """
  Creates a new entry.
  """
  def create_entry(attrs \\ %{}) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an entry.
  """
  def update_entry(%Entry{} = entry, attrs) do
    entry
    |> Entry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an entry.
  """
  def delete_entry(%Entry{} = entry) do
    Repo.delete(entry)
  end

  @doc """
  Returns the list of entries.
  """
  def list_entries do
    Repo.all(Entry)
  end

  @doc """
  Returns the most recently updated entries, limited to the specified count.
  """
  def list_recent_entries(limit \\ 3) do
    import Ecto.Query

    Repo.all(
      from(e in Entry,
        order_by: [desc: e.updated_at],
        limit: ^limit
      )
    )
  end
end
