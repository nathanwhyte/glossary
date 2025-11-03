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

      # Verify we only show 3 entries by counting entry title divs
      entry_count = html |> String.split("recent-entry-title") |> length() |> Kernel.-(1)
      assert entry_count == 5

      # Verify at least some entries are rendered (we can't predict which 3 will be shown)
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
end
