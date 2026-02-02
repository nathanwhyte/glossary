defmodule Glossary.EntriesTest do
  use Glossary.DataCase

  alias Glossary.Entries

  describe "entries" do
    alias Glossary.Entries.Entry

    import Glossary.EntriesFixtures

    @invalid_attrs %{title: nil, body: nil, subtitle: nil, body_text: nil, title_text: nil}

    test "list_entries/0 returns all entries" do
      entry = entry_fixture()
      assert Entries.list_entries() == [entry]
    end

    test "get_entry!/1 returns the entry with given id" do
      entry = entry_fixture()
      assert Entries.get_entry!(entry.id) == entry
    end

    test "create_entry/1 with valid data creates a entry" do
      valid_attrs = %{
        title: "some title",
        title_text: "some title",
        body: "some body",
        body_text: "some body",
        subtitle: "some subtitle"
      }

      assert {:ok, %Entry{} = entry} = Entries.create_entry(valid_attrs)
      assert entry.title == "some title"
      assert entry.body == "some body"
      assert entry.body_text == "some body"
      assert entry.subtitle == "some subtitle"
      assert entry.title_text == "some title"
    end

    test "create_entry/1 with nil data creates a draft entry" do
      assert {:ok, %Entry{}} = Entries.create_entry(@invalid_attrs)
    end

    test "update_entry/2 with valid data updates the entry" do
      entry = entry_fixture()

      update_attrs = %{
        title: "some updated title",
        title_text: "some updated title",
        body: "some updated body",
        body_text: "some updated body",
        subtitle: "some updated subtitle"
      }

      assert {:ok, %Entry{} = entry} = Entries.update_entry(entry, update_attrs)
      assert entry.title == "some updated title"
      assert entry.body == "some updated body"
      assert entry.body_text == "some updated body"
      assert entry.subtitle == "some updated subtitle"
      assert entry.title_text == "some updated title"
    end

    test "update_entry/2 with nil data clears fields" do
      entry = entry_fixture()
      assert {:ok, %Entry{}} = Entries.update_entry(entry, @invalid_attrs)
    end

    test "delete_entry/1 deletes the entry" do
      entry = entry_fixture()
      assert {:ok, %Entry{}} = Entries.delete_entry(entry)
      assert_raise Ecto.NoResultsError, fn -> Entries.get_entry!(entry.id) end
    end

    test "change_entry/1 returns a entry changeset" do
      entry = entry_fixture()
      assert %Ecto.Changeset{} = Entries.change_entry(entry)
    end
  end
end
