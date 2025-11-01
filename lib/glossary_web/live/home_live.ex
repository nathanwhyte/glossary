defmodule GlossaryWeb.HomeLive do
  @moduledoc """
  LiveView for the home page.
  """
  use GlossaryWeb, :live_view

  require Logger
  import GlossaryWeb.KeybindMacros

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

        <div phx-click="click_search" class="input flex w-full">
          <input type="search" placeholder="Search" class="flex-1" />

          <div>
            <kbd class="kbd kbd-sm bg-base-content/10">⌘</kbd>
            <kbd class="kbd kbd-sm bg-base-content/10">K</kbd>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp quick_start_content(assigns) do
    ~H"""
    <section>
      <h1 class="text-xl font-semibold">Quick Start</h1>

      <div class="grid w-full grid-cols-3 grid-rows-3 gap-4 py-2">
        <.quick_start_button
          action_name="New Entry"
          action_link="/entries/new"
          action_keys={["⌘", "shift", "o"]}
        />
        <.quick_start_button
          action_name="View Last Entry"
          action_link="#"
          action_keys={["⌘", "shift", "s"]}
          disabled
        />
        <.quick_start_button
          action_name="Command Palette"
          action_link="#"
          action_keys={["⌘", "shift", "p"]}
          disabled
        />
        <.quick_start_button action_name="View All Tags" action_link="#" disabled />
        <.quick_start_button action_name="View All Subjects" action_link="#" disabled />
        <.quick_start_button action_name="View All Projects" action_link="#" disabled />
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
      "relative flex h-20 rounded-md px-3 py-2"

    assigns =
      assign(
        assigns,
        :container_style,
        cond do
          assigns[:disabled] ->
            base_style <>
              " cursor-default bg-base-content/5"

          true ->
            base_style <> " bg-base-300/75 cursor-pointer transition hover:bg-base-300"
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
end
