defmodule Glossary.ProjectsTest do
  use Glossary.DataCase

  alias Glossary.Projects

  describe "projects" do
    alias Glossary.Projects.Project

    import Glossary.AccountsFixtures
    import Glossary.ProjectsFixtures
    import Glossary.EntriesFixtures

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "list_projects/1 returns all projects ordered by name", %{current_scope: current_scope} do
      project_b = project_fixture(current_scope, %{name: "Bravo"})
      project_a = project_fixture(current_scope, %{name: "Alpha"})

      assert Projects.list_projects(current_scope) == [project_a, project_b]
    end

    test "get_project!/2 returns the project with entries preloaded", %{
      current_scope: current_scope
    } do
      project = project_fixture(current_scope, %{})
      fetched = Projects.get_project!(current_scope, project.id)
      assert fetched.id == project.id
      assert fetched.entries == []
    end

    test "create_project/2 with valid data creates a project", %{current_scope: current_scope} do
      assert {:ok, %Project{} = project} =
               Projects.create_project(current_scope, %{name: "My Project"})

      assert project.name == "My Project"
    end

    test "create_project/2 with invalid data returns error changeset", %{
      current_scope: current_scope
    } do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(current_scope, %{name: nil})
    end

    test "update_project/3 with valid data updates the project", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})

      assert {:ok, %Project{} = updated} =
               Projects.update_project(current_scope, project, %{name: "Updated"})

      assert updated.name == "Updated"
    end

    test "update_project/3 with invalid data returns error changeset", %{
      current_scope: current_scope
    } do
      project = project_fixture(current_scope, %{})

      assert {:error, %Ecto.Changeset{}} =
               Projects.update_project(current_scope, project, %{name: nil})

      assert Projects.get_project!(current_scope, project.id).name == project.name
    end

    test "delete_project/2 deletes the project", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      assert {:ok, %Project{}} = Projects.delete_project(current_scope, project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(current_scope, project.id) end
    end

    test "change_project/1 returns a project changeset", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "entry association" do
    import Glossary.AccountsFixtures
    import Glossary.ProjectsFixtures
    import Glossary.EntriesFixtures

    setup do
      %{current_scope: user_scope_fixture()}
    end

    test "add_entry/3 adds an entry to a project", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})

      {:ok, updated_project} = Projects.add_entry(current_scope, project, entry)
      assert length(updated_project.entries) == 1
      assert hd(updated_project.entries).id == entry.id
    end

    test "add_entry/3 is idempotent", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})

      {:ok, _} = Projects.add_entry(current_scope, project, entry)
      {:ok, updated_project} = Projects.add_entry(current_scope, project, entry)
      assert length(updated_project.entries) == 1
    end

    test "remove_entry/3 removes an entry from a project", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})

      {:ok, project} = Projects.add_entry(current_scope, project, entry)
      assert length(project.entries) == 1

      {:ok, project} = Projects.remove_entry(current_scope, project, entry)
      assert project.entries == []
    end

    test "available_entries/3 returns entries not in the project", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      entry_in = entry_fixture(current_scope, %{title_text: "In Project"})
      entry_out = entry_fixture(current_scope, %{title_text: "Not In Project"})

      {:ok, _} = Projects.add_entry(current_scope, project, entry_in)

      available = Projects.available_entries(current_scope, project)
      available_ids = Enum.map(available, & &1.id)

      assert entry_out.id in available_ids
      refute entry_in.id in available_ids
    end

    test "deleting a project does not delete its entries", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})
      {:ok, _} = Projects.add_entry(current_scope, project, entry)

      {:ok, _} = Projects.delete_project(current_scope, project)

      assert Glossary.Entries.get_entry!(current_scope, entry.id).id == entry.id
    end

    test "deleting an entry removes it from project associations", %{current_scope: current_scope} do
      project = project_fixture(current_scope, %{})
      entry = entry_fixture(current_scope, %{})
      {:ok, _} = Projects.add_entry(current_scope, project, entry)

      {:ok, _} = Glossary.Entries.delete_entry(current_scope, entry)

      refreshed = Projects.get_project!(current_scope, project.id)
      assert refreshed.entries == []
    end
  end
end
