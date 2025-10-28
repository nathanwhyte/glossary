defmodule GlossaryWeb.SearchLiveTest do
  use GlossaryWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  # Helpers
  defp mount_home(conn) do
    {:ok, view, _html} = live(conn, "/")
    view
  end

  defp search_view(view) do
    find_live_child(view, "search-modal")
  end

  defp render_search(view) do
    view |> search_view() |> render()
  end

  defp open_via_pubsub,
    do: Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})

  defp close_via_pubsub,
    do: Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, false})

  defp assert_open(html) do
    assert html =~ "modal-open"
    assert html =~ ~s(data-show="true")
  end

  defp assert_closed(html) do
    assert html =~ "hidden"
    assert html =~ ~s(data-show="false")
  end

  describe "mount/3" do
    test "mounts with show: false by default", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert_closed(html)
    end

    test "subscribes to search_modal PubSub topic when connected", %{conn: conn} do
      view = mount_home(conn)
      open_via_pubsub()
      html = render_search(view)
      assert html =~ "modal-open"
    end
  end

  describe "handle_info/2" do
    test "shows modal when receiving show_search_modal: true message", %{conn: conn} do
      view = mount_home(conn)
      open_via_pubsub()
      html = render_search(view)
      assert_open(html)
    end

    test "hides modal when receiving show_search_modal: false message", %{conn: conn} do
      view = mount_home(conn)
      open_via_pubsub()
      assert render_search(view) =~ "modal-open"
      close_via_pubsub()
      html = render_search(view)
      assert_closed(html)
    end
  end

  describe "handle_event/3" do
    test "modal_click_away event handler exists", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert html =~ ~s(phx-click-away="modal_click_away")
    end
  end

  describe "render/1" do
    test "renders modal with correct visibility state when show: false", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert_closed(html)
    end

    test "renders modal with correct visibility state when show: true", %{conn: conn} do
      view = mount_home(conn)
      open_via_pubsub()
      html = render_search(view)
      assert_open(html)
    end

    test "renders search input field", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)

      assert html =~ ~s(id="search-input")
      assert html =~ ~s(placeholder="Search")
    end
  end

  describe "integration with HomeLive" do
    test "search modal opens when clicking search bar", %{conn: conn} do
      view = mount_home(conn)
      view |> element("div[phx-click=\"click_search\"]") |> render_click()
      html = render_search(view)
      assert html =~ "modal-open"
    end

    test "search modal can be opened and closed via PubSub", %{conn: conn} do
      view = mount_home(conn)
      open_via_pubsub()
      assert render_search(view) =~ "modal-open"
      close_via_pubsub()
      assert render_search(view) =~ "hidden"
    end
  end

  describe "keyboard shortcuts integration" do
    test "Cmd+K opens search modal", %{conn: conn} do
      view = mount_home(conn)

      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      view |> element("div[phx-window-keydown=\"key_down\"]") |> render_keydown(%{"key" => "k"})
      html = render_search(view)
      assert html =~ "modal-open"
    end

    test "Escape closes search modal when leader key is down", %{conn: conn} do
      view = mount_home(conn)

      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Meta"})

      view |> element("div[phx-window-keydown=\"key_down\"]") |> render_keydown(%{"key" => "k"})
      assert render_search(view) =~ "modal-open"

      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Escape"})

      html = render_search(view)
      assert html =~ "hidden"
    end

    test "Escape does not close modal when leader key is not down", %{conn: conn} do
      view = mount_home(conn)
      open_via_pubsub()
      assert render_search(view) =~ "modal-open"

      view
      |> element("div[phx-window-keydown=\"key_down\"]")
      |> render_keydown(%{"key" => "Escape"})

      html = render_search(view)
      assert html =~ "modal-open"
    end
  end

  describe "JS hook integration" do
    test "SearchModal hook is attached to modal container", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert html =~ ~s(phx-hook="SearchModal")
    end

    test "modal container has correct data attributes for JS", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert html =~ ~s(id="search-modal-container")
      assert html =~ ~s(data-show="false")
    end

    test "search input has correct ID for JS focus", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert html =~ ~s(id="search-input")
    end
  end
end
