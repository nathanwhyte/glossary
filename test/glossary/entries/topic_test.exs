defmodule Glossary.Entries.TopicTest do
  use Glossary.DataCase

  alias Glossary.Entries.Topic

  import Glossary.EntriesFixtures

  describe "topic_fixture/1" do
    test "creates a topic with default attributes" do
      topic = topic_fixture()
      assert topic.name == "Test Topic"
      assert topic.description == "Test Topic Description"
      assert topic.id != nil
    end

    test "creates a topic with custom attributes" do
      topic = topic_fixture(%{name: "Custom Topic", description: "Custom Description"})
      assert topic.name == "Custom Topic"
      assert topic.description == "Custom Description"
    end
  end

  describe "many_to_many :entries" do
    test "topic can be associated with entries" do
      topic = topic_fixture()
      entry1 = entry_fixture()
      entry2 = entry_fixture()

      topic
      |> Repo.preload(:entries)
      |> Topic.changeset(%{})
      |> Ecto.Changeset.put_assoc(:entries, [entry1, entry2])
      |> Repo.update!()

      topic = Repo.preload(topic, :entries)
      assert length(topic.entries) == 2
      assert entry1 in topic.entries
      assert entry2 in topic.entries
    end
  end
end
