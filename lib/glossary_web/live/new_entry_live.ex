defmodule GlossaryWeb.NewEntryLive do
  @moduledoc """
  LiveView for creating new glossary entries.
  """
  use GlossaryWeb, :live_view

  require Logger
  import GlossaryWeb.KeybindMacros

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, leader_down: false, shift_down: false, entry: %Glossary.Entries.Entry{})}
  end

  pubsub_broadcast_on_event("summon_modal", :summon_modal, true, "search_modal")
  pubsub_broadcast_on_event("banish_modal", :summon_modal, false, "search_modal")

  keybind_listeners()

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div phx-window-keydown="key_down" phx-throttle="500" class="flex flex-col gap-12 pt-8">
        <div>
          <.icon name="hero-arrow-long-left-micro" class="size-4" />
          <.link navigate={~p"/"} class="link link-hover text-sm">Back to Dashboard</.link>
        </div>

        <div
          id="title-editor"
          phx-hook="TitleEditor"
        >
          <input id="entry_title" type="hidden" name="entry[title]" value={@entry.title} />
        </div>
      </div>
    </Layouts.app>

    {live_render(@socket, GlossaryWeb.SearchLive, id: "search-modal")}
    """
  end
end
