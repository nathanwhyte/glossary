defmodule GlossaryWeb.TagLive.Show do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Projects
  alias Glossary.Tags

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tag = Tags.get_tag!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, tag.name)
     |> assign(:tag, tag)
     |> assign(:entry_search_query, "")
     |> assign(:available_entries, [])
     |> assign(:show_entry_picker?, false)
     |> assign(:project_search_query, "")
     |> assign(:available_projects, [])
     |> assign(:show_project_picker?, false)
     |> stream(:tag_entries, tag.entries)
     |> stream(:tag_projects, tag.projects)}
  end

  @impl true
  def handle_event("show_entry_picker", _params, socket) do
    available = Tags.available_entries(socket.assigns.current_scope, socket.assigns.tag)

    {:noreply,
     socket
     |> assign(:show_entry_picker?, true)
     |> assign(:available_entries, available)
     |> assign(:entry_search_query, "")}
  end

  @impl true
  def handle_event("hide_entry_picker", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_entry_picker?, false)
     |> assign(:available_entries, [])
     |> assign(:entry_search_query, "")}
  end

  @impl true
  def handle_event("search_entries", %{"query" => query}, socket) do
    available = Tags.available_entries(socket.assigns.current_scope, socket.assigns.tag, query)

    {:noreply,
     socket
     |> assign(:entry_search_query, query)
     |> assign(:available_entries, available)}
  end

  @impl true
  def handle_event("add_entry", %{"id" => entry_id}, socket) do
    entry = Entries.get_entry!(socket.assigns.current_scope, entry_id)
    {:ok, tag} = Tags.add_entry(socket.assigns.current_scope, socket.assigns.tag, entry)

    available =
      Tags.available_entries(
        socket.assigns.current_scope,
        tag,
        socket.assigns.entry_search_query
      )

    {:noreply,
     socket
     |> assign(:tag, tag)
     |> assign(:available_entries, available)
     |> stream_insert(:tag_entries, entry)}
  end

  @impl true
  def handle_event("remove_entry", %{"id" => entry_id}, socket) do
    entry = Entries.get_entry!(socket.assigns.current_scope, entry_id)
    {:ok, tag} = Tags.remove_entry(socket.assigns.current_scope, socket.assigns.tag, entry)

    available =
      if socket.assigns.show_entry_picker? do
        Tags.available_entries(
          socket.assigns.current_scope,
          tag,
          socket.assigns.entry_search_query
        )
      else
        []
      end

    {:noreply,
     socket
     |> assign(:tag, tag)
     |> assign(:available_entries, available)
     |> stream_delete(:tag_entries, entry)}
  end

  @impl true
  def handle_event("show_project_picker", _params, socket) do
    available = Tags.available_projects(socket.assigns.current_scope, socket.assigns.tag)

    {:noreply,
     socket
     |> assign(:show_project_picker?, true)
     |> assign(:available_projects, available)
     |> assign(:project_search_query, "")}
  end

  @impl true
  def handle_event("hide_project_picker", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_project_picker?, false)
     |> assign(:available_projects, [])
     |> assign(:project_search_query, "")}
  end

  @impl true
  def handle_event("search_projects", %{"query" => query}, socket) do
    available = Tags.available_projects(socket.assigns.current_scope, socket.assigns.tag, query)

    {:noreply,
     socket
     |> assign(:project_search_query, query)
     |> assign(:available_projects, available)}
  end

  @impl true
  def handle_event("add_project", %{"id" => project_id}, socket) do
    project = Projects.get_project!(socket.assigns.current_scope, project_id)
    {:ok, tag} = Tags.add_project(socket.assigns.current_scope, socket.assigns.tag, project)

    available =
      Tags.available_projects(
        socket.assigns.current_scope,
        tag,
        socket.assigns.project_search_query
      )

    {:noreply,
     socket
     |> assign(:tag, tag)
     |> assign(:available_projects, available)
     |> stream_insert(:tag_projects, project)}
  end

  @impl true
  def handle_event("remove_project", %{"id" => project_id}, socket) do
    project = Projects.get_project!(socket.assigns.current_scope, project_id)
    {:ok, tag} = Tags.remove_project(socket.assigns.current_scope, socket.assigns.tag, project)

    available =
      if socket.assigns.show_project_picker? do
        Tags.available_projects(
          socket.assigns.current_scope,
          tag,
          socket.assigns.project_search_query
        )
      else
        []
      end

    {:noreply,
     socket
     |> assign(:tag, tag)
     |> assign(:available_projects, available)
     |> stream_delete(:tag_projects, project)}
  end

  @impl true
  def handle_info({:search_modal_action, level, message}, socket) do
    tag = Tags.get_tag!(socket.assigns.current_scope, socket.assigns.tag.id)

    {:noreply,
     socket
     |> put_flash(level, message)
     |> assign(:tag, tag)
     |> stream(:tag_entries, tag.entries, reset: true)
     |> stream(:tag_projects, tag.projects, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
        current_scope={@current_scope}
        context={%{page: :tag_show, tag: @tag}}
      />

      <LiveLayouts.back_link navigate={~p"/tags"} text="Back to Tags" />

      <div class="space-y-6">
        <.header>
          {@tag.name}
          <:actions>
            <.button variant="primary" navigate={~p"/tags/#{@tag}/edit"}>
              <.icon name="hero-pencil-square" /> Edit
            </.button>
          </:actions>
        </.header>

        <%!-- Entries section --%>
        <section class="space-y-2">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Entries</h2>
            <.button
              :if={!@show_entry_picker?}
              id="show-entry-picker-button"
              phx-click="show_entry_picker"
            >
              <.icon name="hero-plus" /> Add Entry
            </.button>
          </div>

          <div
            :if={@show_entry_picker?}
            id="entry-picker"
            class="border-base-300 bg-base-100 space-y-3 rounded-lg border p-4"
          >
            <div class="flex items-center justify-between">
              <h3 class="font-medium">Add entries to this tag</h3>
              <button
                id="hide-entry-picker-button"
                phx-click="hide_entry_picker"
                type="button"
                class="btn btn-ghost btn-sm"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </div>

            <.form for={%{}} id="entry-search-form" phx-change="search_entries" class="w-full">
              <.input
                id="entry-search-input"
                type="text"
                name="query"
                placeholder="Search entries..."
                autocomplete="off"
                value={@entry_search_query}
                phx-debounce="150"
                class="w-full"
              />
            </.form>

            <div class="max-h-60 space-y-1 overflow-y-auto">
              <div
                :if={@available_entries == []}
                class="text-base-content/50 py-4 text-center text-sm"
              >
                No available entries found.
              </div>
              <button
                :for={entry <- @available_entries}
                id={"available-entry-#{entry.id}"}
                phx-click="add_entry"
                phx-value-id={entry.id}
                type="button"
                class="flex w-full items-center gap-2 rounded-lg p-2 text-left hover:bg-base-200"
              >
                <.icon name="hero-plus-circle" class="size-5 text-success shrink-0" />
                <div>
                  <div class="font-medium">
                    <%= if entry.title_text && entry.title_text != "" do %>
                      {entry.title_text}
                    <% else %>
                      <em class="text-base-content/25 italic">No Title</em>
                    <% end %>
                  </div>
                  <div
                    :if={entry.subtitle_text && entry.subtitle_text != ""}
                    class="text-base-content/50 text-sm"
                  >
                    {entry.subtitle_text}
                  </div>
                </div>
              </button>
            </div>
          </div>

          <.table id="tag-entries" rows={@streams.tag_entries}>
            <:col :let={{_id, entry}} label="Title">
              <%= if !entry.title_text || entry.title_text == "" do %>
                <em class="text-base-content/25 italic">No Title</em>
              <% else %>
                <span class="font-semibold">{entry.title_text}</span>
              <% end %>
            </:col>
            <:col :let={{_id, entry}} label="Subtitle">
              <%= if !entry.subtitle_text || entry.subtitle_text == "" do %>
                <em class="text-base-content/25 italic">No Subtitle</em>
              <% else %>
                <span class="text-base-content/50 text-sm">{entry.subtitle_text}</span>
              <% end %>
            </:col>
            <:action :let={{_id, entry}}>
              <.link
                href="#"
                phx-click="remove_entry"
                phx-value-id={entry.id}
                data-confirm="Remove this entry from the tag?"
              >
                Remove
              </.link>
            </:action>
            <:action :let={{_id, entry}}>
              <.link navigate={~p"/entries/#{entry}"}>View</.link>
            </:action>
          </.table>
        </section>

        <%!-- Projects section --%>
        <section class="space-y-2">
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold">Projects</h2>
            <.button
              :if={!@show_project_picker?}
              id="show-project-picker-button"
              phx-click="show_project_picker"
            >
              <.icon name="hero-plus" /> Add Project
            </.button>
          </div>

          <div
            :if={@show_project_picker?}
            id="project-picker"
            class="border-base-300 bg-base-100 space-y-3 rounded-lg border p-4"
          >
            <div class="flex items-center justify-between">
              <h3 class="font-medium">Add projects to this tag</h3>
              <button
                id="hide-project-picker-button"
                phx-click="hide_project_picker"
                type="button"
                class="btn btn-ghost btn-sm"
              >
                <.icon name="hero-x-mark" class="size-4" />
              </button>
            </div>

            <.form
              for={%{}}
              id="project-search-form"
              phx-change="search_projects"
              class="w-full"
            >
              <.input
                id="project-search-input"
                type="text"
                name="query"
                placeholder="Search projects..."
                autocomplete="off"
                value={@project_search_query}
                phx-debounce="150"
                class="w-full"
              />
            </.form>

            <div class="max-h-60 space-y-1 overflow-y-auto">
              <div
                :if={@available_projects == []}
                class="text-base-content/50 py-4 text-center text-sm"
              >
                No available projects found.
              </div>
              <button
                :for={project <- @available_projects}
                id={"available-project-#{project.id}"}
                phx-click="add_project"
                phx-value-id={project.id}
                type="button"
                class="flex w-full items-center gap-2 rounded-lg p-2 text-left hover:bg-base-200"
              >
                <.icon name="hero-plus-circle" class="size-5 text-success shrink-0" />
                <span class="font-medium">{project.name}</span>
              </button>
            </div>
          </div>

          <.table id="tag-projects" rows={@streams.tag_projects}>
            <:col :let={{_id, project}} label="Name">
              <span class="font-semibold">{project.name}</span>
            </:col>
            <:action :let={{_id, project}}>
              <.link
                href="#"
                phx-click="remove_project"
                phx-value-id={project.id}
                data-confirm="Remove this project from the tag?"
              >
                Remove
              </.link>
            </:action>
            <:action :let={{_id, project}}>
              <.link navigate={~p"/projects/#{project}"}>View</.link>
            </:action>
          </.table>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
