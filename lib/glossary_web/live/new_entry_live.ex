defmodule GlossaryWeb.NewEntryLive do
  @moduledoc """
  LiveView for creating new glossary entries.
  """
  use GlossaryWeb, :live_view

  require Logger
  import GlossaryWeb.KeybindMacros

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, leader_down: false)}
  end

  pubsub_broadcast_on_event("summon_modal", :summon_modal, true, "search_modal")
  pubsub_broadcast_on_event("banish_modal", :summon_modal, false, "search_modal")

  keybind_listeners()

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div phx-window-keydown="key_down" phx-throttle="500" class="flex flex-col gap-12">
        Hello
      </div>
    </Layouts.app>

    {live_render(@socket, GlossaryWeb.SearchLive, id: "search-modal")}
    """
  end
end
