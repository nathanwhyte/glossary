defmodule Glossary.Entries do
  @moduledoc """
  The Entries context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Repo

  alias Glossary.Entries.Entry

  @doc """
  Returns the list of entries.

  ## Examples

      iex> list_entries()
      [%Entry{}, ...]

  """
  def list_entries do
    Repo.all(Entry)
  end

  @doc """
  Returns the list of the X most recent entries.

  ## Examples

      iex> list_entries(3)
      [%Entry{}, %Entry{}, %Entry{},]

  """
  def recent_entries(count \\ 7) do
    Repo.all(Entry |> order_by(desc: :inserted_at) |> limit(^count))
  end

  @doc """
  Gets a single entry.

  Raises `Ecto.NoResultsError` if the Entry does not exist.

  ## Examples

      iex> get_entry!(123)
      %Entry{}

      iex> get_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_entry!(id), do: Repo.get!(Entry, id)

  @doc """
  Creates a entry.

  ## Examples

      iex> create_entry(%{field: value})
      {:ok, %Entry{}}

      iex> create_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_entry(attrs) do
    %Entry{}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a entry.

  ## Examples

      iex> update_entry(entry, %{field: new_value})
      {:ok, %Entry{}}

      iex> update_entry(entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_entry(%Entry{} = entry, attrs) do
    entry
    |> Entry.changeset(attrs)
    |> Repo.update()
  end

  def upsert_entry(%Entry{id: nil}, attrs) do
    create_entry(attrs)
  end

  def upsert_entry(%Entry{} = entry, attrs) do
    update_entry(entry, attrs)
  end

  @doc """
  Deletes a entry.

  ## Examples

      iex> delete_entry(entry)
      {:ok, %Entry{}}

      iex> delete_entry(entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_entry(%Entry{} = entry) do
    Repo.delete(entry)
  end

  @doc """
  Searches entries and projects, returning a unified list of results.

  Each result is a map with `:type` (`:entry` or `:project`), `:id`, `:title`,
  and `:subtitle` keys for display in the search modal.
  """
  def search(query) do
    query = String.trim(query)
    if query == "", do: [], else: do_unified_search(query)
  end

  defp do_unified_search(query) do
    entry_results =
      do_search(query)
      |> Enum.map(fn entry ->
        %{type: :entry, id: entry.id, title: entry.title_text, subtitle: entry.subtitle_text}
      end)

    project_results =
      Glossary.Projects.search_projects(query)
      |> Enum.map(fn project ->
        %{type: :project, id: project.id, title: project.name, subtitle: nil}
      end)

    project_results ++ entry_results
  end

  def search_entries(query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search(query)
  end

  defp do_search(query) do
    fts_results = fts_search(query)

    if length(fts_results) < 3 do
      fts_ids = MapSet.new(fts_results, & &1.id)
      trigram_results = trigram_search(query)
      fts_results ++ Enum.reject(trigram_results, &MapSet.member?(fts_ids, &1.id))
    else
      fts_results
    end
  end

  defp fts_search(query) do
    from(e in Entry,
      where: fragment("search_tsv @@ websearch_to_tsquery('english', ?)", ^query),
      order_by: [
        desc: fragment("ts_rank_cd(search_tsv, websearch_to_tsquery('english', ?))", ^query),
        desc: e.updated_at
      ],
      limit: 20
    )
    |> Repo.all()
  end

  defp trigram_search(query) do
    from(e in Entry,
      where: fragment("similarity(title_text, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(title_text, ?)", ^query)],
      limit: 10
    )
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entry changes.

  ## Examples

      iex> change_entry(entry)
      %Ecto.Changeset{data: %Entry{}}

  """
  def change_entry(%Entry{} = entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
  end
end
