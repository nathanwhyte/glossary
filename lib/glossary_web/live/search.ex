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
       search_result_groups: result_groups(),
       search_results_empty?: true
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    results = Entries.search(query)

    {:noreply,
     socket
     |> assign(
       query: query,
       search_modal_open?: true,
       search_result_groups: group_results(results, socket.assigns.search_result_groups),
       search_results_empty?: results == []
     )}
  end

  @impl true
  def handle_event("summon_search_modal", _params, socket) do
    {:noreply, assign(socket, :search_modal_open?, true)}
  end

  @impl true
  def handle_event("banish_search_modal", _params, socket) do
    {:noreply, assign(socket, :search_modal_open?, false)}
  end

  defp result_path(%{type: :entry, id: id}), do: ~p"/entries/#{id}"
  defp result_path(%{type: :project, id: id}), do: ~p"/projects/#{id}"
  defp result_path(%{type: :tag, id: id}), do: "/tags/#{id}"

  defp result_groups do
    %{
      entry: %{label: "Entries", dom_id: "entry-results-section", results: []},
      project: %{label: "Projects", dom_id: "project-results-section", results: []},
      tag: %{label: "Tags", dom_id: "tag-results-section", results: []}
    }
  end

  defp group_results(results, groups) do
    groups = reset_group_results(groups)

    grouped =
      Enum.reduce(results, groups, fn result, acc ->
        case result.type do
          :entry -> update_in(acc.entry.results, &[result | &1])
          :project -> update_in(acc.project.results, &[result | &1])
          :tag -> update_in(acc.tag.results, &[result | &1])
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
                type="text"
                name="query"
                placeholder="Search"
                autocomplete="off"
                value={@query}
                phx-debounce="150"
                class="size-full text-base-content/75 py-1 text-sm focus:outline-none"
              />
            </.form>

            <div class="hidden pl-1 sm:inline-flex">
              <kbd class="kbd kbd-sm">
                Esc
              </kbd>
            </div>
          </label>

          <div :if={@query == ""} class="text-base-content/25 px-3 py-10 text-center text-sm italic">
            Start typing to search entries, projects, or tags.
          </div>

          <div
            :if={@query != "" && @search_results_empty?}
            class="text-base-content/60 px-3 py-10 text-center text-sm"
          >
            No matching entries.
          </div>

          <section id="search-results" class="space-y-4 pt-4">
            <.result_section group={@search_result_groups.entry} />
            <.result_section group={@search_result_groups.project} />
            <.result_section group={@search_result_groups.tag} />
          </section>
        </div>
      </section>
    </div>
    """
  end
end
