defmodule Glossary.Entries.TagTest do
  use Glossary.DataCase

  alias Glossary.Entries.Tag

  import Glossary.EntriesFixtures

  describe "tag_fixture/1" do
    test "creates a tag with default attributes" do
      tag = tag_fixture()
      assert tag.name == "test-tag"
      assert tag.id != nil
    end

    test "creates a tag with custom attributes" do
      tag = tag_fixture(%{name: "custom-tag"})
      assert tag.name == "custom-tag"
    end
  end

  describe "many_to_many :entries" do
    test "tag can be associated with entries" do
      tag = tag_fixture()
      entry1 = entry_fixture()
      entry2 = entry_fixture()

      tag
      |> Repo.preload(:entries)
      |> Tag.changeset(%{})
      |> Ecto.Changeset.put_assoc(:entries, [entry1, entry2])
      |> Repo.update!()

      tag = Repo.preload(tag, :entries)
      assert length(tag.entries) == 2
      assert entry1 in tag.entries
      assert entry2 in tag.entries
    end
  end
end
