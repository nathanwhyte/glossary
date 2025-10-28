defmodule GlossaryWeb.SearchLiveTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "mount/3" do
    test "mounts with show: false by default", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # The search modal is rendered as a child LiveView
      search_view = find_live_child(view, "search-modal")
      html = render(search_view)

      assert html =~ "hidden"
      assert html =~ ~s(data-show="false")
    end

    test "subscribes to search_modal PubSub topic when connected", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # Verify the view is subscribed by checking if it responds to PubSub messages
      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})

      html = render(search_view)
      assert html =~ "modal-open"
    end
  end

  describe "handle_info/2" do
    test "shows modal when receiving show_search_modal: true message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})

      html = render(search_view)
      assert html =~ "modal-open"
      assert html =~ ~s(data-show="true")
    end

    test "hides modal when receiving show_search_modal: false message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # First show the modal
      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})
      html = render(search_view)
      assert html =~ "modal-open"

      # Then hide it
      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, false})

      html = render(search_view)
      assert html =~ "hidden"
      assert html =~ ~s(data-show="false")
    end
  end

  describe "handle_event/3" do
    test "modal_click_away event handler exists", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # Verify the modal has the click-away attribute
      html = render(search_view)
      assert html =~ ~s(phx-click-away="modal_click_away")
    end
  end

  describe "render/1" do
    test "renders modal with correct visibility state when show: false", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      html = render(search_view)

      assert html =~ "hidden"
      assert html =~ ~s(data-show="false")
    end

    test "renders modal with correct visibility state when show: true", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})

      html = render(search_view)

      assert html =~ "modal-open"
      assert html =~ ~s(data-show="true")
    end

    test "renders search input field", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      html = render(search_view)

      assert html =~ ~s(id="search-input")
      assert html =~ ~s(placeholder="Search")
    end
  end

  describe "integration with HomeLive" do
    test "search modal opens when clicking search bar", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # Click the search bar
      view |> element("div[phx-click=\"click_search\"]") |> render_click()

      html = render(search_view)
      assert html =~ "modal-open"
    end

    test "search modal can be opened and closed via PubSub", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # Open via PubSub
      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})
      html = render(search_view)
      assert html =~ "modal-open"

      # Close via PubSub
      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, false})
      html = render(search_view)
      assert html =~ "hidden"
    end
  end

  describe "keyboard shortcuts integration" do
    test "Cmd+K opens search modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # Simulate Cmd+K keydown
      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      view |> element("div[phx-window-keydown=\"key_down\"]") |> render_keydown(%{"key" => "k"})

      html = render(search_view)
      assert html =~ "modal-open"
    end

    test "Escape closes search modal when leader key is down", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # First open the modal
      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      view |> element("div[phx-window-keydown=\"key_down\"]") |> render_keydown(%{"key" => "k"})
      html = render(search_view)
      assert html =~ "modal-open"

      # Then close with Escape
      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Escape"})

      html = render(search_view)
      assert html =~ "hidden"
    end

    test "Escape does not close modal when leader key is not down", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      # Open the modal directly via PubSub
      Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})
      html = render(search_view)
      assert html =~ "modal-open"

      # Try to close with Escape without leader key
      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Escape"})

      # Modal should still be open (since leader key is not down)
      html = render(search_view)
      assert html =~ "modal-open"
    end
  end

  describe "JavaScript hook integration" do
    test "SearchModal hook is attached to modal container", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      html = render(search_view)

      # Verify the hook is attached
      assert html =~ ~s(phx-hook="SearchModal")
    end

    test "modal container has correct data attributes for JavaScript", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      html = render(search_view)

      # Verify data attributes that JavaScript hook uses
      assert html =~ ~s(id="search-modal-container")
      assert html =~ ~s(data-show="false")
    end

    test "search input has correct ID for JavaScript focus", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")
      search_view = find_live_child(view, "search-modal")

      html = render(search_view)

      # Verify the input has the ID that JavaScript hook targets for focus
      assert html =~ ~s(id="search-input")
    end
  end
end
