defmodule Glossary.EntriesTest do
  use Glossary.DataCase

  alias Glossary.Entries

  describe "entries" do
    alias Glossary.Entries.Entry

    import Glossary.AccountsFixtures
    import Glossary.EntriesFixtures

    @invalid_attrs %{title: nil, body: nil, subtitle: nil, body_text: nil, title_text: nil}

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "list_entries/1 returns all entries", %{current_scope: current_scope} do
      entry = entry_fixture(current_scope, %{})
      assert [%Entry{id: id}] = Entries.list_entries(current_scope)
      assert id == entry.id
    end

    test "get_entry!/2 returns the entry with given id", %{current_scope: current_scope} do
      entry = entry_fixture(current_scope, %{})
      assert Entries.get_entry!(current_scope, entry.id) == entry
    end

    test "create_entry/2 with valid data creates a entry", %{current_scope: current_scope} do
      valid_attrs = %{
        title: "some title",
        title_text: "some title",
        body: "some body",
        body_text: "some body",
        subtitle: "some subtitle"
      }

      assert {:ok, %Entry{} = entry} = Entries.create_entry(current_scope, valid_attrs)
      assert entry.title == "some title"
      assert entry.body == "some body"
      assert entry.body_text == "some body"
      assert entry.subtitle == "some subtitle"
      assert entry.title_text == "some title"
    end

    test "create_entry/2 with nil data creates a draft entry", %{current_scope: current_scope} do
      assert {:ok, %Entry{}} = Entries.create_entry(current_scope, @invalid_attrs)
    end

    test "update_entry/3 with valid data updates the entry", %{current_scope: current_scope} do
      entry = entry_fixture(current_scope, %{})

      update_attrs = %{
        title: "some updated title",
        title_text: "some updated title",
        body: "some updated body",
        body_text: "some updated body",
        subtitle: "some updated subtitle"
      }

      assert {:ok, %Entry{} = entry} = Entries.update_entry(current_scope, entry, update_attrs)
      assert entry.title == "some updated title"
      assert entry.body == "some updated body"
      assert entry.body_text == "some updated body"
      assert entry.subtitle == "some updated subtitle"
      assert entry.title_text == "some updated title"
    end

    test "update_entry/3 with nil data clears fields", %{current_scope: current_scope} do
      entry = entry_fixture(current_scope, %{})
      assert {:ok, %Entry{}} = Entries.update_entry(current_scope, entry, @invalid_attrs)
    end

    test "delete_entry/2 deletes the entry", %{current_scope: current_scope} do
      entry = entry_fixture(current_scope, %{})
      assert {:ok, %Entry{}} = Entries.delete_entry(current_scope, entry)
      assert_raise Ecto.NoResultsError, fn -> Entries.get_entry!(current_scope, entry.id) end
    end

    test "change_entry/1 returns a entry changeset", %{current_scope: current_scope} do
      entry = entry_fixture(current_scope, %{})
      assert %Ecto.Changeset{} = Entries.change_entry(entry)
    end
  end

  describe "search_entries/1" do
    import Glossary.AccountsFixtures
    import Glossary.EntriesFixtures

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "returns entries matching the title", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})
      entry_fixture(current_scope, %{title_text: "Tidal Locking"})

      results = Entries.search_entries(current_scope, "sourdough")
      assert length(results) == 1
      assert hd(results).title_text == "Sourdough Fermentation"
    end

    test "returns empty list for blank query", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})

      assert Entries.search_entries(current_scope, "") == []
      assert Entries.search_entries(current_scope, "   ") == []
    end

    test "returns empty list when nothing matches", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})

      assert Entries.search_entries(current_scope, "astrophysics") == []
    end

    test "ranks closer matches higher", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Tidal Locking"})
      entry_fixture(current_scope, %{title_text: "Tidal Waves and Erosion"})

      results = Entries.search_entries(current_scope, "tidal locking")
      assert length(results) == 2
      assert hd(results).title_text == "Tidal Locking"
    end
  end

  describe "search/2 with mode" do
    import Glossary.AccountsFixtures
    import Glossary.EntriesFixtures
    import Glossary.ProjectsFixtures
    import Glossary.TopicsFixtures

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "mode :all returns entries, projects, and topics", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})
      project_fixture(current_scope, %{name: "Sourdough Project"})
      topic_fixture(current_scope, %{name: "Sourdough Topic"})

      results = Entries.search(current_scope, "sourdough", :all)
      types = Enum.map(results, & &1.type) |> Enum.uniq() |> Enum.sort()

      assert :entry in types
      assert :project in types
      assert :topic in types
    end

    test "mode :entries returns only entries", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})
      project_fixture(current_scope, %{name: "Sourdough Project"})
      topic_fixture(current_scope, %{name: "Sourdough Topic"})

      results = Entries.search(current_scope, "sourdough", :entries)
      assert Enum.all?(results, &(&1.type == :entry))
      assert results != []
    end

    test "mode :projects returns only projects", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})
      project_fixture(current_scope, %{name: "Sourdough Project"})

      results = Entries.search(current_scope, "sourdough", :projects)
      assert Enum.all?(results, &(&1.type == :project))
      assert length(results) == 1
    end

    test "mode :topics returns only topics", %{current_scope: current_scope} do
      entry_fixture(current_scope, %{title_text: "Sourdough Fermentation"})
      topic_fixture(current_scope, %{name: "Sourdough Topic"})

      results = Entries.search(current_scope, "sourdough", :topics)
      assert Enum.all?(results, &(&1.type == :topic))
      assert length(results) == 1
    end

    test "returns empty list for blank query in any mode", %{current_scope: current_scope} do
      assert Entries.search(current_scope, "", :entries) == []
      assert Entries.search(current_scope, "  ", :projects) == []
      assert Entries.search(current_scope, "", :topics) == []
      assert Entries.search(current_scope, "", :all) == []
    end
  end
end
