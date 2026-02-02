defmodule GlossaryWeb.EntryLiveTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glossary.EntriesFixtures

  # Note: body/body_text/title_text are managed by the Tiptap JS hook in the browser.
  # In tests, we submit them explicitly.
  @update_attrs %{
    title: "<p>some updated title</p>",
    title_text: "some updated title",
    body: "<p>some updated body</p>",
    body_text: "some updated body",
    subtitle: "some updated subtitle"
  }
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

    test "updates entry in listing", %{conn: conn, entry: entry} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#entries-#{entry.id} a", "View")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/#{entry}")

      assert has_element?(form_live, "#entry-form")

      assert {:ok, index_live, _html} =
               form_live
               |> render_submit("save", %{"entry" => @update_attrs})
               |> follow_redirect(conn, ~p"/entries")

      html = render(index_live)
      assert html =~ "Entry updated successfully"
      assert html =~ "some updated title"
    end
  end
end
