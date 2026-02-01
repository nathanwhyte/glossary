defmodule GlossaryWeb.DashboardLive do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias GlossaryWeb.EntryLayouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_scope: nil,
       query: ""
     )
     |> stream(:recent_entries, Entries.recent_entries())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-12">
        <section>
          <label class="input input-lg mx-auto flex w-full max-w-3xl items-center space-x-1 text-sm">
            <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

            <input
              type="text"
              placeholder="Search"
              class=""
              value={@query}
              name="query"
              autocomplete="off"
            />

            <span class="hidden space-x-1 sm:inline-flex">
              <kbd class="kbd kbd-sm">
                ⌘
              </kbd>
              <kbd class="kbd kbd-sm">k</kbd>
            </span>
          </label>
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

        <section>
          <EntryLayouts.entry_table table_title="Recent Entries" table_rows={@streams.recent_entries} />
        </section>
      </div>
    </Layouts.app>
    """
  end
end
