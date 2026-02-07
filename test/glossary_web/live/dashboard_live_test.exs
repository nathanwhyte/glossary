defmodule GlossaryWeb.DashboardLiveTest do
  use GlossaryWeb.ConnCase

  import Glossary.EntriesFixtures
  import Phoenix.LiveViewTest

  test "opens modal when search input is focused", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    refute has_element?(view, "#search-modal")

    view
    |> element("#dashboard-search")
    |> render_focus()

    assert has_element?(view, "#search-modal")
    assert has_element?(view, "#search-modal-content[phx-click-away='banish_search_modal']")
  end

  test "closes modal on escape", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("#dashboard-search")
    |> render_focus()

    assert has_element?(view, "#search-modal")

    render_keydown(view, "banish_search_modal", %{"key" => "escape"})

    refute has_element?(view, "#search-modal")
  end

  test "shows search results in the modal", %{conn: conn} do
    matching = entry_fixture(%{title: "<p>Alpha Term</p>", title_text: "Alpha Term"})
    _other = entry_fixture(%{title: "<p>Zeta Topic</p>", title_text: "Zeta Topic"})

    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> element("#dashboard-search")
    |> render_focus()

    view
    |> element("#dashboard-search-form")
    |> render_change(%{"query" => "Alpha"})

    assert has_element?(view, "#search-modal #search-results")
    assert has_element?(view, "#search-results a", matching.title_text)
  end
end
