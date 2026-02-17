defmodule Glossary.Entries do
  @moduledoc """
  The Entries context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Accounts.Scope
  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @doc """
  Returns the list of entries for the current scope.
  """
  def list_entries(%Scope{} = current_scope) do
    user_id = scope_user_id!(current_scope)

    Repo.all(
      Entry
      |> where([e], e.user_id == ^user_id)
      |> order_by(desc: :inserted_at)
      |> preload([:projects, :topics])
    )
  end

  @doc """
  Returns the list of the X most recent entries for the current scope.
  """
  def recent_entries(%Scope{} = current_scope, count \\ 7) do
    user_id = scope_user_id!(current_scope)

    Repo.all(
      Entry
      |> where([e], e.user_id == ^user_id)
      |> order_by(desc: :inserted_at)
      |> limit(^count)
      |> preload([:projects, :topics])
    )
  end

  @doc """
  Gets a single entry from the current scope.

  Raises `Ecto.NoResultsError` if the Entry does not exist.
  """
  def get_entry!(%Scope{} = current_scope, id) do
    user_id = scope_user_id!(current_scope)

    Repo.get_by!(Entry, id: id, user_id: user_id)
  end

  @doc """
  Creates an entry in the current scope.
  """
  def create_entry(%Scope{} = current_scope, attrs) do
    %Entry{user_id: scope_user_id!(current_scope)}
    |> Entry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an entry in the current scope.
  """
  def update_entry(%Scope{} = current_scope, %Entry{} = entry, attrs) do
    entry
    |> ensure_entry_owned!(current_scope)
    |> Entry.changeset(attrs)
    |> Repo.update()
  end

  def upsert_entry(%Scope{} = current_scope, %Entry{id: nil}, attrs) do
    create_entry(current_scope, attrs)
  end

  def upsert_entry(%Scope{} = current_scope, %Entry{} = entry, attrs) do
    update_entry(current_scope, entry, attrs)
  end

  @doc """
  Deletes an entry in the current scope.
  """
  def delete_entry(%Scope{} = current_scope, %Entry{} = entry) do
    entry
    |> ensure_entry_owned!(current_scope)
    |> Repo.delete()
  end

  @doc """
  Searches entries, projects, and topics in the current scope.
  """
  def search(current_scope, query, mode \\ :all)

  def search(%Scope{} = current_scope, query, mode) do
    query = String.trim(query)
    if query == "", do: [], else: do_filtered_search(current_scope, query, mode)
  end

  defp do_filtered_search(current_scope, query, :entries) do
    do_search(current_scope, query)
    |> Enum.map(&entry_to_result/1)
  end

  defp do_filtered_search(current_scope, query, :projects) do
    Glossary.Projects.search_projects(current_scope, query)
    |> Enum.map(&project_to_result/1)
  end

  defp do_filtered_search(current_scope, query, :topics) do
    Glossary.Topics.search_topics(current_scope, query)
    |> Enum.map(&topic_to_result/1)
  end

  defp do_filtered_search(current_scope, query, :all) do
    entries = do_search(current_scope, query) |> Enum.map(&entry_to_result/1)

    projects =
      Glossary.Projects.search_projects(current_scope, query) |> Enum.map(&project_to_result/1)

    topics = Glossary.Topics.search_topics(current_scope, query) |> Enum.map(&topic_to_result/1)

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

  def search_entries(%Scope{} = current_scope, query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search(current_scope, query)
  end

  defp do_search(%Scope{} = current_scope, query) do
    fts_results = fts_search(current_scope, query)

    if length(fts_results) < 3 do
      fts_ids = MapSet.new(fts_results, & &1.id)
      trigram_results = trigram_search(current_scope, query)
      fts_results ++ Enum.reject(trigram_results, &MapSet.member?(fts_ids, &1.id))
    else
      fts_results
    end
  end

  defp fts_search(%Scope{} = current_scope, query) do
    user_id = scope_user_id!(current_scope)

    from(e in Entry,
      where: e.user_id == ^user_id,
      where: fragment("search_tsv @@ websearch_to_tsquery('english', ?)", ^query),
      order_by: [
        desc: fragment("ts_rank_cd(search_tsv, websearch_to_tsquery('english', ?))", ^query),
        desc: e.updated_at
      ],
      limit: 20
    )
    |> Repo.all()
  end

  defp trigram_search(%Scope{} = current_scope, query) do
    user_id = scope_user_id!(current_scope)

    from(e in Entry,
      where: e.user_id == ^user_id,
      where: fragment("similarity(title_text, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(title_text, ?)", ^query)],
      limit: 10
    )
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking entry changes.
  """
  def change_entry(%Entry{} = entry, attrs \\ %{}) do
    Entry.changeset(entry, attrs)
  end

  @doc """
  Returns projects that the given entry is NOT in, within the current scope.
  """
  def available_projects(%Scope{} = current_scope, %Entry{} = entry, query \\ "") do
    alias Glossary.Projects.Project

    user_id = scope_user_id!(current_scope)
    _ = ensure_entry_owned!(entry, current_scope)

    existing_ids =
      from(pe in "project_entries",
        where: pe.entry_id == ^entry.id,
        select: pe.project_id
      )

    base =
      from(p in Project,
        where: p.user_id == ^user_id,
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
  Returns topics that the given entry is NOT in, within the current scope.
  """
  def available_topics(%Scope{} = current_scope, %Entry{} = entry, query \\ "") do
    alias Glossary.Topics.Topic

    user_id = scope_user_id!(current_scope)
    _ = ensure_entry_owned!(entry, current_scope)

    existing_ids =
      from(et in "entry_topics",
        where: et.entry_id == ^entry.id,
        select: et.topic_id
      )

    base =
      from(t in Topic,
        where: t.user_id == ^user_id,
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

  defp scope_user_id!(%Scope{user: %{id: user_id}}) when not is_nil(user_id), do: user_id

  defp ensure_entry_owned!(%Entry{user_id: user_id} = entry, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: entry,
      else: raise(Ecto.NoResultsError, queryable: Entry)
  end
end
