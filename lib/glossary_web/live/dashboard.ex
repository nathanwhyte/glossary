defmodule GlossaryWeb.Dashboard do
  use GlossaryWeb, :live_view

  alias Glossary.Entries
  alias GlossaryWeb.EntryLayouts

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:recent_entries, Entries.recent_entries())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-12 pt-8">
        <.live_component
          module={GlossaryWeb.SearchModal}
          id="global-search-modal"
          show_trigger={true}
        />

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
