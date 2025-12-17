defmodule GlossaryWeb.LiveCase do
  @moduledoc """
  Test case for LiveView tests with shared helpers and fixtures.
  """

  use ExUnit.CaseTemplate

  # Set up authentication for all LiveView tests
  # since the routes require authentication
  # This runs after ConnCase setup which provides the conn
  setup context do
    case context do
      %{conn: _conn} = ctx ->
        GlossaryWeb.ConnCase.register_and_log_in_user(ctx)

      _ ->
        # ConnCase setup hasn't run yet, return context as-is
        # The setup will be called again after ConnCase setup
        context
    end
  end

  using do
    quote do
      # Inherit from ConnCase for connection setup
      use GlossaryWeb.ConnCase

      # Import LiveView test helpers
      import Phoenix.LiveViewTest

      # Import fixture helpers
      import Glossary.EntriesFixtures

      # Define helper functions
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

      defp open_search_modal,
        do: Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:summon_modal, true})

      defp close_search_modal,
        do: Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:summon_modal, false})

      defp assert_modal_open(html) do
        # Check for modal-open class and data-show attribute using DOM queries
        assert html =~ "modal-open"
        assert html =~ ~s(data-show="true")
      end

      defp assert_modal_closed(html) do
        # Check for hidden class and data-show attribute using DOM queries
        assert html =~ "hidden"
        assert html =~ ~s(data-show="false")
      end

      defp mount_edit_entry(conn, entry) do
        {:ok, view, _html} = live(conn, "/entries/#{entry.id}")
        view
      end

      defp mount_edit_entry_with_fixture(conn, attrs \\ %{}) do
        entry = entry_fixture(attrs)
        mount_edit_entry(conn, entry)
      end

      defp simulate_keydown(view, key, attrs \\ %{}) do
        view
        |> element("div[phx-window-keydown=\"key_down\"]")
        |> render_keydown(Map.merge(%{"key" => key}, attrs))
      end

      defp simulate_keyup(view, key, attrs \\ %{}) do
        view
        |> element("div[phx-window-keyup=\"key_up\"]")
        |> render_keyup(Map.merge(%{"key" => key}, attrs))
      end
    end
  end
end
