defmodule GlossaryWeb.DashboardLive do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias GlossaryWeb.EntryLayouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_scope: nil,
       platform: nil,
       query: ""
     )
     |> stream(:recent_entries, Entries.recent_entries())}
  end

  @impl true
  def handle_event("platform_detected", %{"platform" => platform}, socket) do
    {:noreply, assign(socket, :platform, platform)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <span id="platform-detector" phx-hook="DetectPlatform" class="hidden"></span>

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

          <%= if @platform do %>
            <span class="hidden space-x-1 sm:inline-flex">
              <kbd id="leader-key" class="kbd kbd-sm">
                {if @platform == "mac", do: "⌘", else: "Ctrl"}
              </kbd>
              <kbd class="kbd kbd-sm">k</kbd>
            </span>
          <% end %>
        </label>
      </section>

      <section>
        <div class="grid auto-rows-fr grid-cols-1 gap-8 lg:grid-cols-2">
          <a
            href={~p"/entries/new"}
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75"
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
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75"
          >
            <div class="card-body">
              <h2 class="card-title">See All Entries</h2>
              <div class="h-6" />
              <div class="card-actions justify-end">
                <.icon name="hero-arrow-long-right-micro" class="size-6" />
              </div>
            </div>
          </a>
        </div>
      </section>

      <section>
        <EntryLayouts.entry_table table_title="Recent Entries" table_rows={@streams.recent_entries} />
      </section>
    </Layouts.app>
    """
  end
end
