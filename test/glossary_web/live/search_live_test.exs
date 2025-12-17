defmodule GlossaryWeb.SearchLiveTest do
  use GlossaryWeb.LiveCase

  setup :register_and_log_in_user

  describe "mount/3" do
    test "mounts with show: false by default", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      assert_modal_closed(html)
    end
  end

  describe "handle_info/2" do
    test "shows modal when receiving summon_modal: true message", %{conn: conn} do
      view = mount_home(conn)
      open_search_modal()
      html = render_search(view)
      assert_modal_open(html)
    end

    test "hides modal when receiving summon_modal: false message", %{conn: conn} do
      view = mount_home(conn)
      open_search_modal()
      html = render_search(view)
      assert_modal_open(html)
      close_search_modal()
      html = render_search(view)
      assert_modal_closed(html)
    end
  end

  describe "render/1" do
    test "renders search input for JS focus", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      # Check for search input ID needed for JavaScript hooks
      assert html =~ ~s(id="search-input")
    end
  end

  describe "keyboard shortcuts" do
    test "Cmd+K opens modal", %{conn: conn} do
      view = mount_home(conn)
      simulate_keydown(view, "Meta")
      simulate_keydown(view, "k")
      html = render_search(view)
      assert html =~ "modal-open"
    end

    test "Ctrl+K opens modal", %{conn: conn} do
      view = mount_home(conn)
      simulate_keydown(view, "Control")
      simulate_keydown(view, "k")
      html = render_search(view)
      assert html =~ "modal-open"
    end

    test "Escape closes modal with leader", %{conn: conn} do
      view = mount_home(conn)
      simulate_keydown(view, "Meta")
      simulate_keydown(view, "k")
      html = render_search(view)
      assert_modal_open(html)
      simulate_keydown(view, "Escape")
      html = render_search(view)
      assert_modal_closed(html)
    end

    test "Escape closes modal without leader", %{conn: conn} do
      view = mount_home(conn)
      open_search_modal()
      html = render_search(view)
      assert_modal_open(html)
      simulate_keydown(view, "Escape")
      html = render_search(view)
      assert_modal_closed(html)
    end
  end

  describe "JavaScript hooks" do
    test "SearchModal hook is attached to modal container", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      # Check for phx-hook attribute needed for JavaScript hooks
      assert html =~ ~s(phx-hook="SearchModal")
    end

    test "modal container has correct data attributes for JS", %{conn: conn} do
      view = mount_home(conn)
      # Ensure modal is closed before testing
      close_search_modal()
      html = render_search(view)
      # Check for IDs and data attributes needed for JavaScript
      assert html =~ ~s(id="search-modal-container")
      assert html =~ ~s(data-show="false")
    end

    test "search input has correct ID for JS focus", %{conn: conn} do
      view = mount_home(conn)
      html = render_search(view)
      # Check for search input ID needed for JavaScript focus
      assert html =~ ~s(id="search-input")
    end
  end
end
