defmodule Glossary.Entries.ProjectTest do
  use Glossary.DataCase

  import Glossary.EntriesFixtures

  describe "project_fixture/1" do
    test "creates a project with default attributes" do
      project = project_fixture()
      assert project.name == "Test Project"
      assert project.description == "Test Project Description"
      assert project.id != nil
    end

    test "creates a project with custom attributes" do
      project = project_fixture(%{name: "Custom Project", description: "Custom Description"})
      assert project.name == "Custom Project"
      assert project.description == "Custom Description"
    end
  end

  describe "has_many :entries" do
    test "project can have multiple entries" do
      project = project_fixture()
      entry1 = entry_fixture()
      entry2 = entry_fixture()

      entry1
      |> Repo.preload(:project)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:project, project)
      |> Repo.update!()

      entry2
      |> Repo.preload(:project)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:project, project)
      |> Repo.update!()

      project = Repo.preload(project, :entries)
      assert length(project.entries) == 2
      entry_ids = Enum.map(project.entries, & &1.id)
      assert entry1.id in entry_ids
      assert entry2.id in entry_ids
    end
  end
end
