defmodule GlossaryWeb.SearchModal do
  use GlossaryWeb, :live_component

  alias Glossary.Entries

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
       search_results_empty?: true
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("search", %{"query" => raw_query}, socket) do
    {mode, search_query} = parse_prefix(raw_query, socket.assigns.search_mode)
    results = Entries.search(search_query, mode)

    {:noreply,
     socket
     |> assign(
       query: search_query,
       search_modal_open?: true,
       search_mode: mode,
       search_result_groups: group_results(results, socket.assigns.search_result_groups),
       search_results_empty?: results == []
     )
     |> maybe_push_query_update(raw_query, search_query)}
  end

  @impl true
  def handle_event("summon_search_modal", _params, socket) do
    {:noreply, assign(socket, :search_modal_open?, true)}
  end

  @impl true
  def handle_event("banish_search_modal", _params, socket) do
    {:noreply, assign(socket, :search_modal_open?, false)}
  end

  defp parse_prefix(raw_query, current_mode) do
    case raw_query do
      "@" <> rest -> {:projects, String.trim_leading(rest)}
      "%" <> rest -> {:entries, String.trim_leading(rest)}
      "#" <> rest -> {:topics, String.trim_leading(rest)}
      "" -> {:all, ""}
      _ when current_mode != :all -> {current_mode, raw_query}
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
  defp mode_label(:all), do: nil

  defp mode_badge_class(:projects), do: "badge-accent"
  defp mode_badge_class(:entries), do: "badge-primary"
  defp mode_badge_class(:topics), do: "badge-info"
  defp mode_badge_class(_), do: ""

  defp empty_message(:projects), do: "No matching projects."
  defp empty_message(:entries), do: "No matching entries."
  defp empty_message(:topics), do: "No matching topics."
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
          <label class="mx-auto flex w-full max-w-3xl items-center gap-4 text-sm">
            <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

            <div class="flex grow items-center gap-2">
              <span
                :if={@search_mode != :all}
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

          <div
            :if={@query == ""}
            class="text-base-content/25 px-3 py-10 text-center text-sm italic"
          >
            <p>Start typing to search entries, projects, or topics.</p>
            <p class="text-base-content/40 mt-2 text-xs not-italic">
              Prefix with <kbd class="kbd kbd-xs">@</kbd>
              projects, <kbd class="kbd kbd-xs">%</kbd>
              entries, or <kbd class="kbd kbd-xs">#</kbd>
              topics
            </p>
          </div>

          <div
            :if={@query != "" && @search_results_empty?}
            class="text-base-content/60 px-3 py-10 text-center text-sm"
          >
            {empty_message(@search_mode)}
          </div>

          <section id="search-results" class="space-y-4 pt-4">
            <.result_section group={@search_result_groups.entry} />
            <.result_section group={@search_result_groups.project} />
            <.result_section group={@search_result_groups.topic} />
          </section>
        </div>
      </section>
    </div>
    """
  end

  defp search_placeholder(:all), do: "Search"
  defp search_placeholder(:projects), do: "Search projects..."
  defp search_placeholder(:entries), do: "Search entries..."
  defp search_placeholder(:topics), do: "Search topics..."
end
