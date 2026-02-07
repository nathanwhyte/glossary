defmodule Glossary.ProjectsTest do
  use Glossary.DataCase

  alias Glossary.Projects

  describe "projects" do
    alias Glossary.Projects.Project

    import Glossary.ProjectsFixtures
    import Glossary.EntriesFixtures

    test "list_projects/0 returns all projects ordered by name" do
      project_b = project_fixture(%{name: "Bravo"})
      project_a = project_fixture(%{name: "Alpha"})

      assert Projects.list_projects() == [project_a, project_b]
    end

    test "get_project!/1 returns the project with entries preloaded" do
      project = project_fixture()
      fetched = Projects.get_project!(project.id)
      assert fetched.id == project.id
      assert fetched.entries == []
    end

    test "create_project/1 with valid data creates a project" do
      assert {:ok, %Project{} = project} = Projects.create_project(%{name: "My Project"})
      assert project.name == "My Project"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(%{name: nil})
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      assert {:ok, %Project{} = updated} = Projects.update_project(project, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, %{name: nil})
      assert Projects.get_project!(project.id).name == project.name
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "entry association" do
    import Glossary.ProjectsFixtures
    import Glossary.EntriesFixtures

    test "add_entry/2 adds an entry to a project" do
      project = project_fixture()
      entry = entry_fixture()

      {:ok, updated_project} = Projects.add_entry(project, entry)
      assert length(updated_project.entries) == 1
      assert hd(updated_project.entries).id == entry.id
    end

    test "add_entry/2 is idempotent" do
      project = project_fixture()
      entry = entry_fixture()

      {:ok, _} = Projects.add_entry(project, entry)
      {:ok, updated_project} = Projects.add_entry(project, entry)
      assert length(updated_project.entries) == 1
    end

    test "remove_entry/2 removes an entry from a project" do
      project = project_fixture()
      entry = entry_fixture()

      {:ok, project} = Projects.add_entry(project, entry)
      assert length(project.entries) == 1

      {:ok, project} = Projects.remove_entry(project, entry)
      assert project.entries == []
    end

    test "available_entries/2 returns entries not in the project" do
      project = project_fixture()
      entry_in = entry_fixture(%{title_text: "In Project"})
      entry_out = entry_fixture(%{title_text: "Not In Project"})

      {:ok, _} = Projects.add_entry(project, entry_in)

      available = Projects.available_entries(project)
      available_ids = Enum.map(available, & &1.id)

      assert entry_out.id in available_ids
      refute entry_in.id in available_ids
    end

    test "deleting a project does not delete its entries" do
      project = project_fixture()
      entry = entry_fixture()
      {:ok, _} = Projects.add_entry(project, entry)

      {:ok, _} = Projects.delete_project(project)

      assert Glossary.Entries.get_entry!(entry.id).id == entry.id
    end

    test "deleting an entry removes it from project associations" do
      project = project_fixture()
      entry = entry_fixture()
      {:ok, _} = Projects.add_entry(project, entry)

      {:ok, _} = Glossary.Entries.delete_entry(entry)

      refreshed = Projects.get_project!(project.id)
      assert refreshed.entries == []
    end
  end
end
