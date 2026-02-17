defmodule Glossary.Topics do
  @moduledoc """
  The Topics context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Accounts.Scope
  alias Glossary.Entries.Entry
  alias Glossary.Repo
  alias Glossary.Topics.Topic

  @doc """
  Returns the list of topics for the current scope, ordered by name.
  """
  def list_topics(%Scope{} = current_scope) do
    user_id = scope_user_id!(current_scope)

    Topic
    |> where([t], t.user_id == ^user_id)
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single topic with its entries preloaded from the current scope.

  Raises `Ecto.NoResultsError` if the Topic does not exist.
  """
  def get_topic!(%Scope{} = current_scope, id) do
    user_id = scope_user_id!(current_scope)

    Topic
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.preload(:entries)
  end

  @doc """
  Creates a topic in the current scope.
  """
  def create_topic(%Scope{} = current_scope, attrs) do
    %Topic{user_id: scope_user_id!(current_scope)}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic in the current scope.
  """
  def update_topic(%Scope{} = current_scope, %Topic{} = topic, attrs) do
    topic
    |> ensure_topic_owned!(current_scope)
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic in the current scope.
  """
  def delete_topic(%Scope{} = current_scope, %Topic{} = topic) do
    topic
    |> ensure_topic_owned!(current_scope)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.
  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  @doc """
  Adds an entry to a topic in the current scope.
  """
  def add_entry(%Scope{} = current_scope, %Topic{} = topic, %Entry{} = entry) do
    topic = ensure_topic_owned!(topic, current_scope)
    entry = ensure_entry_owned!(entry, current_scope)

    Repo.insert_all(
      "entry_topics",
      [%{topic_id: topic.id, entry_id: entry.id}],
      on_conflict: :nothing
    )

    {:ok, Repo.preload(topic, :entries, force: true)}
  end

  @doc """
  Removes an entry from a topic in the current scope.
  """
  def remove_entry(%Scope{} = current_scope, %Topic{} = topic, %Entry{} = entry) do
    topic = ensure_topic_owned!(topic, current_scope)
    entry = ensure_entry_owned!(entry, current_scope)

    from(et in "entry_topics",
      where: et.topic_id == ^topic.id and et.entry_id == ^entry.id
    )
    |> Repo.delete_all()

    {:ok, Repo.preload(topic, :entries, force: true)}
  end

  @doc """
  Returns entries that are NOT in the given topic, within the current scope.
  """
  def available_entries(%Scope{} = current_scope, %Topic{} = topic, query \\ "") do
    topic = ensure_topic_owned!(topic, current_scope)
    user_id = scope_user_id!(current_scope)

    existing_ids =
      from(et in "entry_topics",
        where: et.topic_id == ^topic.id,
        select: et.entry_id
      )

    base =
      from(e in Entry,
        where: e.user_id == ^user_id,
        where: e.id not in subquery(existing_ids),
        order_by: [desc: e.updated_at],
        limit: 20
      )

    query = String.trim(query)

    if query == "" do
      Repo.all(base)
    else
      from(e in base,
        where: fragment("similarity(title_text, ?) > 0.1", ^query),
        order_by: [desc: fragment("similarity(title_text, ?)", ^query)]
      )
      |> Repo.all()
    end
  end

  @doc """
  Searches topics by name using trigram similarity in the current scope.
  """
  def search_topics(%Scope{} = current_scope, query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search_topics(current_scope, query)
  end

  defp do_search_topics(%Scope{} = current_scope, query) do
    user_id = scope_user_id!(current_scope)

    from(t in Topic,
      where: t.user_id == ^user_id,
      where: fragment("similarity(name, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(name, ?)", ^query)],
      limit: 5
    )
    |> Repo.all()
  end

  defp scope_user_id!(%Scope{user: %{id: user_id}}) when not is_nil(user_id), do: user_id

  defp ensure_topic_owned!(%Topic{user_id: user_id} = topic, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: topic,
      else: raise(Ecto.NoResultsError, queryable: Topic)
  end

  defp ensure_entry_owned!(%Entry{user_id: user_id} = entry, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: entry,
      else: raise(Ecto.NoResultsError, queryable: Entry)
  end
end
