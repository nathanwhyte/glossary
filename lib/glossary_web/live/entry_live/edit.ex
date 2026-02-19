defmodule GlossaryWeb.EntryLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Entries.Entry
  alias Glossary.Projects

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("title_update", %{"title" => title, "title_text" => title_text}, socket) do
    {:noreply, save_field(socket, %{title: title, title_text: title_text})}
  end

  @impl true
  def handle_event(
        "subtitle_update",
        %{"subtitle" => subtitle, "subtitle_text" => subtitle_text},
        socket
      ) do
    {:noreply, save_field(socket, %{subtitle: subtitle, subtitle_text: subtitle_text})}
  end

  @impl true
  def handle_event("body_update", %{"body" => body, "body_text" => body_text}, socket) do
    {:noreply, save_field(socket, %{body: body, body_text: body_text})}
  end

  @impl true
  def handle_event("toggle_project", %{"id" => project_id}, socket) do
    entry = socket.assigns.entry
    project = Projects.get_project!(socket.assigns.current_scope, project_id)
    already_associated = Enum.any?(entry.projects, &(&1.id == project.id))

    {:ok, entry} =
      if already_associated do
        Entries.remove_project(socket.assigns.current_scope, entry, project)
      else
        Entries.add_project(socket.assigns.current_scope, entry, project)
      end

    {:noreply, assign(socket, :entry, entry)}
  end

  @impl true
  def handle_event("filter_projects", %{"query" => query}, socket) do
    filtered = filter_projects(socket.assigns.all_projects, query)
    {:noreply, assign(socket, project_filter: query, filtered_projects: filtered)}
  end

  @impl true
  def handle_event("create_project", _params, socket) do
    name = String.trim(socket.assigns.project_filter)

    with true <- name != "",
         {:ok, project} <- Projects.create_project(socket.assigns.current_scope, %{name: name}),
         {:ok, entry} <-
           Entries.add_project(socket.assigns.current_scope, socket.assigns.entry, project) do
      all_projects = Projects.list_projects(socket.assigns.current_scope)

      {:noreply,
       assign(socket,
         entry: entry,
         all_projects: all_projects,
         filtered_projects: all_projects,
         project_filter: ""
       )}
    else
      _ -> {:noreply, socket}
    end
  end

  defp save_field(socket, attrs) do
    entry = socket.assigns.entry

    case Entries.upsert_entry(socket.assigns.current_scope, entry, attrs) do
      {:ok, entry} -> assign(socket, :entry, entry)
      {:error, _changeset} -> socket
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.live_component
        module={GlossaryWeb.SearchModal}
        id="global-search-modal"
        current_scope={@current_scope}
        context={%{page: :entry_edit, entry: @entry}}
      />

      <div>
        <LiveLayouts.back_link navigate={~p"/entries"} text="Back to Entries" />

        <div class="mt-4 flex items-center justify-between">
          <div
            id="title-editor"
            phx-hook="TitleEditor"
            data-value={@entry.title}
          >
            <div data-editor="title" id="entry-title" phx-update="ignore" class="title-editor" />
          </div>

          <%!-- IDEA: entry actions menu --%>
          <div>
            <.icon name="hero-ellipsis-vertical-micro" class="size-6 text-base-content/50" />
          </div>
        </div>

        <div
          id="subtitle-editor"
          phx-hook="SubtitleEditor"
          data-value={@entry.subtitle}
          class="mt-1"
        >
          <div data-editor="subtitle" id="entry-subtitle" phx-update="ignore" class="subtitle-editor" />
        </div>
      </div>

      <div class="flex items-center gap-6">
        <div class="join">
          <div class="badge badge-ghost badge-sm join-item">
            Status
          </div>
          <div class="badge badge-warning badge-sm join-item">
            {@entry.status |> to_string() |> String.capitalize()}
            <.icon name="hero-chevron-up-down-micro" class="size-4 -mr-1 -ml-0.5" />
          </div>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs">Projects</span>
          <div :for={project <- @entry.projects} class="badge badge-accent badge-sm">
            {project.name}
          </div>
          <div class="dropdown dropdown-left">
            <div tabindex="0" role="button" class="cursor-pointer">
              <.icon name="hero-plus-micro" class="size-4 text-base-content/50" />
            </div>
            <div
              tabindex="0"
              class="dropdown-content bg-base-200 border-base-300 rounded-box z-10 w-52 border p-2 shadow shadow-xl"
            >
              <form phx-change="filter_projects" phx-submit="create_project">
                <input
                  id="project-filter-input"
                  type="text"
                  name="query"
                  value={@project_filter}
                  placeholder="Search..."
                  autocomplete="off"
                  phx-debounce="100"
                  phx-mounted={JS.focus()}
                  class="size-full text-base-content/75 px-2 pt-1 pb-2 text-sm focus:outline-none"
                />
              </form>
              <ul class="menu gap-0 p-0">
                <li :if={@filtered_projects == [] and @project_filter == ""}>
                  <span class="text-base-content/50 px-2 text-sm italic">No projects yet</span>
                </li>
                <li :if={@filtered_projects == [] and @project_filter != ""}>
                  <button
                    phx-click="create_project"
                    type="button"
                    class="text-primary flex items-center gap-2"
                  >
                    <.icon name="hero-plus" class="size-4 shrink-0" />
                    <span>Create "{@project_filter}"</span>
                  </button>
                </li>
                <li :for={project <- @filtered_projects}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
                      checked={Enum.any?(@entry.projects, &(&1.id == project.id))}
                      phx-click="toggle_project"
                      phx-value-id={project.id}
                    />
                    <span>{project.name}</span>
                  </label>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div class="divider" />

      <div class="mt-4">
        <div
          id="body-editor"
          phx-hook="BodyEditor"
          data-value={@entry.body}
          class="mt-2"
        >
          <div data-editor="body" id="entry-body" phx-update="ignore" class="body-editor" />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_info({:search_modal_action, level, message}, socket) do
    {:noreply, put_flash(socket, level, message)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    entry = Entries.get_entry_all!(socket.assigns.current_scope, id)
    all_projects = Projects.list_projects(socket.assigns.current_scope)

    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, entry)
    |> assign(:all_projects, all_projects)
    |> assign(:project_filter, "")
    |> assign(:filtered_projects, all_projects)
  end

  defp apply_action(socket, :new, _params) do
    all_projects = Projects.list_projects(socket.assigns.current_scope)

    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, %Entry{projects: []})
    |> assign(:all_projects, all_projects)
    |> assign(:project_filter, "")
    |> assign(:filtered_projects, all_projects)
  end

  defp filter_projects(projects, ""), do: projects

  defp filter_projects(projects, query) do
    q = String.downcase(query)
    Enum.filter(projects, &String.contains?(String.downcase(&1.name), q))
  end
end
