defmodule GlossaryWeb.PageControllerTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    {:ok, _view, _html} = live(conn, ~p"/")
  end
end
