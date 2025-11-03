defmodule Glossary.EntriesFixtures do
  @moduledoc """
  Test fixtures for Glossary.Entries context.
  """

  alias Glossary.Entries
  alias Glossary.Entries.{Project, Tag, Topic}
  alias Glossary.Repo

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
    entry_fixture(Map.merge(attrs, %{status: :Published}))
  end

  @doc """
  Generate a draft entry.
  """
  def draft_entry_fixture(attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{status: :Draft}))
  end

  @doc """
  Generate an archived entry.
  """
  def archived_entry_fixture(attrs \\ %{}) do
    entry_fixture(Map.merge(attrs, %{status: :Archived}))
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

  @doc """
  Generate a project with default or custom attributes.
  """
  def project_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Test Project",
        description: "Test Project Description"
      })

    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Generate a tag with default or custom attributes.
  """
  def tag_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "test-tag"
      })

    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Generate a topic with default or custom attributes.
  """
  def topic_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "Test Topic",
        description: "Test Topic Description"
      })

    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Generate an entry associated with a project.
  """
  def entry_with_project_fixture(project_attrs \\ %{}, entry_attrs \\ %{}) do
    project = project_fixture(project_attrs)
    {:ok, entry} = Entries.create_entry(entry_attrs)

    entry
    |> Repo.preload([:project])
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:project, project)
    |> Repo.update!()
    |> Repo.preload([:project])
  end

  @doc """
  Generate an entry associated with tags.
  """
  def entry_with_tags_fixture(tags \\ [], entry_attrs \\ %{}) do
    tags = if Enum.empty?(tags), do: [tag_fixture()], else: tags

    {:ok, entry} =
      entry_attrs
      |> Enum.into(%{
        title: "Test Entry",
        description: "Test Description",
        body: "Test Body",
        status: :Draft
      })
      |> Entries.create_entry()

    entry
    |> Repo.preload(:tags)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Repo.update!()
    |> Repo.preload(:tags)
  end

  @doc """
  Generate an entry associated with topics.
  """
  def entry_with_topics_fixture(topics \\ [], entry_attrs \\ %{}) do
    topics = if Enum.empty?(topics), do: [topic_fixture()], else: topics

    {:ok, entry} =
      entry_attrs
      |> Enum.into(%{
        title: "Test Entry",
        description: "Test Description",
        body: "Test Body",
        status: :Draft
      })
      |> Entries.create_entry()

    entry
    |> Repo.preload(:topics)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:topics, topics)
    |> Repo.update!()
    |> Repo.preload(:topics)
  end

  @doc """
  Generate an entry with all relationships (project, tags, topics).
  """
  def entry_with_all_relationships_fixture(
        project_attrs \\ %{},
        tags \\ [],
        topics \\ [],
        entry_attrs \\ %{}
      ) do
    project = project_fixture(project_attrs)

    tags =
      if Enum.empty?(tags), do: [tag_fixture(), tag_fixture(%{name: "another-tag"})], else: tags

    topics =
      if Enum.empty?(topics),
        do: [topic_fixture(), topic_fixture(%{name: "Another Topic"})],
        else: topics

    {:ok, entry} = Entries.create_entry(entry_attrs)

    entry
    |> Repo.preload([:project, :tags, :topics])
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:project, project)
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> Ecto.Changeset.put_assoc(:topics, topics)
    |> Repo.update!()
    |> Repo.preload([:project, :tags, :topics])
  end
end
