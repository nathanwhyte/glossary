defmodule GlossaryWeb.DashboardLive do
  use GlossaryWeb, :live_view

  # Initialize counter state for the LiveView session.
  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_scope: nil,
       platform: nil,
       query: ""
     )}
  end

  # Handle button clicks and update the counter based on action.
  @impl true
  def handle_event("platform_detected", %{"platform" => platform}, socket) do
    IO.inspect(platform, label: "User Platform")
    {:noreply, assign(socket, :platform, platform)}
  end

  # Render the counter UI with stable DOM IDs for tests.
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <span id="platform-detector" phx-hook="DetectPlatform" class="hidden"></span>

      <section>
        <label class="input input-lg flex w-full items-center space-x-1 text-sm">
          <.icon name="hero-magnifying-glass-micro" class="size-5 shrink-0" />

          <input
            type="text"
            placeholder="Search"
            class=""
            value={@query}
            name="query"
            autocomplete="off"
          />

          <%= if @platform do %>
            <span class="hidden space-x-1 sm:inline-flex">
              <kbd id="leader-key" class="kbd kbd-sm">
                {if @platform == "mac", do: "⌘", else: "Ctrl"}
              </kbd>
              <kbd class="kbd kbd-sm">k</kbd>
            </span>
          <% end %>
        </label>
      </section>
    </Layouts.app>
    """
  end
end
