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
    <div class="text-center">
      <h1 class="text-4xl font-bold text-base-content mb-6">
        Welcome to Glossary
      </h1>
    </div>
    """
  end
end
