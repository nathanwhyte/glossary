defmodule GlossaryWeb.SearchModal do
  use GlossaryWeb, :live_component

  @moduledoc """
  Live component for global search and keyboard-driven result navigation.

  Supports prefix-based modes:
  - `@` projects, `%` entries, `#` topics, `!` commands
  """

  alias Glossary.Entries
  alias Glossary.Projects
  alias Glossary.Topics
  alias GlossaryWeb.Commands

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(
       query: "",
       show_trigger: false,
       search_modal_open?: false,
       search_mode: :all,
       search_result_groups: result_groups(),
       search_results_empty?: true,
       context: %{},
       command_results: [],
       command_step: nil,
       picker_query: "",
       picker_results: []
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("search", %{"query" => raw_query}, socket) do
    {mode, search_query} = parse_prefix(raw_query, socket.assigns.search_mode)

    socket =
      case mode do
        :commands ->
          commands = Commands.list_commands(socket.assigns.context, search_query)

          socket
          |> assign(
            query: search_query,
            search_modal_open?: true,
            search_mode: :commands,
            command_results: commands,
            search_results_empty?: commands == [],
            command_step: nil
          )

        _ ->
          results = Entries.search(search_query, mode)

          socket
          |> assign(
            query: search_query,
            search_modal_open?: true,
            search_mode: mode,
            search_result_groups: group_results(results, socket.assigns.search_result_groups),
            search_results_empty?: results == [],
            command_results: [],
            command_step: nil
          )
      end

    {:noreply, maybe_push_query_update(socket, raw_query, search_query)}
  end

  @impl true
  def handle_event("select_command", %{"id" => command_id}, socket) do
    command = Commands.get_command(command_id)
    action = Commands.resolve_action(command, socket.assigns.context)

    case action do
      {:navigate, path} ->
        {:noreply,
         socket
         |> assign(:search_modal_open?, false)
         |> push_navigate(to: path)}

      {:action, action_name} ->
        picker_results = load_picker_results(action_name, socket.assigns.context, "")

        {:noreply,
         socket
         |> assign(
           command_step: {:picking, command},
           picker_query: "",
           picker_results: picker_results
         )}
    end
  end

  @impl true
  def handle_event("picker_search", %{"picker_query" => query}, socket) do
    {:picking, command} = socket.assigns.command_step
    action = Commands.resolve_action(command, socket.assigns.context)
    {:action, action_name} = action
    results = load_picker_results(action_name, socket.assigns.context, query)

    {:noreply,
     socket
     |> assign(picker_query: query, picker_results: results)}
  end

  @impl true
  def handle_event("picker_select", %{"id" => id, "type" => type}, socket) do
    {:picking, command} = socket.assigns.command_step
    action = Commands.resolve_action(command, socket.assigns.context)
    {:action, action_name} = action

    picked = load_picked_record(type, id)
    {:ok, _} = execute_picker_action(action_name, socket.assigns.context, picked)
    send(self(), {:search_modal_action, :info, action_success_message(action_name)})

    {:noreply,
     socket
     |> assign(
       search_modal_open?: false,
       command_step: nil,
       picker_query: "",
       picker_results: []
     )}
  end

  @impl true
  def handle_event("picker_create", %{"name" => name}, socket) do
    name = String.trim(name)

    if name != "" do
      {:picking, command} = socket.assigns.command_step
      {:action, action_name} = Commands.resolve_action(command, socket.assigns.context)

      created = create_and_associate(action_name, socket.assigns.context, name)

      case created do
        {:ok, _} ->
          send(self(), {:search_modal_action, :info, create_success_message(action_name, name)})

          {:noreply,
           socket
           |> assign(
             search_modal_open?: false,
             command_step: nil,
             picker_query: "",
             picker_results: []
           )}

        {:error, _} ->
          send(self(), {:search_modal_action, :error, "Failed to create \"#{name}\"."})
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("summon_search_modal", _params, socket) do
    {:noreply, assign(socket, :search_modal_open?, true)}
  end

  @impl true
  def handle_event("banish_search_modal", _params, socket) do
    {:noreply,
     assign(socket,
       search_modal_open?: false,
       command_step: nil,
       picker_query: "",
       picker_results: []
     )}
  end

  defp load_picked_record("entry", id), do: Entries.get_entry!(id)
  defp load_picked_record("project", id), do: Projects.get_project!(id)
  defp load_picked_record("topic", id), do: Topics.get_topic!(id)

  defp load_picker_results(:add_entry_to_project, context, query) do
    Projects.available_entries(context.project, query)
    |> Enum.map(&%{id: &1.id, title: &1.title_text, subtitle: &1.subtitle_text, type: :entry})
  end

  defp load_picker_results(:add_entry_to_topic, context, query) do
    Topics.available_entries(context.topic, query)
    |> Enum.map(&%{id: &1.id, title: &1.title_text, subtitle: &1.subtitle_text, type: :entry})
  end

  defp load_picker_results(:add_entry_to_project_from_entry, context, query) do
    Entries.available_projects(context.entry, query)
    |> Enum.map(&%{id: &1.id, title: &1.name, subtitle: nil, type: :project})
  end

  defp load_picker_results(:add_entry_to_topic_from_entry, context, query) do
    Entries.available_topics(context.entry, query)
    |> Enum.map(&%{id: &1.id, title: &1.name, subtitle: nil, type: :topic})
  end

  defp execute_picker_action(:add_entry_to_project, context, picked) do
    Projects.add_entry(context.project, picked)
  end

  defp execute_picker_action(:add_entry_to_topic, context, picked) do
    Topics.add_entry(context.topic, picked)
  end

  defp execute_picker_action(:add_entry_to_project_from_entry, context, picked) do
    Projects.add_entry(picked, context.entry)
  end

  defp execute_picker_action(:add_entry_to_topic_from_entry, context, picked) do
    Topics.add_entry(picked, context.entry)
  end

  defp parse_prefix(raw_query, current_mode) do
    case raw_query do
      "!" <> rest -> {:commands, String.trim_leading(rest)}
      "@" <> rest -> {:projects, String.trim_leading(rest)}
      "%" <> rest -> {:entries, String.trim_leading(rest)}
      "#" <> rest -> {:topics, String.trim_leading(rest)}
      "" -> {:all, ""}
      _ when current_mode not in [:all] -> {current_mode, raw_query}
      _ -> {:all, raw_query}
    end
  end

  defp maybe_push_query_update(socket, raw_query, search_query) do
    if raw_query != search_query do
      push_event(socket, "search:update_query", %{value: search_query})
    else
      socket
    end
  end

  defp mode_label(:projects), do: "Projects"
  defp mode_label(:entries), do: "Entries"
  defp mode_label(:topics), do: "Topics"
  defp mode_label(:commands), do: "Commands"
  defp mode_label(:all), do: nil

  defp mode_badge_class(:projects), do: "badge-accent"
  defp mode_badge_class(:entries), do: "badge-primary"
  defp mode_badge_class(:topics), do: "badge-info"
  defp mode_badge_class(:commands), do: "badge-warning"
  defp mode_badge_class(_), do: ""

  defp empty_message(:projects), do: "No matching projects."
  defp empty_message(:entries), do: "No matching entries."
  defp empty_message(:topics), do: "No matching topics."
  defp empty_message(:commands), do: "No matching commands."
  defp empty_message(:all), do: "No matching results."

  defp result_path(%{type: :entry, id: id}), do: ~p"/entries/#{id}"
  defp result_path(%{type: :project, id: id}), do: ~p"/projects/#{id}"
  defp result_path(%{type: :topic, id: id}), do: ~p"/topics/#{id}"

  defp result_groups do
    %{
      entry: %{label: "Entries", dom_id: "entry-results-section", results: []},
      project: %{label: "Projects", dom_id: "project-results-section", results: []},
      topic: %{label: "Topics", dom_id: "topic-results-section", results: []}
    }
  end

  defp group_results(results, groups) do
    groups = reset_group_results(groups)

    grouped =
      Enum.reduce(results, groups, fn result, acc ->
        case result.type do
          :entry -> update_in(acc.entry.results, &[result | &1])
          :project -> update_in(acc.project.results, &[result | &1])
          :topic -> update_in(acc.topic.results, &[result | &1])
          _ -> acc
        end
      end)

    reverse_group_results(grouped)
  end

  defp reset_group_results(groups) do
    for {key, group} <- groups, into: %{} do
      {key, %{group | results: []}}
    end
  end

  defp reverse_group_results(groups) do
    for {key, group} <- groups, into: %{} do
      {key, %{group | results: Enum.reverse(group.results)}}
    end
  end

  attr :group, :map, required: true

  defp result_section(assigns) do
    ~H"""
    <div :if={@group.results != []} id={@group.dom_id} class="space-y-1">
      <div class="text-base-content/60 px-3 pt-1 text-xs font-semibold uppercase tracking-wide">
        {@group.label}
      </div>

      <.link
        :for={result <- @group.results}
        id={"search-result-#{result.type}-#{result.id}"}
        navigate={result_path(result)}
        class="flex items-center justify-between rounded-lg p-3 transition-colors hover:bg-base-200 focus:bg-base-200 focus:outline-none"
      >
        <div>
          <div class="font-semibold">{result.title}</div>
          <div
            :if={result.subtitle && result.subtitle != ""}
            class="text-base-content/60 text-sm"
          >
            {result.subtitle}
          </div>
        </div>
        <.icon name="hero-chevron-right-micro" class="size-5 text-base-content/25 shrink-0" />
      </.link>
    </div>
    """
  end

  attr :commands, :list, required: true
  attr :myself, :any, required: true

  defp command_section(assigns) do
    ~H"""
    <div class="space-y-1">
      <div class="text-base-content/60 px-3 pt-1 text-xs font-semibold uppercase tracking-wide">
        Commands
      </div>

      <button
        :for={cmd <- @commands}
        id={"command-#{cmd.id}"}
        phx-click="select_command"
        phx-value-id={cmd.id}
        phx-target={@myself}
        type="button"
        class="flex w-full items-center gap-3 rounded-lg p-3 text-left transition-colors hover:bg-base-200 focus:bg-base-200 focus:outline-none"
      >
        <.icon name={cmd.icon} class="size-5 text-base-content/50 shrink-0" />
        <span class="font-semibold">{cmd.label}</span>
      </button>
    </div>
    """
  end

  attr :command, :map, required: true
  attr :picker_query, :string, required: true
  attr :picker_results, :list, required: true
  attr :myself, :any, required: true

  defp picker_section(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center gap-2 px-3 pt-1">
        <.icon name={@command.icon} class="size-4 text-base-content/50" />
        <span class="text-base-content/60 text-xs font-semibold uppercase tracking-wide">
          {@command.label}
        </span>
      </div>

      <.form
        for={%{}}
        id="picker-search-form"
        phx-change="picker_search"
        phx-target={@myself}
        class="px-3"
      >
        <.input
          id="picker-search-input"
          phx-mounted={JS.focus()}
          type="text"
          name="picker_query"
          placeholder="Search..."
          autocomplete="off"
          value={@picker_query}
          phx-debounce="100"
          class="w-full"
        />
      </.form>

      <div class="max-h-60 space-y-1 overflow-y-auto">
        <.form
          :if={picker_can_create?(@command)}
          for={%{}}
          id="picker-create-form"
          phx-submit="picker_create"
          phx-target={@myself}
          class="flex items-center gap-2 rounded-lg p-2 hover:bg-base-200"
        >
          <.icon name="hero-plus" class="size-5 text-primary shrink-0" />
          <input
            type="text"
            name="name"
            placeholder="Create new..."
            autocomplete="off"
            class="grow bg-transparent text-primary placeholder-primary/50 font-medium focus:outline-none"
          />
        </.form>
        <div
          :if={@picker_results == []}
          class="text-base-content/50 py-4 text-center text-sm"
        >
          No results found.
        </div>
        <button
          :for={result <- @picker_results}
          id={"picker-#{result.type}-#{result.id}"}
          phx-click="picker_select"
          phx-value-id={result.id}
          phx-value-type={result.type}
          phx-target={@myself}
          type="button"
          class="flex w-full items-center gap-2 rounded-lg p-2 text-left hover:bg-base-200"
        >
          <.icon name="hero-plus-circle" class="size-5 text-success shrink-0" />
          <div>
            <div class="font-medium">
              <%= if result.title && result.title != "" do %>
                {result.title}
              <% else %>
                <em class="text-base-content/25 italic">Untitled</em>
              <% end %>
            </div>
            <div
              :if={result[:subtitle] && result[:subtitle] != ""}
              class="text-base-content/50 text-sm"
            >
              {result.subtitle}
            </div>
          </div>
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <section :if={@show_trigger}>
        <button
          id="dashboard-search-button"
          phx-hook="SearchShortcut"
          phx-target={@myself}
          phx-focus="summon_search_modal"
          phx-click="summon_search_modal"
          phx-debounce="100"
          type="button"
          class="border-base-content/50 mx-auto flex w-full max-w-3xl cursor-pointer items-center space-x-2 rounded-md border p-3 text-sm"
        >
          <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

          <div
            placeholder="Search"
            autocomplete="off"
            class="text-base-content/50 grow cursor-text text-left focus:outline-none"
          >
            Search
          </div>

          <span class="hidden space-x-1 sm:inline-flex">
            <kbd class="kbd kbd-sm">
              ⌘
            </kbd>
            <kbd class="kbd kbd-sm">k</kbd>
          </span>
        </button>
      </section>

      <button
        :if={!@show_trigger}
        id="search-shortcut-trigger"
        phx-hook="SearchShortcut"
        phx-target={@myself}
        phx-click="summon_search_modal"
        type="button"
        class="hidden"
      >
        Summon Search
      </button>

      <section
        :if={@search_modal_open?}
        id="search-modal"
        class="modal modal-open"
        phx-target={@myself}
        phx-window-keydown="banish_search_modal"
        phx-key="escape"
      >
        <div
          id="search-modal-content"
          class="modal-box min-h-72 max-w-3xl"
          phx-hook="SearchResultNavigator"
          phx-target={@myself}
          phx-click-away="banish_search_modal"
        >
          <%!-- Search input (hidden during picker step) --%>
          <label
            :if={@command_step == nil}
            class="mx-auto flex w-full max-w-3xl items-center gap-4 text-sm"
          >
            <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

            <div class="flex grow items-center gap-2">
              <span
                :if={@search_mode not in [:all]}
                id="search-filter-badge"
                class={["badge badge-sm", mode_badge_class(@search_mode)]}
              >
                {mode_label(@search_mode)}
              </span>

              <.form
                for={%{}}
                id="dashboard-search-form"
                phx-change="search"
                phx-target={@myself}
                class="grow"
              >
                <.input
                  id="dashboard-search-input"
                  phx-mounted={JS.focus()}
                  phx-hook="SearchInput"
                  type="text"
                  name="query"
                  placeholder={search_placeholder(@search_mode)}
                  autocomplete="off"
                  value={@query}
                  phx-debounce="100"
                  class="size-full text-base-content/75 py-1 text-sm focus:outline-none"
                />
              </.form>
            </div>

            <div class="hidden pl-1 sm:inline-flex">
              <kbd class="kbd kbd-sm">
                Esc
              </kbd>
            </div>
          </label>

          <%!-- Default empty state --%>
          <div
            :if={@command_step == nil && @search_mode != :commands && @query == ""}
            class="text-base-content/25 px-3 py-10 text-center text-sm italic"
          >
            <p>Start typing to search entries, projects, or topics.</p>
            <p class="text-base-content/40 mt-2 text-xs not-italic">
              Prefix with <kbd class="kbd kbd-xs">@</kbd>
              projects, <kbd class="kbd kbd-xs">%</kbd>
              entries, <kbd class="kbd kbd-xs">#</kbd>
              topics, or <kbd class="kbd kbd-xs">!</kbd>
              commands
            </p>
          </div>

          <%!-- Commands mode: empty query shows all commands --%>
          <div
            :if={@command_step == nil && @search_mode == :commands && @command_results == []}
            class="text-base-content/60 px-3 py-10 text-center text-sm"
          >
            {empty_message(:commands)}
          </div>

          <%!-- Search empty state --%>
          <div
            :if={
              @command_step == nil && @search_mode != :commands && @query != "" &&
                @search_results_empty?
            }
            class="text-base-content/60 px-3 py-10 text-center text-sm"
          >
            {empty_message(@search_mode)}
          </div>

          <%!-- Command results --%>
          <section
            :if={@command_step == nil && @search_mode == :commands && @command_results != []}
            id="command-results"
            class="space-y-4 pt-4"
          >
            <.command_section commands={@command_results} myself={@myself} />
          </section>

          <%!-- Search results --%>
          <section
            :if={@command_step == nil && @search_mode != :commands}
            id="search-results"
            class="space-y-4 pt-4"
          >
            <.result_section group={@search_result_groups.entry} />
            <.result_section group={@search_result_groups.project} />
            <.result_section group={@search_result_groups.topic} />
          </section>

          <%!-- Two-step picker --%>
          <%= if match?({:picking, _}, @command_step) do %>
            <% {:picking, cmd} = @command_step %>
            <section id="picker-results" class="pt-4">
              <.picker_section
                command={cmd}
                picker_query={@picker_query}
                picker_results={@picker_results}
                myself={@myself}
              />
            </section>
          <% end %>
        </div>
      </section>
    </div>
    """
  end

  defp create_and_associate(:add_entry_to_project_from_entry, context, name) do
    with {:ok, project} <- Projects.create_project(%{name: name}) do
      Projects.add_entry(project, context.entry)
    end
  end

  defp create_and_associate(:add_entry_to_topic_from_entry, context, name) do
    with {:ok, topic} <- Topics.create_topic(%{name: name}) do
      Topics.add_entry(topic, context.entry)
    end
  end

  defp create_and_associate(:add_entry_to_project, context, name) do
    with {:ok, entry} <- Entries.create_entry(%{title_text: name}) do
      Projects.add_entry(context.project, entry)
    end
  end

  defp create_and_associate(:add_entry_to_topic, context, name) do
    with {:ok, entry} <- Entries.create_entry(%{title_text: name}) do
      Topics.add_entry(context.topic, entry)
    end
  end

  defp action_success_message(:add_entry_to_project), do: "Entry added to project."
  defp action_success_message(:add_entry_to_topic), do: "Entry added to topic."
  defp action_success_message(:add_entry_to_project_from_entry), do: "Added to project."
  defp action_success_message(:add_entry_to_topic_from_entry), do: "Added to topic."

  defp create_success_message(:add_entry_to_project_from_entry, name), do: "Created project \"#{name}\" and added entry."
  defp create_success_message(:add_entry_to_topic_from_entry, name), do: "Created topic \"#{name}\" and added entry."
  defp create_success_message(:add_entry_to_project, name), do: "Created entry \"#{name}\" and added to project."
  defp create_success_message(:add_entry_to_topic, name), do: "Created entry \"#{name}\" and added to topic."

  defp picker_can_create?(%{action: {:action, _}}), do: true
  defp picker_can_create?(_), do: false

  defp search_placeholder(:all), do: "Search"
  defp search_placeholder(:projects), do: "Search projects..."
  defp search_placeholder(:entries), do: "Search entries..."
  defp search_placeholder(:topics), do: "Search topics..."
  defp search_placeholder(:commands), do: "Search commands..."
end
