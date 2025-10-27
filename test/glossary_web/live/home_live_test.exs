defmodule GlossaryWeb.HomeLiveTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")

    # Navbar content
    assert disconnected_html =~ "🧠"
    assert render(page_live) =~ "Glossary"
  end

  test "renders home page content", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # Navbar content
    assert has_element?(view, "span", "🧠")
    assert has_element?(view, "span", "Glossary")

    # Search guide content
    assert has_element?(view, "code", "@tag")
    assert has_element?(view, "code", "#subject")
    assert has_element?(view, "code", "!")
  end

  test "renders quick start content", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    # with keybinds
    assert has_element?(view, "span", "New Entry")
    assert has_element?(view, "kbd", "⌘")
    assert has_element?(view, "kbd", "shift")
    assert has_element?(view, "kbd", "O")

    assert has_element?(view, "span", "View Last Entry")
    assert has_element?(view, "kbd", "⌘")
    assert has_element?(view, "kbd", "shift")
    assert has_element?(view, "kbd", "S")

    # just links
    assert has_element?(view, "span", "Get a Refresher")
    assert has_element?(view, "span", "View All Tags")
    assert has_element?(view, "span", "View All Subjects")
    assert has_element?(view, "span", "View Projects")
  end
end
