defmodule GlossaryWeb.HomeLive do
  @moduledoc """
  LiveView for the home page.
  """
  use GlossaryWeb, :live_view

  require Logger

  import GlossaryWeb.KeybindMacros
  import Ecto.Query, only: [from: 2]

  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @impl true
  def mount(_params, _session, socket) do
    # IDEA: cache the latest 5 entries
    #       invalidate on new entry creation (?)

    timezone = get_connect_params(socket)["timezone"] || "UTC"

    recent_entries =
      Repo.all(
        from(e in Entry,
          order_by: [desc: e.updated_at],
          limit: 3
        )
      )

    Logger.info("HomeLive mounted with entries: #{inspect(recent_entries)}")

    {:ok,
     assign(socket,
       leader_down: false,
       shift_down: false,
       timezone: timezone,
       recent_entries: recent_entries
     )}
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
        class="flex flex-col gap-12 py-8"
      >
        <.search_bar />
        <.quick_start_content />

        <section>
          <h1 class="text-xl font-semibold">Recent Entries</h1>
          <div class="grid w-full grid-flow-row auto-rows-auto grid-cols-1 gap-y-4 py-2">
            <.entry_card :for={entry <- @recent_entries} entry={entry} timezone={@timezone} />
          </div>
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

  attr :entry, Entry, required: true
  attr :timezone, :string, required: true

  defp entry_card(assigns) do
    ~H"""
    <div class="card card-sm border-base-content/5 border shadow-md">
      <div class="card-body">
        <%= if @entry.title != "" do %>
          <div class="recent-entry-title">
            {Phoenix.HTML.raw(@entry.title)}
          </div>
        <% else %>
          <div class="recent-entry-title text-base-content/25 italic">
            No Title
          </div>
        <% end %>
        <div :if={@entry.description != ""} class="recent-entry-description">
          {Phoenix.HTML.raw(@entry.description)}
        </div>
        <div class="flex items-center gap-3 pt-1">
          <.status_indicator status={@entry.status} />
          <.project_select project="None" />
          <.topic_badges topics={[]} />
          <.tag_badges tags={[]} />
        </div>
        <.last_updated_timestamp updated={@entry.updated_at} timezone={@timezone} />
      </div>
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
    <div class="join">
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
    <div class="join">
      <span class="badge badge-sm bg-base-content/5 border-base-content/10 join-item">
        Project
      </span>
      <span class={@style}>
        {@project} <.icon name="hero-chevron-up-down-micro" class="size-3 -mx-0.5" />
      </span>
    </div>
    """
  end

  # IDEA: if length(@topics) > 3, move excess to dropdown menu

  attr :topics, :list, required: true

  defp topic_badges(assigns) do
    ~H"""
    <div class="flex items-center gap-1.5">
      <div class="text-[0.75rem]">Topics</div>
      <%= if length(@topics) <= 0 do %>
        <div class="text-base-content/25 pl-1 font-semibold italic">
          None
        </div>
      <% else %>
        <%= for topic <- @topics do %>
          <div class="badge badge-info badge-sm font-semibold">
            #{topic}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  # IDEA: if length(@tags) > 3, move excess to dropdown menu

  attr :tags, :list, required: true

  defp tag_badges(assigns) do
    ~H"""
    <div class="flex items-center gap-1.5">
      <div class="text-[0.75rem]">Tags</div>
      <%= if length(@tags) <= 0 do %>
        <div class="text-base-content/25 pl-1 font-semibold italic">
          None
        </div>
      <% else %>
        <%= for tag <- @tags do %>
          <div class="badge badge-primary badge-sm font-semibold">
            @{tag}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr :updated, DateTime, required: true
  attr :timezone, :string, required: true

  defp last_updated_timestamp(assigns) do
    assigns =
      assign(assigns, :updated_localized, DateTime.shift_zone!(assigns.updated, assigns.timezone))

    ~H"""
    <div class="text-base-content/50 pt-1 text-xs">
      Updated
      <span class="font-semibold">
        {@updated_localized |> Calendar.strftime("%a, %m/%d/%y")}
      </span>
      at
      <span class="font-semibold">
        {@updated_localized |> Calendar.strftime("%H:%M")}
      </span>
    </div>
    """
  end
end
