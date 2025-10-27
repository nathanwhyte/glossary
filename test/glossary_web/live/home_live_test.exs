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
end
