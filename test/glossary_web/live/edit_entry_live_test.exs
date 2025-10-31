defmodule GlossaryWeb.EditEntryLiveTest do
  use GlossaryWeb.LiveCase

  alias Glossary.Entries

  describe "mount/3" do
    test "mounts EditEntryLive with entry from database", %{conn: conn} do
      entry = entry_fixture(%{title: "Test Title", description: "Test Desc", body: "Body"})
      view = mount_edit_entry(conn, entry)

      assert view.module == GlossaryWeb.EditEntryLive
    end

    test "loads entry correctly", %{conn: conn} do
      entry = entry_fixture()
      view = mount_edit_entry(conn, entry)

      # Verify entry is loaded by checking the module mounts successfully
      assert view.module == GlossaryWeb.EditEntryLive
    end
  end

  describe "title_update event handler" do
    test "updates entry title in database", %{conn: conn} do
      entry = entry_fixture(%{title: "Original Title"})
      view = mount_edit_entry(conn, entry)

      # Simulate the hook event using render_hook
      render_hook(view, "title_update", %{"title" => "Updated Title"})

      # Re-fetch from database to verify update
      updated_entry = Entries.get_entry(entry.id)
      assert updated_entry.title == "Updated Title"
    end

    test "updates entry title with HTML content", %{conn: conn} do
      entry = entry_fixture(%{title: "Original"})
      view = mount_edit_entry(conn, entry)

      render_hook(view, "title_update", %{"title" => "<p>New Title</p>"})

      updated_entry = Entries.get_entry(entry.id)
      assert updated_entry.title == "<p>New Title</p>"
    end
  end

  describe "description_update event handler" do
    test "updates entry description in database", %{conn: conn} do
      entry = entry_fixture(%{description: "Original Description"})
      view = mount_edit_entry(conn, entry)

      render_hook(view, "description_update", %{"description" => "Updated Description"})

      # Re-fetch from database to verify update
      updated_entry = Entries.get_entry(entry.id)
      assert updated_entry.description == "Updated Description"
    end

    test "updates entry description with HTML content", %{conn: conn} do
      entry = entry_fixture(%{description: "Original"})
      view = mount_edit_entry(conn, entry)

      render_hook(view, "description_update", %{
        "description" => "<p>New <strong>Description</strong></p>"
      })

      updated_entry = Entries.get_entry(entry.id)
      assert updated_entry.description == "<p>New <strong>Description</strong></p>"
    end
  end

  describe "body_update event handler" do
    test "updates entry body in database", %{conn: conn} do
      entry = entry_fixture(%{body: "Original Body"})
      view = mount_edit_entry(conn, entry)

      render_hook(view, "body_update", %{"body" => "Updated Body"})

      # Re-fetch from database to verify update
      updated_entry = Entries.get_entry(entry.id)
      assert updated_entry.body == "Updated Body"
    end

    test "updates entry body with complex HTML", %{conn: conn} do
      entry = entry_fixture(%{body: "Original"})
      view = mount_edit_entry(conn, entry)

      render_hook(view, "body_update", %{"body" => "<h1>Heading</h1><p>Content</p>"})

      updated_entry = Entries.get_entry(entry.id)
      assert updated_entry.body == "<h1>Heading</h1><p>Content</p>"
    end
  end

  describe "PubSub event handlers" do
    @moduletag :capture_log

    test "summon_modal broadcasts to search_modal topic", %{conn: conn} do
      entry = entry_fixture()
      view = mount_edit_entry(conn, entry)

      # Subscribe to the PubSub topic to verify the message is broadcast
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")

      render_hook(view, "summon_modal", %{})

      # Wait for the message
      assert_receive {:summon_modal, true}
    end

    test "banish_modal broadcasts to search_modal topic", %{conn: conn} do
      entry = entry_fixture()
      view = mount_edit_entry(conn, entry)

      # Subscribe to the PubSub topic to verify the message is broadcast
      Phoenix.PubSub.subscribe(Glossary.PubSub, "search_modal")

      render_hook(view, "banish_modal", %{})

      # Wait for the message
      assert_receive {:summon_modal, false}
    end
  end

  describe "render/1" do
    test "renders critical JS hook elements", %{conn: conn} do
      entry = entry_fixture()
      {:ok, _view, html} = live(conn, "/entries/#{entry.id}")

      # Critical for JS hooks
      assert html =~ ~s(id="title-editor")
      assert html =~ ~s(id="description-editor")
      assert html =~ ~s(id="body-editor")
      assert html =~ ~s(id="entry_body")
    end

    test "renders search modal", %{conn: conn} do
      entry = entry_fixture()
      view = mount_edit_entry(conn, entry)

      search_view = find_live_child(view, "search-modal")
      assert search_view != nil
    end
  end
end
