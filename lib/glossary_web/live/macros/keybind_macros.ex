defmodule GlossaryWeb.KeybindMacros do
  @moduledoc """
  Macros for common LiveView event handling patterns.
  """

  @doc """
  Macro for handling simple assign events.
  """
  defmacro handle_assign_event(event_name, assign_key, value) do
    quote do
      def handle_event(unquote(event_name), _params, socket) do
        {:noreply, assign(socket, unquote(assign_key), unquote(value))}
      end
    end
  end

  @doc """
  Macro for handling toggle events.
  """
  defmacro handle_toggle_event(event_name, assign_key) do
    quote do
      def handle_event(unquote(event_name), _params, socket) do
        {:noreply, assign(socket, unquote(assign_key), !socket.assigns[unquote(assign_key)])}
      end
    end
  end

  @doc """
  Macro for handling keyboard events with leader key support.
  """
  defmacro handle_keyboard_events do
    quote do
      def handle_event("key_down", %{"key" => key}, socket) do
        case key do
          "Meta" ->
            {:noreply, assign(socket, :leader_down, true)}

          "Control" ->
            {:noreply, assign(socket, :leader_down, true)}

          "k" ->
            if socket.assigns.leader_down do
              {:noreply, assign(socket, show_search_modal: !socket.assigns.show_search_modal)}
            else
              {:noreply, socket}
            end

          "Escape" ->
            if socket.assigns.leader_down do
              {:noreply, assign(socket, show_search_modal: false)}
            else
              {:noreply, socket}
            end

          _ ->
            {:noreply, socket}
        end
      end

      def handle_event("key_up", %{"key" => key}, socket) do
        case key do
          "Meta" ->
            {:noreply, assign(socket, :leader_down, false)}

          "Control" ->
            {:noreply, assign(socket, :leader_down, false)}

          _ ->
            {:noreply, socket}
        end
      end
    end
  end
end
