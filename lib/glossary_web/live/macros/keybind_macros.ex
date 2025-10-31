defmodule GlossaryWeb.KeybindMacros do
  @moduledoc """
  Macros for common LiveView event handling patterns.
  """

  alias Glossary.Repo
  alias Glossary.Entries.Entry

  @doc """
  Macro for handling simple assign events with PubSub publishing.
  """
  defmacro pubsub_broadcast(pubsub_topic, assign_key, value) do
    quote do
      Phoenix.PubSub.broadcast(
        Glossary.PubSub,
        unquote(pubsub_topic),
        {unquote(assign_key), unquote(value)}
      )
    end
  end

  @doc """
  Macro for handling simple assign events with PubSub publishing.
  """
  defmacro pubsub_broadcast_on_event(event_name, assign_key, value, pubsub_topic) do
    quote do
      def handle_event(unquote(event_name), _params, socket) do
        # not using pubsub_broadcast here, required re-quoting then unquoting again
        Phoenix.PubSub.broadcast(
          Glossary.PubSub,
          unquote(pubsub_topic),
          {unquote(assign_key), unquote(value)}
        )

        {:noreply, assign(socket, unquote(assign_key), unquote(value))}
      end
    end
  end

  @doc """
  Macro for handling keyboard events with leader key support.
  """
  defmacro keybind_listeners do
    quote do
      def handle_event("key_down", %{"key" => key}, socket) do
        case key do
          # update state of caller module
          "Meta" ->
            {:noreply, assign(socket, :leader_down, true)}

          "Control" ->
            {:noreply, assign(socket, :leader_down, true)}

          "Shift" ->
            if socket.assigns.leader_down do
              {:noreply, assign(socket, :shift_down, true)}
            else
              {:noreply, socket}
            end

          # broadcasted to parent LiveView
          "k" ->
            if socket.assigns.leader_down do
              pubsub_broadcast("search_modal", :summon_modal, true)
            end

            {:noreply, socket}

          "o" ->
            if socket.assigns.leader_down && socket.assigns.shift_down do
              # TODO: cull empty entries
              {:ok, new_entry} = Repo.insert(%Entry{})
              {:noreply, push_navigate(socket, to: ~p"/entries/#{new_entry.id}")}
            else
              {:noreply, socket}
            end

          "Escape" ->
            if socket.assigns.leader_down do
              pubsub_broadcast("search_modal", :summon_modal, false)
            end

            {:noreply, socket}

          _ ->
            {:noreply, socket}
        end
      end

      def handle_event("key_up", %{"key" => key}, socket) do
        # update state of caller module
        case key do
          "Meta" ->
            {:noreply, assign(socket, :leader_down, false)}

          "Control" ->
            {:noreply, assign(socket, :leader_down, false)}

          "Shift" ->
            {:noreply, assign(socket, :shift_down, false)}

          _ ->
            {:noreply, socket}
        end
      end
    end
  end
end
