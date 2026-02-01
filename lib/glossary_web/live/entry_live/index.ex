defmodule GlossaryWeb.EntryLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias GlossaryWeb.EntryLayouts

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <EntryLayouts.entry_table
        table_title="All Entries"
        table_rows={@streams.entries}
      />
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    IO.inspect(list_entries(), label: "Mounting EntryLive.Index with entries")

    {:ok,
     socket
     |> assign(:page_title, "All Entries")
     |> stream(:entries, list_entries())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    entry = Entries.get_entry!(id)
    {:ok, _} = Entries.delete_entry(entry)

    {:noreply, stream_delete(socket, :entries, entry)}
  end

  defp list_entries() do
    Entries.list_entries()
  end
end
