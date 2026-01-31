defmodule GlossaryWeb.PageControllerTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "#home-counter")
    assert has_element?(view, "#home-counter-value")
    assert has_element?(view, "#home-counter-dec")
    assert has_element?(view, "#home-counter-reset")
    assert has_element?(view, "#home-counter-inc")
  end
end
