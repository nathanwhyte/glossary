defmodule GlossaryWeb.EditEntryLive do
  @moduledoc """
  LiveView for editing glossary entries.

  The "New Entry" keybind and quick start action also end up here.
  The listener for those events will insert a new "draft" entry, get
  the UUID assigned to the new entry, and route the user to edit it here.

  This allows for auto-save on change and on blur without needing to
  worry about managing a cache.

  Entries that are blank when this component unmounts will be dropped.
  Otherwise, the entry will remain marked as "draft" until the user hits
  the submit button.
  """
  use GlossaryWeb, :live_view

  require Logger

  import GlossaryWeb.KeybindMacros

  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @impl true
  def mount(%{"entry_id" => entry_id}, _session, socket) do
    # TODO: show error flash if Ecto has trouble loading the entry

    Logger.info("rendered")

    entry = Repo.get(Entry, entry_id)
    {:ok, assign(socket, leader_down: false, shift_down: false, entry: entry)}
  end

  pubsub_broadcast_on_event("summon_modal", :summon_modal, true, "search_modal")
  pubsub_broadcast_on_event("banish_modal", :summon_modal, false, "search_modal")

  keybind_listeners()

  @impl true
  def handle_event("title_blur", %{"title" => title}, socket) do
    # TODO: support marking as draft (or autosaving as a draft after title is updated)

    {:ok, _} =
      Entry.changeset(socket.assigns.entry, %{title: title})
      |> Repo.update()

    {:noreply, socket}
  end

  def handle_event("description_blur", %{"description" => description}, socket) do
    {:ok, _} =
      Entry.changeset(socket.assigns.entry, %{description: description})
      |> Repo.update()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        id="edit-entry-container"
        phx-window-keydown="key_down"
        phx-window-keyup="key_up"
        phx-update="ignore"
        class="flex flex-col gap-4 pt-8"
      >
        <header>
          <div
            id="title-editor"
            phx-hook="TitleEditor"
          >
            <input id="entry_title" type="hidden" name="entry[title]" value={@entry.title} />
          </div>

          <div
            id="description-editor"
            phx-hook="DescriptionEditor"
          >
            <input
              id="entry_description"
              type="hidden"
              name="entry[description]"
              value={@entry.description}
            />
          </div>
        </header>
      </div>
    </Layouts.app>

    {live_render(@socket, GlossaryWeb.SearchLive, id: "search-modal")}
    """
  end
end
