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
  the submit button or marks the entry as "published".
  """
  use GlossaryWeb, :live_view

  require Logger

  import GlossaryWeb.KeybindMacros

  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @impl true
  def mount(%{"entry_id" => entry_id}, _session, socket) do
    # TODO: show error flash if Ecto has trouble loading the entry

    entry = Repo.get(Entry, entry_id)
    {:ok, assign(socket, leader_down: false, shift_down: false, entry: entry)}
  end

  pubsub_broadcast_on_event("summon_modal", :summon_modal, true, "search_modal")
  pubsub_broadcast_on_event("banish_modal", :summon_modal, false, "search_modal")

  keybind_listeners()

  @impl true
  def handle_event("title_update", %{"title" => title}, socket) do
    # TODO: support marking as draft (or autosaving as a draft after title is updated)

    {:ok, _} =
      Entry.changeset(socket.assigns.entry, %{title: title})
      |> Repo.update()

    {:noreply, socket}
  end

  def handle_event("description_update", %{"description" => description}, socket) do
    {:ok, _} =
      Entry.changeset(socket.assigns.entry, %{description: description})
      |> Repo.update()

    {:noreply, socket}
  end

  def handle_event("body_update", %{"body" => body}, socket) do
    {:ok, _} =
      Entry.changeset(socket.assigns.entry, %{body: body})
      |> Repo.update()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- TODO: "saving" and "saved" indicators --%>
    <Layouts.app flash={@flash}>
      <div
        id="edit-entry-container"
        phx-window-keydown="key_down"
        phx-window-keyup="key_up"
        class="flex h-full flex-col py-8"
      >
        <.title_section entry={@entry} />

        <div class="divider px-3"></div>

        <section class="h-full">
          <%!-- TODO: body input section --%>
          <%!--       support headers, code/quote blocks, font styles, etc. --%>

          <div
            id="body-editor"
            phx-hook="BodyEditor"
          >
            <input
              id="entry_body"
              type="hidden"
              name="entry[body]"
              value={@entry.body}
            />
          </div>
        </section>
      </div>
    </Layouts.app>

    {live_render(@socket, GlossaryWeb.SearchLive, id: "search-modal")}
    """
  end

  defp title_section(assigns) do
    ~H"""
    <header>
      <div
        id="title-editor"
        phx-hook="TitleEditor"
      >
        <input
          id="entry_title"
          type="hidden"
          name="entry[title]"
          value={assigns.entry.title}
        />
      </div>

      <div
        id="description-editor"
        phx-hook="DescriptionEditor"
      >
        <input
          id="entry_description"
          type="hidden"
          name="entry[description]"
          value={assigns.entry.description}
        />
      </div>

      <div class="text-base-content/50 flex gap-2 px-3 py-2 text-sm font-medium">
        <%!-- TODO: @tags and #topics line, similar to Linear's --%>
        <%!--       no autosave here, update on blur or keybind  --%>
        <span><i>@tags</i></span>
        <span><i>#topics</i></span>
      </div>
    </header>
    """
  end
end
