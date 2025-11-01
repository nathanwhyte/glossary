defmodule GlossaryWeb.NewEntryLive do
  @moduledoc """
  LiveView for creating a new entry.

  Simply creates a blank entry and redirects to the edit page.
  """
  use GlossaryWeb, :live_view

  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @impl true
  def mount(_params, _session, socket) do
    # Create a new blank entry and redirect to its edit page
    {:ok, new_entry} = Repo.insert(%Entry{})
    {:ok, push_navigate(socket, to: ~p"/entries/#{new_entry.id}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>Creating new entry...</div>
    """
  end
end
