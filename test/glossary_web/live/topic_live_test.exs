defmodule GlossaryWeb.TopicLiveTest do
  use GlossaryWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glossary.TopicsFixtures
  import Glossary.EntriesFixtures

  setup :register_and_log_in_user

  defp create_topic(_) do
    topic = topic_fixture(%{name: "Test Topic"})
    %{topic: topic}
  end

  describe "Index" do
    setup [:create_topic]

    test "lists all topics", %{conn: conn, topic: topic} do
      {:ok, _index_live, html} = live(conn, ~p"/topics")

      assert html =~ "All Topics"
      assert html =~ topic.name
    end

    test "deletes topic", %{conn: conn, topic: topic} do
      {:ok, index_live, _html} = live(conn, ~p"/topics")

      assert has_element?(index_live, "#topics-#{topic.id}")

      index_live
      |> element("#topics-#{topic.id} a", "Delete")
      |> render_click()

      refute has_element?(index_live, "#topics-#{topic.id}")
    end
  end

  describe "New" do
    test "creates a new topic", %{conn: conn} do
      {:ok, new_live, html} = live(conn, ~p"/topics/new")

      assert html =~ "New Topic"

      new_live
      |> form("#topic-form", topic: %{name: "My New Topic"})
      |> render_submit()

      {path, _flash} = assert_redirect(new_live)
      assert path =~ ~r"/topics/\d+"
    end

    test "validates topic name is required", %{conn: conn} do
      {:ok, new_live, _html} = live(conn, ~p"/topics/new")

      html =
        new_live
        |> form("#topic-form", topic: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "Show" do
    setup [:create_topic]

    test "displays topic", %{conn: conn, topic: topic} do
      {:ok, _show_live, html} = live(conn, ~p"/topics/#{topic}")

      assert html =~ topic.name
      assert html =~ "Entries"
    end

    test "adds an entry to the topic", %{conn: conn, topic: topic} do
      entry = entry_fixture(%{title_text: "Test Entry"})

      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      show_live |> element("#show-entry-picker-button") |> render_click()

      assert has_element?(show_live, "#entry-picker")
      assert has_element?(show_live, "#available-entry-#{entry.id}")

      show_live |> element("#available-entry-#{entry.id}") |> render_click()

      assert has_element?(show_live, "#topic_entries-#{entry.id}")
    end

    test "removes an entry from the topic", %{conn: conn, topic: topic} do
      entry = entry_fixture(%{title_text: "Entry to Remove"})
      Glossary.Topics.add_entry(topic, entry)

      {:ok, show_live, _html} = live(conn, ~p"/topics/#{topic}")

      assert has_element?(show_live, "#topic_entries-#{entry.id}")

      show_live
      |> element("#topic_entries-#{entry.id} a", "Remove")
      |> render_click()

      refute has_element?(show_live, "#topic_entries-#{entry.id}")
    end
  end

  describe "Edit" do
    setup [:create_topic]

    test "updates topic name", %{conn: conn, topic: topic} do
      {:ok, edit_live, html} = live(conn, ~p"/topics/#{topic}/edit")

      assert html =~ "Edit Topic"

      edit_live
      |> form("#topic-form", topic: %{name: "Renamed Topic"})
      |> render_submit()

      assert_redirect(edit_live, ~p"/topics/#{topic}")

      updated = Glossary.Topics.get_topic!(topic.id)
      assert updated.name == "Renamed Topic"
    end

    test "validates name is required on edit", %{conn: conn, topic: topic} do
      {:ok, edit_live, _html} = live(conn, ~p"/topics/#{topic}/edit")

      html =
        edit_live
        |> form("#topic-form", topic: %{name: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end
end
