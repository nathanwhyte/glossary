defmodule GlossaryWeb.EntryLiveTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glossary.EntriesFixtures

  # Note: body and body_text are managed by the Tiptap JS hook via hidden inputs,
  # so we only include title/subtitle in form test attrs
  @update_attrs %{title: "some updated title", subtitle: "some updated subtitle"}
  @invalid_attrs %{title: nil, subtitle: nil}
  defp create_entry(_) do
    entry = entry_fixture()

    %{entry: entry}
  end

  describe "Index" do
    setup [:create_entry]

    test "lists all entries", %{conn: conn, entry: entry} do
      {:ok, _index_live, html} = live(conn, ~p"/entries")

      assert html =~ "All Entries"
      assert html =~ entry.title
    end

    test "saves new entry", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Entry")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/new")

      assert render(form_live) =~ "New Entry"

      assert form_live
             |> form("#entry-form", entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      # Use render_submit/2 with explicit params to include body (managed by Tiptap hook in browser)
      assert {:ok, index_live, _html} =
               form_live
               |> render_submit("save", %{
                 "entry" => %{
                   "title" => "some title",
                   "subtitle" => "some subtitle",
                   "body" => "<p>some body</p>",
                   "body_text" => "some body"
                 }
               })
               |> follow_redirect(conn, ~p"/entries")

      html = render(index_live)
      assert html =~ "Entry created successfully"
      assert html =~ "some title"
    end

    test "updates entry in listing", %{conn: conn, entry: entry} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#entries-#{entry.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/#{entry}/edit")

      assert render(form_live) =~ "Edit Entry"

      assert form_live
             |> form("#entry-form", entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#entry-form", entry: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/entries")

      html = render(index_live)
      assert html =~ "Entry updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes entry in listing", %{conn: conn, entry: entry} do
      {:ok, index_live, _html} = live(conn, ~p"/entries")

      assert index_live |> element("#entries-#{entry.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#entries-#{entry.id}")
    end
  end

  describe "Show" do
    setup [:create_entry]

    test "displays entry", %{conn: conn, entry: entry} do
      {:ok, _show_live, html} = live(conn, ~p"/entries/#{entry}")

      assert html =~ "Show Entry"
      assert html =~ entry.title
    end

    test "updates entry and returns to show", %{conn: conn, entry: entry} do
      {:ok, show_live, _html} = live(conn, ~p"/entries/#{entry}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/entries/#{entry}/edit?return_to=show")

      assert render(form_live) =~ "Edit Entry"

      assert form_live
             |> form("#entry-form", entry: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#entry-form", entry: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/entries/#{entry}")

      html = render(show_live)
      assert html =~ "Entry updated successfully"
      assert html =~ "some updated title"
    end
  end
end
