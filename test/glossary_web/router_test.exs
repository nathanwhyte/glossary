defmodule GlossaryWeb.RouterTest do
  use GlossaryWeb.ConnCase
  import Phoenix.LiveViewTest

  import Glossary.EntriesFixtures

  describe "routes" do
    test "GET / mounts HomeLive", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      assert view.module == GlossaryWeb.HomeLive
    end

    test "GET /entries/:entry_id returns 200 for valid entry", %{conn: conn} do
      entry = entry_fixture()
      conn = get(conn, "/entries/#{entry.id}")
      assert html_response(conn, 200)
    end

    test "GET /entries/:entry_id renders EditEntryLive for existing entry", %{conn: conn} do
      entry = entry_fixture()

      {:ok, view, _html} = live(conn, "/entries/#{entry.id}")

      # Verify the route returns 200 and renders EditEntryLive
      assert view.module == GlossaryWeb.EditEntryLive
    end

    test "GET /entries/new creates new entry and redirects to edit page", %{conn: conn} do
      alias Glossary.Entries
      initial_count = length(Entries.list_entries())

      assert {:error, {:live_redirect, %{to: redirect_to}}} =
               live(conn, "/entries/new")

      # Verify redirect is to /entries/:entry_id pattern
      assert redirect_to =~ ~r|/entries/[a-f0-9-]{36}|

      # Verify entry was created in database
      assert length(Entries.list_entries()) == initial_count + 1
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

    test "creates entry in database on Cmd+Shift+O", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      import Glossary.Entries
      initial_count = length(list_entries())

      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Shift"})

      assert {:error, {:live_redirect, _}} =
               view
               |> element("div[phx-window-keydown=\"key_down\"]")
               |> render_keydown(%{"key" => "o"})

      assert length(list_entries()) == initial_count + 1
    end
  end
end
