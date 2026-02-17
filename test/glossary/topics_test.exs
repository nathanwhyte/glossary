defmodule Glossary.TopicsTest do
  use Glossary.DataCase

  alias Glossary.Topics

  describe "topics" do
    alias Glossary.Topics.Topic

    import Glossary.AccountsFixtures
    import Glossary.TopicsFixtures
    import Glossary.EntriesFixtures

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "list_topics/1 returns all topics ordered by name", %{current_scope: current_scope} do
      topic_b = topic_fixture(current_scope, %{name: "Bravo"})
      topic_a = topic_fixture(current_scope, %{name: "Alpha"})

      assert Topics.list_topics(current_scope) == [topic_a, topic_b]
    end

    test "get_topic!/2 returns the topic with entries preloaded", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      fetched = Topics.get_topic!(current_scope, topic.id)
      assert fetched.id == topic.id
      assert fetched.entries == []
    end

    test "create_topic/2 with valid data creates a topic", %{current_scope: current_scope} do
      assert {:ok, %Topic{} = topic} = Topics.create_topic(current_scope, %{name: "Biology"})
      assert topic.name == "Biology"
    end

    test "create_topic/2 with invalid data returns error changeset", %{
      current_scope: current_scope
    } do
      assert {:error, %Ecto.Changeset{}} = Topics.create_topic(current_scope, %{name: nil})
    end

    test "update_topic/3 with valid data updates the topic", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})

      assert {:ok, %Topic{} = updated} =
               Topics.update_topic(current_scope, topic, %{name: "Updated"})

      assert updated.name == "Updated"
    end

    test "update_topic/3 with invalid data returns error changeset", %{
      current_scope: current_scope
    } do
      topic = topic_fixture(current_scope, %{})
      assert {:error, %Ecto.Changeset{}} = Topics.update_topic(current_scope, topic, %{name: nil})
      assert Topics.get_topic!(current_scope, topic.id).name == topic.name
    end

    test "delete_topic/2 deletes the topic", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      assert {:ok, %Topic{}} = Topics.delete_topic(current_scope, topic)
      assert_raise Ecto.NoResultsError, fn -> Topics.get_topic!(current_scope, topic.id) end
    end

    test "change_topic/1 returns a topic changeset", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      assert %Ecto.Changeset{} = Topics.change_topic(topic)
    end
  end

  describe "entry association" do
    import Glossary.AccountsFixtures
    import Glossary.TopicsFixtures
    import Glossary.EntriesFixtures

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "add_entry/3 adds an entry to a topic", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})

      {:ok, updated_topic} = Topics.add_entry(current_scope, topic, entry)
      assert length(updated_topic.entries) == 1
      assert hd(updated_topic.entries).id == entry.id
    end

    test "add_entry/3 is idempotent", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})

      {:ok, _} = Topics.add_entry(current_scope, topic, entry)
      {:ok, updated_topic} = Topics.add_entry(current_scope, topic, entry)
      assert length(updated_topic.entries) == 1
    end

    test "remove_entry/3 removes an entry from a topic", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})

      {:ok, topic} = Topics.add_entry(current_scope, topic, entry)
      assert length(topic.entries) == 1

      {:ok, topic} = Topics.remove_entry(current_scope, topic, entry)
      assert topic.entries == []
    end

    test "available_entries/3 returns entries not in the topic", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      entry_in = entry_fixture(current_scope, %{title_text: "In Topic"})
      entry_out = entry_fixture(current_scope, %{title_text: "Not In Topic"})

      {:ok, _} = Topics.add_entry(current_scope, topic, entry_in)

      available = Topics.available_entries(current_scope, topic)
      available_ids = Enum.map(available, & &1.id)

      assert entry_out.id in available_ids
      refute entry_in.id in available_ids
    end

    test "deleting a topic does not delete its entries", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})
      {:ok, _} = Topics.add_entry(current_scope, topic, entry)

      {:ok, _} = Topics.delete_topic(current_scope, topic)

      assert Glossary.Entries.get_entry!(current_scope, entry.id).id == entry.id
    end

    test "deleting an entry removes it from topic associations", %{current_scope: current_scope} do
      topic = topic_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})
      {:ok, _} = Topics.add_entry(current_scope, topic, entry)

      {:ok, _} = Glossary.Entries.delete_entry(current_scope, entry)

      refreshed = Topics.get_topic!(current_scope, topic.id)
      assert refreshed.entries == []
    end
  end
end
