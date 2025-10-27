defmodule GlossaryWeb.HomeLive do
  @moduledoc """
  LiveView for the home page.
  """
  use GlossaryWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.home_content />
    </Layouts.app>
    """
  end

  defp home_content(assigns) do
    ~H"""
    <section class="pt-24">
      <div class="w-full flex-col items-start space-y-2">
        <h1 class="text-xl font-semibold">Glossary Search</h1>

        <div class="input w-full">
          <input type="search" placeholder="Search" />
          <kbd class="kbd kbd-sm bg-base-content/10">⌘</kbd>
          <kbd class="kbd kbd-sm bg-base-content/10 -ml-1">K</kbd>
        </div>

        <div class="flex justify-between pt-2">
          <div class="text-base-content/60 items-center text-xs font-medium">
            Use <code class="badge badge-xs bg-base-content/10 border-none">@tag</code>
            and <code class="badge badge-xs bg-base-content/10 border-none">#subject</code>
            to modify search.
          </div>

          <div class="text-base-content/60 text-xs font-medium">
            Use the <code class="badge badge-xs bg-base-content/10 border-none">!</code>
            prefix to generate an AI-assisted summary of results.
          </div>
        </div>
      </div>
    </section>
    """
  end
end
