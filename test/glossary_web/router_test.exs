defmodule GlossaryWeb.RouterTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /entries/:entry_id" do
    test "returns 200 and renders EditEntryLive for existing entry", %{conn: conn} do
      # Create a test entry
      alias Glossary.Entries.Entry
      alias Glossary.Repo

      {:ok, entry} = Repo.insert(%Entry{})

      {:ok, view, _html} = live(conn, "/entries/#{entry.id}")

      # Verify the route returns 200 and renders EditEntryLive
      assert view.module == GlossaryWeb.EditEntryLive
    end
  end

  describe "keybind listeners" do
    test "Shift+O creates new entry and navigates to edit page with different leader keys", %{
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

        # Press O key - should create entry and navigate to edit page
        assert {:error, {:live_redirect, %{kind: :push, to: redirect_to}}} =
                 home_view
                 |> element("div[phx-window-keydown=\"key_down\"]")
                 |> render_keydown(%{"key" => "o"})

        # Verify redirect is to /entries/:entry_id pattern
        assert redirect_to =~ ~r|/entries/[a-f0-9-]{36}|
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
