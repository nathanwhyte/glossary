defmodule GlossaryWeb.HomeLiveTest do
  use GlossaryWeb.LiveCase

  test "mounts HomeLive correctly", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    assert view.module == GlossaryWeb.HomeLive
  end

  test "New Entry quick action link exists and navigates", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    assert has_element?(view, "a[href=\"/entries/new\"]")
  end
end
