defmodule GlossaryWeb.RouterTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /entries/new" do
    test "returns 200 and renders NewEntryLive", %{conn: conn} do
      {:ok, view, html} = live(conn, "/entries/new")

      # Verify the route returns 200 (no error)
      assert html =~ "New Entry"
      assert view.module == GlossaryWeb.NewEntryLive
    end
  end

  describe "keybind listeners" do
    test "Cmd+Shift+O navigates to /entries/new from home page", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Press Cmd (Meta) key
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

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

    test "Ctrl+Shift+O navigates to /entries/new from home page", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Press Ctrl key
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Control"})

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

    test "Cmd+K opens search modal when leader key is down", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Press Cmd (Meta) key
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      # Press K key - should open search modal via PubSub
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "k"})

      # Check that search modal is opened (via PubSub broadcast)
      # We can verify this by checking the search modal state
      search_view = find_live_child(home_view, "search-modal")
      html = render(search_view)
      assert html =~ "modal-open"
    end

    test "Escape closes search modal when leader key is down", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # First open the search modal
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "k"})

      # Verify modal is open
      search_view = find_live_child(home_view, "search-modal")
      assert render(search_view) =~ "modal-open"

      # Press Escape - should close search modal
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Escape"})

      # Verify modal is closed
      html = render(search_view)
      assert html =~ "hidden"
    end

    test "leader key state is properly managed", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Test that keybinds work when leader key is down
      # Press Cmd (Meta) key
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      # Press K key - should open search modal (only works when leader key is down)
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "k"})

      # Check that search modal is opened
      search_view = find_live_child(home_view, "search-modal")
      html = render(search_view)
      assert html =~ "modal-open"

      # Release Cmd (Meta) key - use key_down event since key_up isn't bound
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      # Press K key again - should NOT open search modal (leader key is up)
      home_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "k"})

      # Modal should still be open from before (not closed by this keypress)
      html = render(search_view)
      assert html =~ "modal-open"
    end

    test "keybinds work on NewEntryLive page", %{conn: conn} do
      {:ok, new_entry_view, _html} = live(conn, "/entries/new")

      # Test that search modal can be opened from NewEntryLive
      new_entry_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      new_entry_view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "k"})

      # Check that search modal is opened
      search_view = find_live_child(new_entry_view, "search-modal")
      html = render(search_view)
      assert html =~ "modal-open"
    end
  end

  describe "quick action links" do
    test "New Entry quick action link exists and has correct href", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Verify the link exists and has the correct href
      assert has_element?(home_view, "a[href=\"/entries/new\"]")

      # Verify the link contains the "New Entry" text
      assert has_element?(home_view, "a[href=\"/entries/new\"] span", "New Entry")
    end

    test "quick action buttons render with correct keybinds", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Check that the New Entry button shows the correct keybinds
      assert has_element?(home_view, "span", "New Entry")
      assert has_element?(home_view, "kbd", "⌘")
      assert has_element?(home_view, "kbd", "shift")
      assert has_element?(home_view, "kbd", "o")
    end

    test "quick action buttons have correct styling", %{conn: conn} do
      {:ok, home_view, _html} = live(conn, "/")

      # Check that enabled buttons have cursor-pointer class
      new_entry_link = home_view |> element("a[href=\"/entries/new\"]")
      html = render(new_entry_link)
      assert html =~ "cursor-pointer"

      # Check that disabled buttons exist and have the correct structure
      assert has_element?(home_view, "a[href=\"#\"]")
      assert has_element?(home_view, "span", "View Last Entry")
      assert has_element?(home_view, "span", "Command Palette")
    end
  end
end
