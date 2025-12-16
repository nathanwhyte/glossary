defmodule GlossaryWeb.HomeLive do
  @moduledoc """
  LiveView for the home page.
  """
  use GlossaryWeb, :live_view

  on_mount {GlossaryWeb.UserAuthHooks, :assign_current_scope}

  import GlossaryWeb.KeybindMacros
  import GlossaryWeb.Components.EntryComponents

  alias Glossary.{Entries, Projects}

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    params = get_connect_params(socket) || %{}
    timezone = params["timezone"] || "UTC"

    recent_entries = Entries.list_recent_entries(5)
    recent_projects = Projects.list_recent_projects(5)

    for entry <- recent_entries do
      Logger.info("Entry: #{inspect(entry.topics)}\n")
    end

    {:ok,
     assign(socket,
       leader_down: false,
       shift_down: false,
       timezone: timezone,
       recent_entries: recent_entries,
       recent_projects: recent_projects
     )}
  end

  # Use macros to generate handle_event functions
  pubsub_broadcast_on_event("summon_modal", :summon_modal, true, "search_modal")
  pubsub_broadcast_on_event("banish_modal", :summon_modal, false, "search_modal")
  pubsub_broadcast_on_event("click_search", :summon_modal, true, "search_modal")

  keybind_listeners()

  @impl true
  def handle_event(
        "change_project",
        %{"entry_id" => entry_id, "project_id" => project_id},
        socket
      ) do
    project_id = if project_id == "", do: nil, else: project_id
    entry = Entries.get_entry!(entry_id)

    {:ok, _} =
      Entries.update_entry(entry, %{project_id: project_id})

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div
        phx-window-keydown="key_down"
        phx-window-keyup="key_up"
        class="flex flex-col gap-8 py-8"
      >
        <.search_bar />
        <.quick_start_content />

        <section>
          <div class="flex items-center justify-between">
            <h1 class="text-xl font-semibold">Recent Entries</h1>
            <%!-- TODO: route to "all entries" view (not implemented yet) --%>
            <.button class="btn btn-ghost btn-xs" navigate={~p"/"}>
              View All <.icon name="hero-chevron-right-micro" class="size-3.5 -mr-0.5" />
            </.button>
          </div>
          <%= if Enum.empty?(@recent_entries) do %>
            <div class="text-base-content/25 py-16 text-center text-xl font-semibold italic">
              No entries yet.
            </div>
          <% else %>
            <div class="grid w-full grid-flow-row auto-rows-auto grid-cols-1 gap-y-4 py-2">
              <.entry_card
                :for={entry <- @recent_entries}
                entry={entry}
                timezone={@timezone}
                recent_projects={@recent_projects}
              />
            </div>
          <% end %>
        </section>
      </div>
    </Layouts.app>

    {live_render(@socket, GlossaryWeb.SearchLive, id: "search-modal")}
    """
  end

  defp search_bar(assigns) do
    ~H"""
    <section>
      <div class="w-full flex-col items-start space-y-2">
        <h1 class="text-xl font-semibold">Glossary Search</h1>

        <label phx-click="click_search" class="input flex w-full shadow-sm has-focus:outline-none">
          <input type="search" placeholder="Search" class="grow" />

          <div>
            <kbd class="kbd kbd-sm bg-base-content/10">⌘</kbd>
            <kbd class="kbd kbd-sm bg-base-content/10">K</kbd>
          </div>
        </label>
      </div>
    </section>
    """
  end

  defp quick_start_content(assigns) do
    ~H"""
    <section>
      <h1 class="text-xl font-semibold">Quick Start</h1>

      <div class="grid w-full grid-cols-3 grid-rows-1 gap-4 py-2">
        <.quick_start_button
          action_name="New Entry"
          action_link="/entries/new"
          action_keys={["⌘", "shift", "o"]}
        />
        <.quick_start_button
          action_name="Command Palette"
          action_link="#"
          action_keys={["⌘", "shift", "p"]}
          disabled
        />
        <.quick_start_button action_name="Projects" action_link="#" disabled />
      </div>
    </section>
    """
  end

  attr :action_name, :string, required: true
  attr :action_link, :string, required: true
  attr :action_keys, :list, default: []
  attr :disabled, :boolean, default: false

  defp quick_start_button(assigns) do
    base_style =
      "relative flex h-20 rounded-md border border-base-content/20 px-3 py-2 shadow-sm"

    assigns =
      assign(
        assigns,
        :container_style,
        cond do
          assigns[:disabled] ->
            base_style <>
              " cursor-default"

          true ->
            base_style <>
              " cursor-pointer transition hover:bg-base-300/50 hover:border-base-300/50"
        end
      )

    ~H"""
    <.link navigate={@action_link}>
      <div class={@container_style}>
        <div class="flex h-full flex-1 flex-col justify-between text-lg">
          <span class="font-medium">
            {@action_name}
          </span>
          <div :if={length(@action_keys) > 0} class="space-x-1 pb-1">
            <kbd :for={key <- @action_keys} class="kbd kbd-sm bg-base-content/10">{key}</kbd>
          </div>
        </div>

        <div class="flex items-end pb-1">
          <.icon name="hero-chevron-right-micro" class="size-5" />
        </div>
      </div>
    </.link>
    """
  end
end
