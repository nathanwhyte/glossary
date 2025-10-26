defmodule GlossaryWeb.HomeLiveTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to Glossary"
    assert render(page_live) =~ "Welcome to Glossary"
  end

  test "renders home page content", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "h1", "Welcome to Glossary")
  end
end
