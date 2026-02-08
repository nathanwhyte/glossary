defmodule Glossary.TopicsTest do
  use Glossary.DataCase

  alias Glossary.Topics

  describe "topics" do
    alias Glossary.Topics.Topic

    import Glossary.TopicsFixtures
    import Glossary.EntriesFixtures

    test "list_topics/0 returns all topics ordered by name" do
      topic_b = topic_fixture(%{name: "Bravo"})
      topic_a = topic_fixture(%{name: "Alpha"})

      assert Topics.list_topics() == [topic_a, topic_b]
    end

    test "get_topic!/1 returns the topic with entries preloaded" do
      topic = topic_fixture()
      fetched = Topics.get_topic!(topic.id)
      assert fetched.id == topic.id
      assert fetched.entries == []
    end

    test "create_topic/1 with valid data creates a topic" do
      assert {:ok, %Topic{} = topic} = Topics.create_topic(%{name: "Biology"})
      assert topic.name == "Biology"
    end

    test "create_topic/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Topics.create_topic(%{name: nil})
    end

    test "update_topic/2 with valid data updates the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{} = updated} = Topics.update_topic(topic, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "update_topic/2 with invalid data returns error changeset" do
      topic = topic_fixture()
      assert {:error, %Ecto.Changeset{}} = Topics.update_topic(topic, %{name: nil})
      assert Topics.get_topic!(topic.id).name == topic.name
    end

    test "delete_topic/1 deletes the topic" do
      topic = topic_fixture()
      assert {:ok, %Topic{}} = Topics.delete_topic(topic)
      assert_raise Ecto.NoResultsError, fn -> Topics.get_topic!(topic.id) end
    end

    test "change_topic/1 returns a topic changeset" do
      topic = topic_fixture()
      assert %Ecto.Changeset{} = Topics.change_topic(topic)
    end
  end

  describe "entry association" do
    import Glossary.TopicsFixtures
    import Glossary.EntriesFixtures

    test "add_entry/2 adds an entry to a topic" do
      topic = topic_fixture()
      entry = entry_fixture()

      {:ok, updated_topic} = Topics.add_entry(topic, entry)
      assert length(updated_topic.entries) == 1
      assert hd(updated_topic.entries).id == entry.id
    end

    test "add_entry/2 is idempotent" do
      topic = topic_fixture()
      entry = entry_fixture()

      {:ok, _} = Topics.add_entry(topic, entry)
      {:ok, updated_topic} = Topics.add_entry(topic, entry)
      assert length(updated_topic.entries) == 1
    end

    test "remove_entry/2 removes an entry from a topic" do
      topic = topic_fixture()
      entry = entry_fixture()

      {:ok, topic} = Topics.add_entry(topic, entry)
      assert length(topic.entries) == 1

      {:ok, topic} = Topics.remove_entry(topic, entry)
      assert topic.entries == []
    end

    test "available_entries/2 returns entries not in the topic" do
      topic = topic_fixture()
      entry_in = entry_fixture(%{title_text: "In Topic"})
      entry_out = entry_fixture(%{title_text: "Not In Topic"})

      {:ok, _} = Topics.add_entry(topic, entry_in)

      available = Topics.available_entries(topic)
      available_ids = Enum.map(available, & &1.id)

      assert entry_out.id in available_ids
      refute entry_in.id in available_ids
    end

    test "deleting a topic does not delete its entries" do
      topic = topic_fixture()
      entry = entry_fixture()
      {:ok, _} = Topics.add_entry(topic, entry)

      {:ok, _} = Topics.delete_topic(topic)

      assert Glossary.Entries.get_entry!(entry.id).id == entry.id
    end

    test "deleting an entry removes it from topic associations" do
      topic = topic_fixture()
      entry = entry_fixture()
      {:ok, _} = Topics.add_entry(topic, entry)

      {:ok, _} = Glossary.Entries.delete_entry(entry)

      refreshed = Topics.get_topic!(topic.id)
      assert refreshed.entries == []
    end
  end
end
