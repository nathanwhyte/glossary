defmodule GlossaryWeb.EntryLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias GlossaryWeb.EntryLayouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
        current_scope={@current_scope}
      />

      <LiveLayouts.back_link navigate={~p"/"} text="Back to Dashboard" />

      <EntryLayouts.entry_table
        table_title="All Entries"
        table_rows={@streams.entries}
        allow_delete
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "All Entries")
     |> stream(:entries, list_entries(socket.assigns.current_scope))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    entry = Entries.get_entry!(socket.assigns.current_scope, id)
    {:ok, _} = Entries.delete_entry(socket.assigns.current_scope, entry)

    {:noreply, stream_delete(socket, :entries, entry)}
  end

  defp list_entries(current_scope) do
    Entries.list_entries(current_scope)
  end
end
