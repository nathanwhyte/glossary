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
    Repo.all(Entry |> order_by(desc: :inserted_at) |> preload([:projects, :topics]))
  end

  @doc """
  Returns the list of the X most recent entries.

  ## Examples

      iex> list_entries(3)
      [%Entry{}, %Entry{}, %Entry{},]

  """
  def recent_entries(count \\ 7) do
    Repo.all(
      Entry
      |> order_by(desc: :inserted_at)
      |> limit(^count)
      |> preload([:projects, :topics])
    )
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
  Searches entries, projects, and topics, returning a unified list of results.

  Each result is a map with `:type` (`:entry`, `:project`, or `:topic`), `:id`,
  `:title`, and `:subtitle` keys for display in the search modal.

  Accepts an optional `mode` to restrict which types are searched:

    * `:all` (default) - searches entries, projects, and topics
    * `:entries` - searches entries only
    * `:projects` - searches projects only
    * `:topics` - searches topics only
  """
  def search(query, mode \\ :all)

  def search(query, mode) do
    query = String.trim(query)
    if query == "", do: [], else: do_filtered_search(query, mode)
  end

  defp do_filtered_search(query, :entries) do
    do_search(query)
    |> Enum.map(&entry_to_result/1)
  end

  defp do_filtered_search(query, :projects) do
    Glossary.Projects.search_projects(query)
    |> Enum.map(&project_to_result/1)
  end

  defp do_filtered_search(query, :topics) do
    Glossary.Topics.search_topics(query)
    |> Enum.map(&topic_to_result/1)
  end

  defp do_filtered_search(query, :all) do
    entries = do_search(query) |> Enum.map(&entry_to_result/1)
    projects = Glossary.Projects.search_projects(query) |> Enum.map(&project_to_result/1)
    topics = Glossary.Topics.search_topics(query) |> Enum.map(&topic_to_result/1)

    projects ++ topics ++ entries
  end

  defp entry_to_result(entry) do
    %{type: :entry, id: entry.id, title: entry.title_text, subtitle: entry.subtitle_text}
  end

  defp project_to_result(project) do
    %{type: :project, id: project.id, title: project.name, subtitle: nil}
  end

  defp topic_to_result(topic) do
    %{type: :topic, id: topic.id, title: topic.name, subtitle: nil}
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

  @doc """
  Returns projects that the given entry is NOT in, optionally filtered by name.
  Used by the command palette picker.
  """
  def available_projects(%Entry{} = entry, query \\ "") do
    alias Glossary.Projects.Project

    existing_ids =
      from(pe in "project_entries",
        where: pe.entry_id == ^entry.id,
        select: pe.project_id
      )

    base =
      from(p in Project,
        where: p.id not in subquery(existing_ids),
        order_by: [desc: p.updated_at],
        limit: 20
      )

    query = String.trim(query)

    if query == "" do
      Repo.all(base)
    else
      Repo.all(from(p in base, where: ilike(p.name, ^"%#{query}%")))
    end
  end

  @doc """
  Returns topics that the given entry is NOT in, optionally filtered by name.
  Used by the command palette picker.
  """
  def available_topics(%Entry{} = entry, query \\ "") do
    alias Glossary.Topics.Topic

    existing_ids =
      from(et in "entry_topics",
        where: et.entry_id == ^entry.id,
        select: et.topic_id
      )

    base =
      from(t in Topic,
        where: t.id not in subquery(existing_ids),
        order_by: [desc: t.updated_at],
        limit: 20
      )

    query = String.trim(query)

    if query == "" do
      Repo.all(base)
    else
      Repo.all(from(t in base, where: ilike(t.name, ^"%#{query}%")))
    end
  end
end
