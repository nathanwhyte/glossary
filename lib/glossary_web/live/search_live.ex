defmodule GlossaryWeb.SearchLive do
  @moduledoc """
  Search modal component for the home page.
  """
  use GlossaryWeb, :live_view

  import GlossaryWeb.Components.UiComponents, only: [attribute_badge: 1]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-h-[75vh] mx-auto max-w-6xl space-y-6 pt-32">
      <.search_content />
    </div>
    """
  end

  def search_content(assigns) do
    ~H"""
    <div class="space-y-2">
      <div class="input flex w-full items-center">
        <.icon name="hero-magnifying-glass-micro" class="size-4" />
        <input type="search" placeholder="Search" class="flex-1" />
        <kbd class="kbd kbd-xs bg-base-content/10">esc</kbd>
      </div>

      <div class="flex justify-between pt-2">
        <div class="text-base-content/60 items-center text-xs font-medium">
          Use <.attribute_badge attribute="@tag" />, <.attribute_badge attribute="#subject" />, and
          <.attribute_badge attribute="&project" /> to modify search.
        </div>
        <div class="text-base-content/60 text-xs font-medium">
          Use the <.attribute_badge attribute="!" />
          prefix to generate an AI-assisted summary of results.
        </div>
      </div>
    </div>

    <div class="min-h-64">
      <h1 class="text-xl font-semibold">
        Results
      </h1>
    </div>
    """
  end

  attr :show, :boolean, default: true
  attr :on_close, :any, required: true

  def search_modal(assigns) do
    ~H"""
    <div class={if @show, do: "modal modal-open", else: "modal"}>
      <div
        phx-click-away="modal_click_away"
        class="modal-box border-base-content/10 max-h-[75vh] mx-auto max-w-6xl space-y-6 border"
      >
        <.search_content />
      </div>
      <div class="modal-action"></div>
    </div>
    """
  end
end
