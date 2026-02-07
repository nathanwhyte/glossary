defmodule GlossaryWeb.DashboardLive do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias GlossaryWeb.EntryLayouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(query: "", search_modal_open?: false, search_results_empty?: true)
     |> stream(:search_results, [])
     |> stream(:recent_entries, Entries.recent_entries())}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    results = Entries.search_entries(query)

    {:noreply,
     socket
     |> assign(query: query, search_modal_open?: true, search_results_empty?: results == [])
     |> stream(:search_results, results, reset: true)}
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
    <Layouts.app flash={@flash}>
      <div class="space-y-12 pt-8">
        <section>
          <button
            id="dashboard-search-button"
            phx-hook="SearchShortcut"
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

        <section
          :if={@search_modal_open?}
          id="search-modal"
          class="modal modal-open"
          phx-window-keydown="banish_search_modal"
          phx-key="escape"
        >
          <div
            id="search-modal-content"
            class="modal-box min-h-72 max-w-3xl"
            phx-click-away="banish_search_modal"
          >
            <label class="mx-auto flex w-full max-w-3xl items-center gap-4 text-sm">
              <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

              <.form for={%{}} id="dashboard-search-form" phx-change="search" class="grow">
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

            <section id="search-results" phx-update="stream" class="space-y-1">
              <.link
                :for={{id, entry} <- @streams.search_results}
                id={id}
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

        <section class="grid auto-rows-fr grid-cols-2 gap-4">
          <a
            href={~p"/entries/new"}
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75 focus:bg-base-200/75"
          >
            <div class="card-body">
              <h2 class="card-title">New Entry</h2>
              <div class="h-6" />
              <div class="card-actions justify-end">
                <.icon name="hero-arrow-long-right-micro" class="size-6" />
              </div>
            </div>
          </a>

          <a
            href={~p"/entries"}
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75 focus:bg-base-200/75"
          >
            <div class="card-body">
              <h2 class="card-title">See All Entries</h2>
              <div class="h-6" />
              <div class="card-actions justify-end">
                <.icon name="hero-arrow-long-right-micro" class="size-6" />
              </div>
            </div>
          </a>
        </section>

        <EntryLayouts.entry_table
          table_title="Recent Entries"
          table_rows={@streams.recent_entries}
        />

        <%!-- IDEA: project list w/ dropdown to show entries --%>
        <%!--       similar to Google Drive layout but w/o folders --%>
      </div>
    </Layouts.app>
    """
  end
end
