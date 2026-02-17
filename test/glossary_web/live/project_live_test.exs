defmodule GlossaryWeb.ProjectLiveTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glossary.ProjectsFixtures
  import Glossary.EntriesFixtures

  setup :register_and_log_in_user

  defp create_project(_) do
    project = project_fixture(%{name: "Test Project"})
    %{project: project}
  end

  describe "Index" do
    setup [:create_project]

    test "lists all projects", %{conn: conn, project: project} do
      {:ok, _index_live, html} = live(conn, ~p"/projects")

      assert html =~ "All Projects"
      assert html =~ project.name
    end

    test "deletes project", %{conn: conn, project: project} do
      {:ok, index_live, _html} = live(conn, ~p"/projects")

      assert has_element?(index_live, "#projects-#{project.id}")

      index_live
      |> element("#projects-#{project.id} a", "Delete")
      |> render_click()

      refute has_element?(index_live, "#projects-#{project.id}")
    end
  end

  describe "New" do
    test "creates a new project", %{conn: conn} do
      {:ok, new_live, html} = live(conn, ~p"/projects/new")

      assert html =~ "New Project"

      new_live
      |> form("#project-form", project: %{name: "My New Project"})
      |> render_submit()

      {path, _flash} = assert_redirect(new_live)
      assert path =~ ~r"/projects/\d+"
    end

    test "validates project name is required", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/projects/new")

      html =
        new_live
        |> form("#project-form", project: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Show" do
    setup [:create_project]

    test "displays project", %{conn: conn, project: project} do
      {:ok, _show_live, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ project.name
      assert html =~ "Entries"
    end

    test "adds an entry to the project", %{conn: conn, project: project} do
      entry = entry_fixture(%{title_text: "Test Entry"})

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}")

      show_live |> element("#show-entry-picker-button") |> render_click()

      assert has_element?(show_live, "#entry-picker")
      assert has_element?(show_live, "#available-entry-#{entry.id}")

      show_live |> element("#available-entry-#{entry.id}") |> render_click()

      assert has_element?(show_live, "#project_entries-#{entry.id}")
    end

    test "removes an entry from the project", %{conn: conn, project: project} do
      entry = entry_fixture(%{title_text: "Entry to Remove"})
      Glossary.Projects.add_entry(project, entry)

      {:ok, show_live, _html} = live(conn, ~p"/projects/#{project}")

      assert has_element?(show_live, "#project_entries-#{entry.id}")

      show_live
      |> element("#project_entries-#{entry.id} a", "Remove")
      |> render_click()

      refute has_element?(show_live, "#project_entries-#{entry.id}")
    end
  end

  describe "Edit" do
    setup [:create_project]

    test "updates project name", %{conn: conn, project: project} do
      {:ok, edit_live, html} = live(conn, ~p"/projects/#{project}/edit")

      assert html =~ "Edit Project"

      assert edit_live
             |> form("#project-form", project: %{name: "Renamed Project"})
             |> render_submit()

      assert_redirect(edit_live, ~p"/projects/#{project}")

      updated = Glossary.Projects.get_project!(project.id)
      assert updated.name == "Renamed Project"
    end

    test "validates name is required on edit", %{conn: conn, project: project} do
      {:ok, edit_live, _html} = live(conn, ~p"/projects/#{project}/edit")

      html =
        edit_live
        |> form("#project-form", project: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end
end
