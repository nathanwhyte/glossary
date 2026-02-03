defmodule GlossaryWeb.DashboardLive do
  use GlossaryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "")}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-12 pt-8">
        <section>
          <label class="input input-lg mx-auto flex w-full max-w-3xl items-center space-x-1 text-sm">
            <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

            <.form for={%{}} phx-change="search" class="grow">
              <.input
                type="text"
                name="query"
                placeholder="Search"
                autocomplete="off"
                value={@query}
                phx-debounce="150"
                class="input-ghost input-md size-full border-0 focus:ring-0"
              />
            </.form>

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
      </div>
    </Layouts.app>
    """
  end
end
