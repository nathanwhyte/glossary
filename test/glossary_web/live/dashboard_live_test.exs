defmodule GlossaryWeb.DashboardTest do
  use GlossaryWeb.ConnCase

  import Glossary.EntriesFixtures
  import Phoenix.LiveViewTest

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

  test "shows search results in the modal", %{conn: conn} do
    matching = entry_fixture(%{title: "<p>Alpha Term</p>", title_text: "Alpha Term"})
    _other = entry_fixture(%{title: "<p>Zeta Topic</p>", title_text: "Zeta Topic"})

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
end
