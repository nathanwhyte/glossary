defmodule GlossaryWeb.EntryLive.Edit do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias Glossary.Entries.Entry
  alias Glossary.Projects
  alias Glossary.Tags
  alias Glossary.Topics

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

    user_id = socket.assigns.current_scope.user.id

    Phoenix.PubSub.broadcast(
      Glossary.PubSub,
      "user_entries:#{user_id}",
      {:entry_updated, entry.id}
    )

    {:noreply,
     socket
     |> assign(:entry, entry)
     |> load_available_projects(socket.assigns.project_filter)}
  end

  @impl true
  def handle_event("set_status", %{"status" => status}, socket) do
    case Entries.update_entry(socket.assigns.current_scope, socket.assigns.entry, %{
           status: status
         }) do
      {:ok, entry} ->
        user_id = socket.assigns.current_scope.user.id

        Phoenix.PubSub.broadcast(
          Glossary.PubSub,
          "user_entries:#{user_id}",
          {:entry_updated, entry.id}
        )

        {:noreply, assign(socket, :entry, entry)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_topic", %{"id" => topic_id}, socket) do
    entry = socket.assigns.entry
    topic = Topics.get_topic!(socket.assigns.current_scope, topic_id)
    already_associated = Enum.any?(entry.topics, &(&1.id == topic.id))

    {:ok, entry} =
      if already_associated do
        Entries.remove_topic(socket.assigns.current_scope, entry, topic)
      else
        Entries.add_topic(socket.assigns.current_scope, entry, topic)
      end

    user_id = socket.assigns.current_scope.user.id

    Phoenix.PubSub.broadcast(
      Glossary.PubSub,
      "user_entries:#{user_id}",
      {:entry_updated, entry.id}
    )

    {:noreply,
     socket
     |> assign(:entry, entry)
     |> load_available_topics(socket.assigns.topic_filter)}
  end

  @impl true
  def handle_event("search_topics", %{"query" => query}, socket) do
    {:noreply, load_available_topics(socket, query)}
  end

  @impl true
  def handle_event("create_topic", _params, socket) do
    name = String.trim(socket.assigns.topic_filter)

    with true <- name != "",
         {:ok, topic} <- Topics.create_topic(socket.assigns.current_scope, %{name: name}),
         {:ok, entry} <-
           Entries.add_topic(socket.assigns.current_scope, socket.assigns.entry, topic) do
      {:noreply,
       socket
       |> assign(:entry, entry)
       |> load_available_topics()}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_tag", %{"id" => tag_id}, socket) do
    entry = socket.assigns.entry
    tag = Tags.get_tag!(socket.assigns.current_scope, tag_id)
    already_associated = Enum.any?(entry.tags, &(&1.id == tag.id))

    {:ok, entry} =
      if already_associated do
        Entries.remove_tag(socket.assigns.current_scope, entry, tag)
      else
        Entries.add_tag(socket.assigns.current_scope, entry, tag)
      end

    user_id = socket.assigns.current_scope.user.id

    Phoenix.PubSub.broadcast(
      Glossary.PubSub,
      "user_entries:#{user_id}",
      {:entry_updated, entry.id}
    )

    {:noreply,
     socket
     |> assign(:entry, entry)
     |> load_available_tags(socket.assigns.tag_filter)}
  end

  @impl true
  def handle_event("search_tags", %{"query" => query}, socket) do
    {:noreply, load_available_tags(socket, query)}
  end

  @impl true
  def handle_event("create_tag", _params, socket) do
    name = String.trim(socket.assigns.tag_filter)

    with true <- name != "",
         {:ok, tag} <- Tags.create_tag(socket.assigns.current_scope, %{name: name}),
         {:ok, entry} <-
           Entries.add_tag(socket.assigns.current_scope, socket.assigns.entry, tag) do
      {:noreply,
       socket
       |> assign(:entry, entry)
       |> load_available_tags()}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search_projects", %{"query" => query}, socket) do
    {:noreply, load_available_projects(socket, query)}
  end

  @impl true
  def handle_event("create_project", _params, socket) do
    name = String.trim(socket.assigns.project_filter)

    with true <- name != "",
         {:ok, project} <- Projects.create_project(socket.assigns.current_scope, %{name: name}),
         {:ok, entry} <-
           Entries.add_project(socket.assigns.current_scope, socket.assigns.entry, project) do
      {:noreply,
       socket
       |> assign(:entry, entry)
       |> load_available_projects()}
    else
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("regenerate_ai", _params, socket) do
    entry = socket.assigns.entry
    Glossary.AI.generate_entry_ai(entry)
    {:noreply, assign(socket, :ai_loading, true)}
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Entries.delete_entry(socket.assigns.current_scope, socket.assigns.entry)
    {:noreply, push_navigate(socket, to: ~p"/entries")}
  end

  defp save_field(socket, attrs) do
    entry = socket.assigns.entry

    case Entries.upsert_entry(socket.assigns.current_scope, entry, attrs) do
      {:ok, entry} ->
        if socket.assigns.broadcast_timer,
          do: Process.cancel_timer(socket.assigns.broadcast_timer)

        timer = Process.send_after(self(), {:broadcast_entry_updated, entry.id}, 5_000)

        socket
        |> assign(:entry, entry)
        |> assign(:broadcast_timer, timer)
        |> maybe_generate_ai(entry)

      {:error, _changeset} ->
        socket
    end
  end

  defp maybe_generate_ai(socket, entry) do
    if is_nil(entry.summary) and entry.body_text != nil and String.trim(entry.body_text) != "" do
      Glossary.AI.generate_entry_ai(entry)
    end

    socket
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
            class="flex-1"
          >
            <div data-editor="title" id="entry-title" phx-update="ignore" class="title-editor" />
          </div>

          <div class="shrink-0">
            <details id="entry-actions" class="dropdown dropdown-end">
              <summary class="btn btn-ghost btn-sm btn-square list-none">
                <.icon name="hero-ellipsis-vertical-micro" class="size-6 text-base-content/50" />
              </summary>
              <ul class="dropdown-content menu bg-base-200 border-base-300 rounded-box z-10 mt-1 border p-2 shadow shadow-xl">
                <li>
                  <button
                    phx-click={
                      JS.push("regenerate_ai")
                      |> JS.remove_attribute("open", to: "#entry-actions")
                    }
                    type="button"
                    disabled={@ai_loading}
                    class="text-nowrap"
                  >
                    <.icon name="hero-sparkles" class="size-4" />
                    {if @ai_loading, do: "Generating...", else: "Regenerate Summary & Tags"}
                  </button>
                </li>
                <li :if={@live_action == :edit}>
                  <button
                    phx-click="delete"
                    data-confirm="Are you sure you want to delete this entry?"
                    type="button"
                    class="text-nowrap text-error"
                  >
                    <.icon name="hero-trash" class="size-4" />
                    Delete Entry
                  </button>
                </li>
              </ul>
            </details>
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

      <div class="flex items-end gap-6">
        <div class="flex items-center gap-2 text-center">
          <div class="text-xs font-medium">Status</div>
          <details id="status-dropdown" class="dropdown dropdown-bottom">
            <summary class={[
              "badge badge-sm -mt-1 cursor-pointer list-none",
              GlossaryWeb.Mappings.map_entry_status_to_badge_color(@entry.status)
            ]}>
              {@entry.status |> to_string() |> String.capitalize()}
              <.icon name="hero-chevron-down-micro" class="size-3.5 -mr-1 -ml-0.5" />
            </summary>
            <ul class="dropdown-content menu bg-base-200 border-base-300 rounded-box z-10 mt-1 w-36 space-y-1 border p-2 shadow shadow-xl">
              <li :for={status <- Entries.entry_statuses()}>
                <button
                  phx-click={
                    JS.push("set_status", value: %{status: status})
                    |> JS.remove_attribute("open", to: "#status-dropdown")
                  }
                  type="button"
                  class={if @entry.status == status, do: "bg-base-300", else: "hover:bg-base-100"}
                >
                  {status |> to_string() |> String.capitalize()}
                </button>
              </li>
            </ul>
          </details>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs">Projects</span>
          <div :for={project <- @entry.projects} class="badge badge-accent badge-sm">
            {project.name}
          </div>
          <div class="dropdown dropdown-left">
            <div
              tabindex="0"
              role="button"
              class="cursor-pointer"
              phx-click="search_projects"
              phx-value-query=""
            >
              <.icon name="hero-plus-micro" class="size-4 text-base-content/50 -mt-1" />
            </div>
            <div
              tabindex="0"
              class="dropdown-content bg-base-200 border-base-300 rounded-box z-10 ml-2 w-52 border p-2 shadow shadow-xl"
            >
              <form phx-change="search_projects" phx-submit="create_project">
                <input
                  id="project-filter-input"
                  type="text"
                  name="query"
                  value={@project_filter}
                  placeholder="Search..."
                  autocomplete="off"
                  phx-debounce="100"
                  class="size-full text-base-content/75 px-2 pt-1 pb-2 text-sm focus:outline-none"
                />
              </form>
              <ul class="menu gap-0 p-0">
                <li :for={project <- @entry.projects}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
                      checked
                      phx-click="toggle_project"
                      phx-value-id={project.id}
                    />
                    <span>{project.name}</span>
                  </label>
                </li>
                <li :if={
                  @available_projects == [] and @entry.projects == [] and @project_filter == ""
                }>
                  <span class="text-base-content/50 px-2 text-sm italic">No projects yet</span>
                </li>
                <li :if={@available_projects == [] and @project_filter != ""}>
                  <button
                    phx-click="create_project"
                    type="button"
                    class="text-primary flex items-center gap-2"
                  >
                    <.icon name="hero-plus" class="size-4 shrink-0" />
                    <span>Create "{@project_filter}"</span>
                  </button>
                </li>
                <li :for={project <- @available_projects}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
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

        <div class="flex items-center gap-2">
          <span class="text-xs">Topics</span>
          <div :for={topic <- @entry.topics} class="badge badge-info badge-sm">
            #{topic.name}
          </div>
          <div class="dropdown dropdown-left">
            <div
              tabindex="0"
              role="button"
              class="cursor-pointer"
              phx-click="search_topics"
              phx-value-query=""
            >
              <.icon name="hero-plus-micro" class="size-4 text-base-content/50 -mt-1" />
            </div>
            <div
              tabindex="0"
              class="dropdown-content bg-base-200 border-base-300 rounded-box z-10 ml-2 w-52 border p-2 shadow shadow-xl"
            >
              <form phx-change="search_topics" phx-submit="create_topic">
                <input
                  id="topic-filter-input"
                  type="text"
                  name="query"
                  value={@topic_filter}
                  placeholder="Search..."
                  autocomplete="off"
                  phx-debounce="100"
                  class="size-full text-base-content/75 px-2 pt-1 pb-2 text-sm focus:outline-none"
                />
              </form>
              <ul class="menu gap-0 p-0">
                <li :for={topic <- @entry.topics}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
                      checked
                      phx-click="toggle_topic"
                      phx-value-id={topic.id}
                    />
                    <span>{topic.name}</span>
                  </label>
                </li>
                <li :if={@available_topics == [] and @entry.topics == [] and @topic_filter == ""}>
                  <span class="text-base-content/50 px-2 text-sm italic">No topics yet</span>
                </li>
                <li :if={@available_topics == [] and @topic_filter != ""}>
                  <button
                    phx-click="create_topic"
                    type="button"
                    class="text-primary flex items-center gap-2"
                  >
                    <.icon name="hero-plus" class="size-4 shrink-0" />
                    <span>Create "{@topic_filter}"</span>
                  </button>
                </li>
                <li :for={topic <- @available_topics}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
                      phx-click="toggle_topic"
                      phx-value-id={topic.id}
                    />
                    <span>{topic.name}</span>
                  </label>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <span class="text-xs">Tags</span>
          <div :for={tag <- @entry.tags} class="badge badge-secondary badge-sm">
            @{tag.name}
          </div>
          <div class="dropdown dropdown-left">
            <div
              tabindex="0"
              role="button"
              class="cursor-pointer"
              phx-click="search_tags"
              phx-value-query=""
            >
              <.icon name="hero-plus-micro" class="size-4 text-base-content/50 -mt-1" />
            </div>
            <div
              tabindex="0"
              class="dropdown-content bg-base-200 border-base-300 rounded-box z-10 ml-2 w-52 border p-2 shadow shadow-xl"
            >
              <form phx-change="search_tags" phx-submit="create_tag">
                <input
                  id="tag-filter-input"
                  type="text"
                  name="query"
                  value={@tag_filter}
                  placeholder="Search..."
                  autocomplete="off"
                  phx-debounce="100"
                  class="size-full text-base-content/75 px-2 pt-1 pb-2 text-sm focus:outline-none"
                />
              </form>
              <ul class="menu gap-0 p-0">
                <li :for={tag <- @entry.tags}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
                      checked
                      phx-click="toggle_tag"
                      phx-value-id={tag.id}
                    />
                    <span>{tag.name}</span>
                  </label>
                </li>
                <li :if={@available_tags == [] and @entry.tags == [] and @tag_filter == ""}>
                  <span class="text-base-content/50 px-2 text-sm italic">No tags yet</span>
                </li>
                <li :if={@available_tags == [] and @tag_filter != ""}>
                  <button
                    phx-click="create_tag"
                    type="button"
                    class="text-primary flex items-center gap-2"
                  >
                    <.icon name="hero-plus" class="size-4 shrink-0" />
                    <span>Create "{@tag_filter}"</span>
                  </button>
                </li>
                <li :for={tag <- @available_tags}>
                  <label class="flex cursor-pointer items-center gap-2 p-2">
                    <input
                      type="checkbox"
                      class="checkbox checkbox-sm"
                      phx-click="toggle_tag"
                      phx-value-id={tag.id}
                    />
                    <span>{tag.name}</span>
                  </label>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div
        :if={@entry.summary || @entry.ai_tags != []}
        class="bg-base-200/50 mt-4 rounded-lg p-4"
      >
        <div class="text-base-content/70 mb-2 flex items-center gap-2 text-sm font-medium">
          <.icon name="hero-sparkles" class="size-4" /> AI Generated
        </div>
        <p :if={@entry.summary} class="text-base-content/80 text-sm">{@entry.summary}</p>
        <div :if={@entry.ai_tags != []} class="mt-2 flex flex-wrap gap-1">
          <span :for={tag <- @entry.ai_tags} class="badge badge-ghost badge-sm">{tag}</span>
        </div>
      </div>

      <div
        :if={@ai_loading}
        class="text-base-content/50 mt-4 flex items-center gap-2 text-sm"
      >
        <span class="loading loading-spinner loading-xs"></span> Generating summary and tags...
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
  def handle_info({:broadcast_entry_updated, entry_id}, socket) do
    user_id = socket.assigns.current_scope.user.id

    Phoenix.PubSub.broadcast(
      Glossary.PubSub,
      "user_entries:#{user_id}",
      {:entry_updated, entry_id}
    )

    {:noreply, assign(socket, :broadcast_timer, nil)}
  end

  @impl true
  def handle_info({:ai_generated, entry_id}, socket) do
    if socket.assigns.entry.id == entry_id do
      entry = Entries.get_entry_all!(socket.assigns.current_scope, entry_id)
      {:noreply, socket |> assign(:entry, entry) |> assign(:ai_loading, false)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:ai_error, _entry_id, _reason}, socket) do
    {:noreply,
     socket
     |> assign(:ai_loading, false)
     |> put_flash(:error, "AI generation failed. You can try again manually.")}
  end

  @impl true
  def handle_info({:search_modal_action, level, message}, socket) do
    {:noreply, put_flash(socket, level, message)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    entry = Entries.get_entry_all!(socket.assigns.current_scope, id)

    socket
    |> assign(:page_title, "Edit Entry")
    |> assign(:entry, entry)
    |> assign_picker_defaults()
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Entry")
    |> assign(:entry, %Entry{projects: [], tags: [], topics: []})
    |> assign_picker_defaults()
  end

  defp assign_picker_defaults(socket) do
    socket
    |> assign(:project_filter, "")
    |> assign(:available_projects, [])
    |> assign(:tag_filter, "")
    |> assign(:available_tags, [])
    |> assign(:topic_filter, "")
    |> assign(:available_topics, [])
    |> assign(:broadcast_timer, nil)
    |> assign(:ai_loading, false)
  end

  defp load_available_projects(socket, query \\ "") do
    available =
      Entries.available_projects(socket.assigns.current_scope, socket.assigns.entry, query)

    assign(socket, available_projects: available, project_filter: query)
  end

  defp load_available_tags(socket, query \\ "") do
    available = Entries.available_tags(socket.assigns.current_scope, socket.assigns.entry, query)
    assign(socket, available_tags: available, tag_filter: query)
  end

  defp load_available_topics(socket, query \\ "") do
    available =
      Entries.available_topics(socket.assigns.current_scope, socket.assigns.entry, query)

    assign(socket, available_topics: available, topic_filter: query)
  end
end
