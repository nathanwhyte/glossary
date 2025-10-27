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
      <div class="flex flex-col gap-12">
        <.search_bar />
        <.quick_start_content />
      </div>
    </Layouts.app>
    """
  end

  defp search_bar(assigns) do
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
            Use <code class="badge badge-xs bg-base-content/10 border-none">@tag</code>, <code class="badge badge-xs bg-base-content/10 border-none">#subject</code>,
            and <code class="badge badge-xs bg-base-content/10 border-none">&project</code>
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

  defp quick_start_content(assigns) do
    ~H"""
    <section>
      <h1 class="text-xl font-semibold">Quick Start</h1>

      <div class="grid w-full grid-cols-3 grid-rows-3 gap-6 py-2">
        <.quick_start_button
          action_name="New Entry"
          action_link="/"
          action_keys={["⌘", "shift", "O"]}
        />
        <.quick_start_button
          action_name="View Last Entry"
          action_link="/"
          action_keys={["⌘", "shift", "S"]}
        />
        <.quick_start_button action_name="Get a Refresher" action_link="/" />
        <.quick_start_button action_name="View All Tags" action_link="/" />
        <.quick_start_button action_name="View All Subjects" action_link="/" />
        <.quick_start_button action_name="View Projects" action_link="/" />
      </div>
    </section>
    """
  end

  attr :action_name, :string, required: true
  attr :action_link, :string, required: true
  attr :action_keys, :list, default: []

  defp quick_start_button(assigns) do
    ~H"""
    <div class="bg-base-300/25 relative flex h-20 rounded-md rounded-md px-3 py-2 transition hover:bg-base-300 hover:cursor-pointer">
      <.link navigate={~p"/"} class="absolute inset-0"></.link>
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
    """
  end
end
