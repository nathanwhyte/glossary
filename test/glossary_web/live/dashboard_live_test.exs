defmodule GlossaryWeb.DashboardTest do
  use GlossaryWeb.ConnCase

  import Glossary.EntriesFixtures
  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "shows the search modal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    assert has_element?(view, "#search-modal")
    assert has_element?(view, "#search-modal-content[phx-click-away='banish_search_modal']")
  end

  test "closes modal on escape", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    assert has_element?(view, "#search-modal")

    view
    |> element("#search-modal")
    |> render_keydown(%{"key" => "escape"})

    refute has_element?(view, "#search-modal")
  end

  test "shows search results in the modal", %{conn: conn, scope: current_scope} do
    matching =
      entry_fixture(current_scope, %{title: "<p>Alpha Term</p>", title_text: "Alpha Term"})

    _other = entry_fixture(current_scope, %{title: "<p>Zeta Topic</p>", title_text: "Zeta Topic"})

    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    view
    |> element("#dashboard-search-form")
    |> render_change(%{"query" => "Alpha"})

    assert has_element?(view, "#search-modal #search-results")
    assert has_element?(view, "#search-results a", matching.title_text)
  end

  test "hides detected prefix from query input and shows mode badge", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    view
    |> element("#dashboard-search-form")
    |> render_change(%{"query" => "@Alpha"})

    assert has_element?(view, "#search-filter-badge", "Projects")
    assert has_element?(view, "#dashboard-search-input[value='Alpha']")
  end

  test "shows starter commands for empty query", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    assert has_element?(view, "#starter-command-results")
    assert has_element?(view, "#starter-command-results #global-command-results-section")
    assert has_element?(view, "#starter-command-results #command-new_entry", "New Entry")
    assert has_element?(view, "#starter-command-results #command-go_entries", "Go to Entries")
  end

  test "groups command mode results under Global", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    view
    |> element("#dashboard-search-form")
    |> render_change(%{"query" => "!"})

    assert has_element?(view, "#command-results #global-command-results-section")
    assert has_element?(view, "#command-results #global-command-results-section", "Global")
    assert has_element?(view, "#command-results #command-new_entry", "New Entry")
  end

  test "clears active prefix when query becomes empty", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    unless has_element?(view, "#search-modal") do
      view
      |> element("#dashboard-search-button")
      |> render_click()
    end

    view
    |> element("#dashboard-search-form")
    |> render_change(%{"query" => "@"})

    assert has_element?(view, "#search-filter-badge", "Projects")

    view
    |> element("#dashboard-search-form")
    |> render_change(%{"query" => ""})

    refute has_element?(view, "#search-filter-badge")
    assert has_element?(view, "#starter-command-results")
  end
end
