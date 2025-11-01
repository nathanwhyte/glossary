defmodule GlossaryWeb.HomeLive do
  @moduledoc """
  LiveView for the home page.
  """
  use GlossaryWeb, :live_view

  require Logger
  import GlossaryWeb.KeybindMacros

  alias Glossary.Entries.Entry

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, leader_down: false, shift_down: false)}
  end

  # Use macros to generate handle_event functions
  pubsub_broadcast_on_event("summon_modal", :summon_modal, true, "search_modal")
  pubsub_broadcast_on_event("banish_modal", :summon_modal, false, "search_modal")
  pubsub_broadcast_on_event("click_search", :summon_modal, true, "search_modal")

  keybind_listeners()

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div
        phx-window-keydown="key_down"
        phx-window-keyup="key_up"
        class="flex flex-col gap-12"
      >
        <.search_bar />
        <.quick_start_content />
        <.recent_entries />
      </div>
    </Layouts.app>

    {live_render(@socket, GlossaryWeb.SearchLive, id: "search-modal")}
    """
  end

  defp search_bar(assigns) do
    ~H"""
    <section class="pt-32">
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
      "relative flex h-20 rounded-md border border-base-content/10 px-3 py-2 shadow-sm"

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
          <%= if length(@action_keys) > 0 do %>
            <div class="pb-1">
              <%= for key <- @action_keys do %>
                <kbd class="kbd kbd-sm bg-base-content/10">{key}</kbd>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="flex items-end pb-1">
          <.icon name="hero-chevron-right-micro" class="size-5" />
        </div>
      </div>
    </.link>
    """
  end

  defp recent_entries(assigns) do
    # TODO: add "last updated" timestamp
    ~H"""
    <section>
      <h1 class="text-xl font-semibold">Recent Entries</h1>
      <div class="grid w-full grid-flow-row auto-rows-auto grid-cols-1 gap-y-4 py-2">
        <.entry_card />
        <div class="card card-sm border-base-content/10 border shadow-md">
          <div class="card-body space-y-1">
            <h2 class="card-title px-1 text-2xl">
              Entry Title 2
            </h2>
            <div class="text-base-content/50 prose w-full px-1 text-sm font-medium italic outline-none">
              This is a brief summary or excerpt of the entry content to give users an idea of what it's about.
            </div>
            <div class="flex items-center gap-3 text-sm">
              <div class="join">
                <div class="badge badge-sm bg-base-content/5 join-item">Status</div>
                <div class="badge badge-success badge-sm join-item font-semibold ">
                  Published
                </div>
              </div>
              <div class="join">
                <div class="badge badge badge-sm bg-base-content/5 join-item">
                  Project
                </div>
                <div class="badge badge-secondary badge-sm join-item font-semibold">
                  Project 1 <.icon name="hero-chevron-up-down-micro" class="size-3 -mx-0.5" />
                </div>
              </div>
              <div class="space-x-1 pl-1">
                <span class="text-[0.75rem]">Topics</span>
                <div class="badge badge-info badge-sm font-semibold">
                  Topic 1
                </div>
                <div class="badge badge-info badge-sm font-semibold">
                  Topic 2
                </div>
              </div>
              <div class="space-x-1 pl-1">
                <span class="text-[0.75rem]">Tags</span>
                <div class="badge badge-primary badge-sm font-semibold">
                  Tag 1
                </div>
                <div class="badge badge-primary badge-sm font-semibold">Tag 2</div>
              </div>
            </div>
            <div class="text-base-content/50 px-1 text-xs">
              Updated
              <span class="font-semibold">
                {DateTime.now!("America/Chicago") |> Calendar.strftime("%a, %m/%d/%y")}
              </span>
              at
              <span class="font-semibold">
                {DateTime.now!("America/Chicago") |> Calendar.strftime("%H:%M")}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :entry, Entry, default: %Entry{}

  defp entry_card(assigns) do
    ~H"""
    <div class="card card-sm border-base-content/5 border shadow-md">
      <.link navigate="#" class="card-body">
        <h2 class="card-title px-1 text-2xl">
          Entry Title 1
        </h2>
        <p class="text-base-content/50 prose w-full px-1 text-sm font-medium italic outline-none">
          This is a brief summary or excerpt of the entry content to give users an idea of what it's about.
        </p>
        <div class="flex gap-3">
          <.status_indicator status="Published" />
          <.project_select />
        </div>
      </.link>
    </div>
    """
  end

  attr :status, :string, required: true

  defp status_indicator(assigns) do
    base_style = "badge badge-sm join-item font-medium"

    assigns =
      assign(
        assigns,
        :style,
        base_style <>
          if(assigns[:status] == "Published",
            do: " badge-success",
            else: " badge-warning"
          )
      )

    ~H"""
    <div class="join pt-1">
      <span class="badge badge-sm bg-base-content/5 border-base-content/10 join-item">
        Status
      </span>
      <span class={@style}>
        {@status}
      </span>
    </div>
    """
  end

  attr :project, :string, default: "None"

  defp project_select(assigns) do
    base_style = "badge badge-sm join-item font-medium"

    assigns =
      assign(
        assigns,
        :style,
        base_style <>
          if(assigns[:project] == "None",
            do: " border-base-content/10",
            else: " badge-secondary"
          )
      )

    ~H"""
    <div class="join pt-1">
      <span class="badge badge-sm bg-base-content/5 border-base-content/10 join-item">
        Project
      </span>
      <span class={@style}>
        {@project} <.icon name="hero-chevron-up-down-micro" class="size-3 -mx-0.5" />
      </span>
    </div>
    """
  end
end
