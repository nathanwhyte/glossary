defmodule GlossaryWeb.EntryLive.New do
  @moduledoc """
  LiveView for creating a new entry.

  Simply creates a blank entry and redirects to the edit page.
  """
  use GlossaryWeb, :live_view

  alias Glossary.Entries

  @impl true
  def mount(_params, _session, socket) do
    {:ok, new_entry} = Entries.create_entry(socket.assigns.current_scope, %{})
    {:ok, push_navigate(socket, to: ~p"/entries/#{new_entry.id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>Creating new entry...</div>
    """
  end
end
