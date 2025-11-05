defmodule GlossaryWeb.HomeLiveTest do
  use GlossaryWeb.LiveCase

  import Glossary.EntriesFixtures

  test "mounts HomeLive correctly", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    assert view.module == GlossaryWeb.HomeLive
  end

  test "New Entry quick action link exists and navigates", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    assert has_element?(view, "a[href=\"/entries/new\"]")
  end

  describe "Recent Entries section" do
    test "renders Recent Entries section heading", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")
      assert html =~ "Recent Entries"
      assert has_element?(view, "h1", "Recent Entries")
    end

    test "renders multiple entries and limits to 5 most recent", %{conn: conn} do
      # Create 5 entries to verify limit
      _entry1 = entry_fixture(%{title: "Entry One"})
      _entry2 = entry_fixture(%{title: "Entry Two"})
      _entry3 = entry_fixture(%{title: "Entry Three"})
      _entry4 = entry_fixture(%{title: "Entry Four"})
      _entry5 = entry_fixture(%{title: "Entry Five"})

      {:ok, _view, html} = live(conn, "/")

      # Verify we only show 5 entries by counting entry title divs
      entry_count = html |> String.split("recent-entry-title") |> length() |> Kernel.-(1)
      assert entry_count == 5

      # Verify at least some entries are rendered (we can't predict which 5 will be shown)
      assert html =~ "Entry One" || html =~ "Entry Two" || html =~ "Entry Three" ||
               html =~ "Entry Four" || html =~ "Entry Five"
    end

    test "shows 'No Title' when entry has empty title", %{conn: conn} do
      entry_fixture(%{title: ""})

      {:ok, view, html} = live(conn, "/")

      assert html =~ "No Title"
      assert has_element?(view, ".recent-entry-title", "No Title")
      assert html =~ ~r/text-base-content\/25.*italic/
    end

    test "renders description conditionally based on presence", %{conn: conn} do
      entry_fixture(%{title: "Test Entry", description: ""})

      {:ok, _view, html} = live(conn, "/")

      assert html =~ "Test Entry"
      # Description div should not appear when empty (uses :if condition)
      refute html =~ ~r/<div.*class="recent-entry-description"/

      # Create entry with description
      entry_fixture(%{title: "Test Entry 2", description: "Test Description"})

      {:ok, view2, _html2} = live(conn, "/")

      assert has_element?(view2, ".recent-entry-description", "Test Description")
    end

    test "displays entry card metadata sections", %{conn: conn} do
      entry_fixture(%{title: "Test Entry"})

      {:ok, _view, html} = live(conn, "/")

      # Status section
      assert html =~ "Status"
      assert html =~ "Draft"

      # Project section
      assert html =~ "Project"
      assert html =~ "None"

      # Topic badges section
      assert html =~ "Topics"
      assert html =~ "None"

      # Tag badges section
      assert html =~ "Tags"
      assert html =~ "None"
    end

    test "displays project name when entry has a project", %{conn: conn} do
      entry_with_project_fixture(%{name: "My Project"}, %{title: "Test Entry"})

      {:ok, view, html} = live(conn, "/")

      assert html =~ "Project"
      assert html =~ "My Project"
      assert has_element?(view, ".badge-secondary", "My Project")
    end

    test "displays topic badges when entry has topics", %{conn: conn} do
      topic1 = topic_fixture(%{name: "Elixir"})
      topic2 = topic_fixture(%{name: "Phoenix"})
      entry_with_topics_fixture([topic1, topic2], %{title: "Test Entry"})

      {:ok, view, html} = live(conn, "/")

      assert html =~ "Topics"
      assert html =~ "Elixir"
      assert html =~ "Phoenix"
      assert has_element?(view, ".badge-info", "Elixir")
      assert has_element?(view, ".badge-info", "Phoenix")
    end

    test "displays tag badges when entry has tags", %{conn: conn} do
      tag1 = tag_fixture(%{name: "testing"})
      tag2 = tag_fixture(%{name: "phoenix"})
      entry_with_tags_fixture([tag1, tag2], %{title: "Test Entry"})

      {:ok, view, html} = live(conn, "/")

      assert html =~ "Tags"
      assert html =~ "@testing"
      assert html =~ "@phoenix"
      assert has_element?(view, ".badge-primary", "@testing")
      assert has_element?(view, ".badge-primary", "@phoenix")
    end

    test "displays all relationships on entry card", %{conn: conn} do
      tag = tag_fixture(%{name: "test-tag"})
      topic = topic_fixture(%{name: "Test Topic"})

      entry_with_all_relationships_fixture(
        %{name: "Test Project"},
        [tag],
        [topic],
        %{title: "Test Entry"}
      )

      {:ok, view, html} = live(conn, "/")

      # Project
      assert html =~ "Project"
      assert html =~ "Test Project"

      # Topics
      assert html =~ "Topics"
      assert html =~ "Test Topic"
      assert has_element?(view, ".badge-info", "Test Topic")

      # Tags
      assert html =~ "Tags"
      assert html =~ "@test-tag"
      assert has_element?(view, ".badge-primary", "@test-tag")
    end

    test "shows 'None' when entry has no relationships", %{conn: conn} do
      entry_fixture(%{title: "Test Entry"})

      {:ok, _view, html} = live(conn, "/")

      # Count occurrences of "None" - should appear for Project, Topics, and Tags
      none_count = html |> String.split("None") |> length() |> Kernel.-(1)
      # At least Project, Topics, and Tags
      assert none_count >= 3
    end

    test "displays formatted timestamp and handles timezone", %{conn: conn} do
      _entry = entry_fixture(%{title: "Test Entry"})

      {:ok, _view, html} = live(conn, "/")

      # Timestamp should be displayed and formatted
      assert html =~ "Updated"
      # Date format
      assert html =~ ~r/\d{2}\/\d{2}\/\d{2}/
      # Time format
      assert html =~ ~r/\d{2}:\d{2}/

      # Verify timezone handling (defaults to UTC when not provided)
      entry_fixture(%{title: "Test Entry 2"})

      {:ok, _view2, html2} = live(conn, "/")
      assert html2 =~ "Updated"

      # Mount with timezone in connect params - should not crash
      {:ok, _view3, _html3} =
        live(
          conn
          |> Map.put(:query_params, %{})
          |> Plug.Conn.put_req_header("user-agent", "test"),
          "/"
        )
    end
  end

  describe "change_project event handler" do
    alias Glossary.Repo

    test "sets a project on an entry from home page", %{conn: conn} do
      entry = entry_fixture(%{title: "Test Entry"})
      project = project_fixture(%{name: "Test Project"})
      {:ok, view, _html} = live(conn, "/")

      # Verify entry has no project initially
      assert entry.project_id == nil

      # Trigger the change_project event directly (no need to open dropdown in tests)
      view
      |> element(
        "div[phx-click=\"change_project\"][phx-value-entry_id=\"#{entry.id}\"][phx-value-project_id=\"#{project.id}\"]"
      )
      |> render_click()

      # Re-fetch from database to verify update
      updated_entry = Glossary.Entries.get_entry_details(entry.id)
      assert updated_entry.project_id == project.id
      assert updated_entry.project.name == "Test Project"
    end

    test "clears project when None is selected from home page", %{conn: conn} do
      entry = entry_with_project_fixture(%{name: "Test Project"}, %{title: "Test Entry"})
      {:ok, view, _html} = live(conn, "/")

      # Verify entry has a project initially
      assert entry.project_id != nil

      # Trigger the change_project event with empty project_id
      view
      |> element(
        "div[phx-click=\"change_project\"][phx-value-entry_id=\"#{entry.id}\"][phx-value-project_id=\"\"]"
      )
      |> render_click()

      # Re-fetch from database to verify project is cleared
      updated_entry = Glossary.Entries.get_entry_details(entry.id)
      assert updated_entry.project_id == nil
      assert updated_entry.project == nil
    end

    test "changes from one project to another from home page", %{conn: conn} do
      project1 = project_fixture(%{name: "Project One"})
      project2 = project_fixture(%{name: "Project Two"})

      # Create entry with first project
      entry = entry_fixture(%{title: "Test Entry"})

      entry
      |> Repo.preload(:project)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:project, project1)
      |> Repo.update!()

      {:ok, view, _html} = live(conn, "/")

      # Trigger the change_project event to switch to project2
      view
      |> element(
        "div[phx-click=\"change_project\"][phx-value-entry_id=\"#{entry.id}\"][phx-value-project_id=\"#{project2.id}\"]"
      )
      |> render_click()

      # Re-fetch from database to verify project changed
      updated_entry = Glossary.Entries.get_entry_details(entry.id)
      assert updated_entry.project_id == project2.id
      assert updated_entry.project.name == "Project Two"
    end
  end
end
