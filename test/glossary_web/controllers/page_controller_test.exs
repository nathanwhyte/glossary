defmodule GlossaryWeb.PageControllerTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest

  setup :register_and_log_in_user

  test "GET /", %{conn: conn} do
    {:ok, _view, _html} = live(conn, ~p"/")
  end
end
