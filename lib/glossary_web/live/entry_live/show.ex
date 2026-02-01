defmodule GlossaryWeb.EntryLive.Show do
  use GlossaryWeb, :live_view

  alias Glossary.Entries

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Entry {@entry.id}
        <:subtitle>This is a entry record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/entries"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/entries/#{@entry}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit entry
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Title">{@entry.title}</:item>
        <:item title="Subtitle">{@entry.subtitle}</:item>
        <:item title="Body">
          <div class="prose prose-sm max-w-none">
            {raw(@entry.body)}
          </div>
        </:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Entry")
     |> assign(:entry, Entries.get_entry!(id))}
  end
end
