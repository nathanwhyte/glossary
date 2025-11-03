defmodule Glossary.EntriesTest do
  use Glossary.DataCase

  alias Glossary.Entries
  alias Glossary.Entries.Entry

  import Glossary.EntriesFixtures

  describe "get_entry!/1" do
    test "returns the entry with given id" do
      entry = entry_fixture()
      assert Entries.get_entry!(entry.id).id == entry.id
    end

    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Entries.get_entry!("00000000-0000-0000-0000-000000000000")
      end
    end
  end

  describe "get_entry/1" do
    test "returns the entry with given id" do
      entry = entry_fixture()
      assert Entries.get_entry(entry.id).id == entry.id
    end

    test "returns nil if id is invalid" do
      assert Entries.get_entry("00000000-0000-0000-0000-000000000000") == nil
    end
  end

  describe "create_entry/1" do
    test "creates an entry with valid attributes" do
      valid_attrs = %{title: "Test", description: "Description", body: "Body", status: :Draft}

      assert {:ok, %Entry{} = entry} = Entries.create_entry(valid_attrs)
      assert entry.title == "Test"
      assert entry.description == "Description"
      assert entry.body == "Body"
      assert entry.status == :Draft
    end

    test "creates an entry with default values" do
      assert {:ok, %Entry{} = entry} = Entries.create_entry()
      assert entry.title == ""
      assert entry.description == ""
      assert entry.body == ""
      assert entry.status == :Draft
    end

    test "creates entry with minimal required attrs" do
      assert {:ok, %Entry{} = entry} = Entries.create_entry(%{status: :Draft})
      assert entry.status == :Draft
      assert entry.title == ""
    end

    test "fails to create entry with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = Entries.create_entry(%{status: :invalid})
    end
  end

  describe "update_entry/2" do
    test "updates the entry with valid attributes" do
      entry = entry_fixture()
      update_attrs = %{title: "Updated Title", description: "Updated Desc"}

      assert {:ok, %Entry{} = entry} = Entries.update_entry(entry, update_attrs)
      assert entry.title == "Updated Title"
      assert entry.description == "Updated Desc"
    end

    test "performs partial updates" do
      entry = entry_fixture()
      assert {:ok, updated} = Entries.update_entry(entry, %{title: "New Title"})
      assert updated.title == "New Title"
      assert updated.description == entry.description
    end

    test "allows status transitions" do
      entry = entry_fixture(%{status: :Draft})
      assert {:ok, updated} = Entries.update_entry(entry, %{status: :Published})
      assert updated.status == :Published
    end

    test "fails to update entry with invalid attributes" do
      entry = entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Entries.update_entry(entry, %{status: :invalid})
    end
  end

  describe "delete_entry/1" do
    test "deletes the entry" do
      entry = entry_fixture()
      assert {:ok, %Entry{}} = Entries.delete_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> Entries.get_entry!(entry.id) end
    end
  end

  describe "list_entries/0" do
    test "returns empty list when no entries exist" do
      assert Entries.list_entries() == []
    end

    test "returns all entries" do
      entry1 = entry_fixture()
      entry2 = entry_fixture()
      entries = Entries.list_entries()
      assert length(entries) == 2
      assert entry1 in entries
      assert entry2 in entries
    end
  end

  describe "list_recent_entries/1" do
    test "returns empty list when no entries exist" do
      assert Entries.list_recent_entries() == []
    end

    test "returns entries ordered by updated_at descending" do
      _entry1 = entry_fixture(%{title: "First Entry"})
      entry2 = entry_fixture(%{title: "Second Entry"})

      # Update entry2 to ensure it has a more recent updated_at
      {:ok, updated_entry2} = Entries.update_entry(entry2, %{title: "Second Entry Updated"})

      entries = Entries.list_recent_entries()
      assert length(entries) == 2
      # Verify entries are returned and one of them is the updated one
      entry_ids = Enum.map(entries, & &1.id)
      assert updated_entry2.id in entry_ids
      # Verify ordering: all entries should have updated_at in descending order
      timestamps = Enum.map(entries, & &1.updated_at)
      assert timestamps == Enum.sort(timestamps, {:desc, DateTime})
    end

    test "limits results to specified count" do
      entry_fixture(%{title: "Entry 1"})
      entry_fixture(%{title: "Entry 2"})
      entry_fixture(%{title: "Entry 3"})
      entry_fixture(%{title: "Entry 4"})
      entry_fixture(%{title: "Entry 5"})
      entry_fixture(%{title: "Entry 6"})

      entries = Entries.list_recent_entries(5)
      assert length(entries) == 5
    end

    test "preloads project, tags, and topics" do
      _entry = entry_with_all_relationships_fixture()

      entries = Entries.list_recent_entries(1)
      assert length(entries) == 1

      loaded_entry = hd(entries)
      assert Ecto.assoc_loaded?(loaded_entry.project)
      assert loaded_entry.project != nil
      assert Ecto.assoc_loaded?(loaded_entry.tags)
      assert length(loaded_entry.tags) > 0
      assert Ecto.assoc_loaded?(loaded_entry.topics)
      assert length(loaded_entry.topics) > 0
    end

    test "handles entries without relationships" do
      entry_fixture()

      entries = Entries.list_recent_entries(1)
      assert length(entries) == 1

      loaded_entry = hd(entries)
      assert Ecto.assoc_loaded?(loaded_entry.project)
      assert loaded_entry.project == nil
      assert Ecto.assoc_loaded?(loaded_entry.tags)
      assert loaded_entry.tags == []
      assert Ecto.assoc_loaded?(loaded_entry.topics)
      assert loaded_entry.topics == []
    end
  end

  describe "Entry relationships" do
    test "entry can belong to a project" do
      entry = entry_with_project_fixture()

      assert entry.project != nil
      assert entry.project.name == "Test Project"
    end

    test "entry can have many tags" do
      tag1 = tag_fixture(%{name: "tag1"})
      tag2 = tag_fixture(%{name: "tag2"})
      entry = entry_with_tags_fixture([tag1, tag2])

      assert length(entry.tags) == 2
      assert tag1 in entry.tags
      assert tag2 in entry.tags
    end

    test "entry can have many topics" do
      topic1 = topic_fixture(%{name: "Topic 1"})
      topic2 = topic_fixture(%{name: "Topic 2"})
      entry = entry_with_topics_fixture([topic1, topic2])

      assert length(entry.topics) == 2
      assert topic1 in entry.topics
      assert topic2 in entry.topics
    end

    test "entry can have all relationships" do
      entry = entry_with_all_relationships_fixture()

      assert entry.project != nil
      assert length(entry.tags) > 0
      assert length(entry.topics) > 0
    end

    test "entry can be updated with new tags" do
      entry = entry_fixture()
      tag1 = tag_fixture(%{name: "tag1"})
      tag2 = tag_fixture(%{name: "tag2"})

      updated_entry =
        entry
        |> Repo.preload(:tags)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:tags, [tag1, tag2])
        |> Repo.update!()

      entry = Repo.preload(updated_entry, :tags)
      assert length(entry.tags) == 2
      assert tag1 in entry.tags
      assert tag2 in entry.tags
    end

    test "entry can be updated with new topics" do
      entry = entry_fixture()
      topic1 = topic_fixture(%{name: "Topic 1"})
      topic2 = topic_fixture(%{name: "Topic 2"})

      updated_entry =
        entry
        |> Repo.preload(:topics)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:topics, [topic1, topic2])
        |> Repo.update!()

      entry = Repo.preload(updated_entry, :topics)
      assert length(entry.topics) == 2
      assert topic1 in entry.topics
      assert topic2 in entry.topics
    end

    test "entry can be updated with a project" do
      entry = entry_fixture()
      project = project_fixture(%{name: "New Project"})

      updated_entry =
        entry
        |> Repo.preload(:project)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:project, project)
        |> Repo.update!()

      entry = Repo.preload(updated_entry, :project)
      assert entry.project != nil
      assert entry.project.name == "New Project"
    end
  end
end
