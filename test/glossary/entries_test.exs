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

  describe "Entry.changeset/2" do
    test "validates with all fields" do
      attrs = %{
        title: "Test Title",
        description: "Test Description",
        body: "Test Body",
        status: :Published
      }

      changeset = Entry.changeset(%Entry{}, attrs)
      assert changeset.valid?
    end

    test "validates status is present when explicitly set to nil" do
      # Schema has default, so empty attrs makes valid changeset
      # But we can test that nil is rejected
      changeset = Entry.changeset(%Entry{}, %{status: nil})
      refute changeset.valid?
      assert errors_on(changeset).status != nil
    end

    test "validates status enum values" do
      valid_statuses = [:Draft, :Published, :Archived]

      for status <- valid_statuses do
        changeset = Entry.changeset(%Entry{}, %{status: status})
        assert changeset.valid?
      end
    end

    test "rejects invalid status values" do
      changeset = Entry.changeset(%Entry{}, %{status: :invalid})
      refute changeset.valid?
    end

    test "casts string fields correctly" do
      attrs = %{
        title: "Title",
        description: "Description",
        body: "Body",
        status: :Draft
      }

      changeset = Entry.changeset(%Entry{}, attrs)
      assert changeset.changes.title == "Title"
      assert changeset.changes.description == "Description"
      assert changeset.changes.body == "Body"
    end

    test "uses default values when attrs empty" do
      changeset = Entry.changeset(%Entry{}, %{status: :Draft})
      assert Map.get(changeset.changes, :title) == nil || Map.get(changeset.changes, :title) == ""
    end
  end
end
