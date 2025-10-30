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
    assert has_element?(view, "kbd", "o")

    assert has_element?(view, "span", "View Last Entry")
    assert has_element?(view, "kbd", "⌘")
    assert has_element?(view, "kbd", "shift")
    assert has_element?(view, "kbd", "s")

    assert has_element?(view, "span", "Command Palette")
    assert has_element?(view, "kbd", "⌘")
    assert has_element?(view, "kbd", "shift")
    assert has_element?(view, "kbd", "p")

    # just links
    assert has_element?(view, "span", "View All Tags")
    assert has_element?(view, "span", "View All Subjects")
    assert has_element?(view, "span", "View All Projects")
  end

  test "New Entry quick action link exists and has correct url", %{conn: conn} do
    {:ok, home_view, _html} = live(conn, "/")

    # Verify the link exists and has the correct href
    assert has_element?(home_view, "a[href=\"/entries/new\"]")

    # Verify the link contains the "New Entry" text
    assert has_element?(home_view, "a[href=\"/entries/new\"] span", "New Entry")
  end
end
