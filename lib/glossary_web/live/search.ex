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
       search_results: [],
       search_results_empty?: true
     )}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    results = Entries.search_entries(query)

    {:noreply,
     socket
     |> assign(
       query: query,
       search_modal_open?: true,
       search_results: results,
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
                class="size-full py-3 text-sm focus:outline-none"
              />
            </.form>

            <div class="hidden pl-1 sm:inline-flex">
              <kbd class="kbd kbd-sm">
                Esc
              </kbd>
            </div>
          </label>

          <div :if={@query == ""} class="text-base-content/25 px-3 py-10 text-center text-sm italic">
            Start typing to search entries.
          </div>

          <div
            :if={@query != "" && @search_results_empty?}
            class="text-base-content/60 px-3 py-10 text-center text-sm"
          >
            No matching entries.
          </div>

          <section id="search-results" class="space-y-1">
            <.link
              :for={entry <- @search_results}
              id={"search-result-#{entry.id}"}
              navigate={~p"/entries/#{entry.id}"}
              class="block rounded-lg p-3 hover:bg-base-200"
            >
              <div class="font-semibold">{entry.title_text}</div>
              <div :if={entry.subtitle_text != ""} class="text-base-content/60 text-sm">
                {entry.subtitle_text}
              </div>
            </.link>
          </section>
        </div>
      </section>
    </div>
    """
  end
end
