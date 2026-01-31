defmodule GlossaryWeb.EntryLive.Index do
  use GlossaryWeb, :live_view

  alias Glossary.Entries

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Entries
        <:actions>
          <.button variant="primary" navigate={~p"/entries/new"}>
            <.icon name="hero-plus" /> New Entry
          </.button>
        </:actions>
      </.header>

      <.table
        id="entries"
        rows={@streams.entries}
        row_click={fn {_id, entry} -> JS.navigate(~p"/entries/#{entry}") end}
      >
        <:col :let={{_id, entry}} label="Title">{entry.title}</:col>
        <:col :let={{_id, entry}} label="Subtitle">{entry.subtitle}</:col>
        <:col :let={{_id, entry}} label="Body">{entry.body}</:col>
        <:action :let={{_id, entry}}>
          <div class="sr-only">
            <.link navigate={~p"/entries/#{entry}"}>Show</.link>
          </div>
          <.link navigate={~p"/entries/#{entry}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, entry}}>
          <.link
            phx-click={JS.push("delete", value: %{id: entry.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Entries")
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
