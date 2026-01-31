defmodule GlossaryWeb.DashboardLive do
  use GlossaryWeb, :live_view

  # Initialize counter state for the LiveView session.
  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_scope: nil,
       initial: 0,
       step: 1,
       count: 0
     )}
  end

  # Handle button clicks and update the counter based on action.
  @impl true
  def handle_event("counter", %{"action" => action}, socket) do
    count =
      update_count(action, socket.assigns.count, socket.assigns.initial, socket.assigns.step)

    {:noreply, assign(socket, :count, count)}
  end

  # Apply counter rules without mutating the socket directly.
  defp update_count("dec", count, _initial, step), do: count - step
  defp update_count("inc", count, _initial, step), do: count + step
  defp update_count("reset", _count, initial, _step), do: initial
  defp update_count(_action, count, _initial, _step), do: count

  # Render the counter UI with stable DOM IDs for tests.
  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="card bg-base-200 border-base-300 border p-6 shadow-sm">
        <.header>
          Server Counter
          <:subtitle>LiveView keeps the count in sync.</:subtitle>
        </.header>

        <div class="flex items-center justify-between gap-6" id="home-counter">
          <output id="home-counter-value" class="text-5xl font-semibold">
            {@count}
          </output>

          <div class="flex gap-2">
            <.button
              id="home-counter-dec"
              phx-click="counter"
              phx-value-action="dec"
              class="btn-outline"
            >
              -1
            </.button>
            <.button
              id="home-counter-reset"
              phx-click="counter"
              phx-value-action="reset"
              class="btn-ghost"
            >
              Reset
            </.button>
            <.button
              id="home-counter-inc"
              phx-click="counter"
              phx-value-action="inc"
            >
              +1
            </.button>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
