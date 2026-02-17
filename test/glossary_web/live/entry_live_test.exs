defmodule GlossaryWeb.EntryLiveTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glossary.EntriesFixtures

  setup :register_and_log_in_user

  defp create_entry(_) do
    entry = entry_fixture()

    %{entry: entry}
  end

  describe "Index" do
    setup [:create_entry]

    test "lists all entries", %{conn: conn, entry: entry} do
      {:ok, _index_live, html} = live(conn, ~p"/entries")

      assert html =~ "All Entries"
      assert html =~ entry.title_text
    end

    test "updates entry via events", %{conn: conn, entry: entry} do
      {:ok, edit_live, _html} = live(conn, ~p"/entries/#{entry}")

      render_hook(edit_live, "title_update", %{
        "title" => "<p>some updated title</p>",
        "title_text" => "some updated title"
      })

      render_hook(edit_live, "body_update", %{
        "body" => "<p>some updated body</p>",
        "body_text" => "some updated body"
      })

      updated = Glossary.Entries.get_entry!(entry.id)
      assert updated.title == "<p>some updated title</p>"
      assert updated.title_text == "some updated title"
      assert updated.body == "<p>some updated body</p>"
      assert updated.body_text == "some updated body"
    end
  end
end
