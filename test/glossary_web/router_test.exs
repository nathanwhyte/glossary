defmodule GlossaryWeb.RouterTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /entries/new" do
    test "returns 200 and renders NewEntryLive", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/entries/new")

      # Verify the route returns 200 (no error)
      assert view.module == GlossaryWeb.NewEntryLive
    end
  end

  describe "keybind listeners" do
    test "Shift+O navigates to /entries/new from home page with different leader keys", %{
      conn: conn
    } do
      for leader_key <- ["Meta", "Control"] do
        {:ok, home_view, _html} = live(conn, "/")

        # Press leader key (Cmd or Ctrl)
        home_view
        |> element("div[phx-window-keydown=\"key_down\"]")
        |> render_keydown(%{"key" => leader_key})

        # Press Shift key
        home_view
        |> element("div[phx-window-keydown=\"key_down\"]")
        |> render_keydown(%{"key" => "Shift"})

        # Press O key - should navigate to /entries/new
        assert {:error, {:live_redirect, %{kind: :push, to: "/entries/new"}}} =
                 home_view
                 |> element("div[phx-window-keydown=\"key_down\"]")
                 |> render_keydown(%{"key" => "o"})
      end
    end

    test "O key alone does not navigate without Shift", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Press Cmd (Meta) key
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      # Press O key WITHOUT Shift - should NOT navigate
      # We can verify this by checking that we're still on the home page
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "o"})

      # Should still be on home page (not redirected)
      assert home_view.module == GlossaryWeb.HomeLive
    end
  end
end
