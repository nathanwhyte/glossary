defmodule Glossary.Topics do
  @moduledoc """
  The Topics context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Repo

  alias Glossary.Topics.Topic
  alias Glossary.Entries.Entry

  @doc """
  Returns the list of topics, ordered by name.
  """
  def list_topics do
    Topic
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single topic with its entries preloaded.

  Raises `Ecto.NoResultsError` if the Topic does not exist.
  """
  def get_topic!(id) do
    Topic
    |> Repo.get!(id)
    |> Repo.preload(:entries)
  end

  @doc """
  Creates a topic.
  """
  def create_topic(attrs) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic.
  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.
  """
  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.
  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end

  @doc """
  Adds an entry to a topic. Idempotent (ON CONFLICT DO NOTHING).
  """
  def add_entry(%Topic{} = topic, %Entry{} = entry) do
    Repo.insert_all(
      "entry_topics",
      [%{topic_id: topic.id, entry_id: entry.id}],
      on_conflict: :nothing
    )

    {:ok, Repo.preload(topic, :entries, force: true)}
  end

  @doc """
  Removes an entry from a topic.
  """
  def remove_entry(%Topic{} = topic, %Entry{} = entry) do
    from(et in "entry_topics",
      where: et.topic_id == ^topic.id and et.entry_id == ^entry.id
    )
    |> Repo.delete_all()

    {:ok, Repo.preload(topic, :entries, force: true)}
  end

  @doc """
  Returns entries that are NOT in the given topic, optionally filtered by a
  search query on `title_text`. Used by the entry assignment UI.
  """
  def available_entries(%Topic{} = topic, query \\ "") do
    existing_ids =
      from(et in "entry_topics",
        where: et.topic_id == ^topic.id,
        select: et.entry_id
      )

    base =
      from(e in Entry,
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
  Searches topics by name using trigram similarity.
  """
  def search_topics(query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search_topics(query)
  end

  defp do_search_topics(query) do
    from(t in Topic,
      where: fragment("similarity(name, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(name, ?)", ^query)],
      limit: 5
    )
    |> Repo.all()
  end
end
