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

  on_mount {GlossaryWeb.UserAuthHooks, :ensure_authenticated}

  import GlossaryWeb.KeybindMacros
  import GlossaryWeb.Components.EntryComponents

  alias Glossary.{Entries, Entries.Entry}
  alias Glossary.Projects
  alias Glossary.Repo

  require Logger

  @impl true
  def mount(%{"entry_id" => entry_id}, _session, socket) do
    # TODO: show error flash if Ecto has trouble loading the entry

    entry = Entries.get_entry_details(entry_id)
    recent_projects = Projects.list_recent_projects(5)

    {:ok,
     assign(socket,
       leader_down: false,
       shift_down: false,
       entry: entry,
       recent_projects: recent_projects
     )}
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
    Entry.changeset(socket.assigns.entry, %{body: body})
    |> Repo.update()
    |> case do
      {:ok, updated_entry} ->
        {:noreply, assign(socket, :entry, updated_entry)}

      {:error, changeset} ->
        Logger.error("Failed to update entry body: #{inspect(changeset.errors)}")
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("change_project", %{"project_id" => project_id}, socket) do
    project_id = if project_id == "", do: nil, else: project_id
    Logger.info("Changing #{inspect(socket.assigns.entry)} to ID: #{project_id}")

    {:ok, _} =
      Entry.changeset(socket.assigns.entry, %{project_id: project_id})
      |> Repo.update()

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- TODO: "saving" and "saved" indicators --%>
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div
        id="edit-entry-container"
        phx-window-keydown="key_down"
        phx-window-keyup="key_up"
        class="flex h-full flex-col py-8"
      >
        <.title_section entry={@entry} recent_projects={@recent_projects} />

        <div class="divider px-3"></div>

        <section class="h-full">
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

  attr :entry, Entry, required: true, doc: "the entry being edited"
  attr :recent_projects, :list, required: true, doc: "list of recent projects for selection"

  defp title_section(assigns) do
    ~H"""
    <header>
      <div class="flex px-3 py-2">
        <div
          id="title-editor"
          phx-hook="TitleEditor"
          class="flex-1"
        >
          <input
            id="entry_title"
            type="hidden"
            name="entry[title]"
            value={assigns.entry.title}
          />
        </div>

        <%!-- TODO: options/actions menu, e.g. "mark as draft/published" --%>
        <.icon name="hero-ellipsis-horizontal-mini" class="size-6 mt-2 mr-1" />
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

      <div class="text-base-content/50 flex gap-4 px-3 py-2 text-sm font-medium">
        <.status_indicator status={assigns.entry.status} />
        <.project_select
          project={assigns.entry.project}
          entry_id={assigns.entry.id}
          recent_projects={assigns.recent_projects}
        />
        <.tag_badges tags={assigns.entry.tags} />
        <.topic_badges topics={assigns.entry.topics} />
      </div>
    </header>
    """
  end
end
