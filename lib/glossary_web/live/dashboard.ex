defmodule GlossaryWeb.Dashboard do
  use GlossaryWeb, :live_view

  @moduledoc """
  LiveView dashboard showing navigation cards and recent entries.
  """

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
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-12 pt-8">
        <.live_component
          module={GlossaryWeb.SearchModal}
          id="global-search-modal"
          show_trigger={true}
        />

        <section class="grid auto-rows-fr grid-cols-1 gap-4 lg:grid-cols-3">
          <a
            href={~p"/entries"}
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75 focus:bg-base-200/75"
          >
            <div class="card-body">
              <h2 class="card-title">Entries</h2>
              <div class="h-6" />
              <div class="card-actions justify-end">
                <.icon name="hero-arrow-long-right-micro" class="size-6" />
              </div>
            </div>
          </a>

          <a
            href={~p"/projects"}
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75 focus:bg-base-200/75"
          >
            <div class="card-body">
              <h2 class="card-title">Projects</h2>
              <div class="h-6" />
              <div class="card-actions justify-end">
                <.icon name="hero-arrow-long-right-micro" class="size-6" />
              </div>
            </div>
          </a>

          <a
            href={~p"/topics"}
            class="card card-border bg-base-100 shadow-xl transition-colors hover:bg-base-200/75 focus:bg-base-200/75"
          >
            <div class="card-body">
              <h2 class="card-title">Topics</h2>
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
      </div>
    </Layouts.app>
    """
  end
end
