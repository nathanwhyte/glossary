defmodule GlossaryWeb.LiveLayouts do
  @moduledoc """
  Reusable layout components for LiveView pages.
  """
  use GlossaryWeb, :html

  attr :navigate, :any, required: true, doc: "the target path for the back link"
  attr :text, :string, required: true, doc: "the back link text"

  def back_link(assigns) do
    ~H"""
    <div class="-ml-1.5 flex items-center justify-between">
      <.link
        navigate={@navigate}
        class="link link-hover text-base-content/25 mb-4 -ml-1.5 flex items-center text-sm font-semibold"
      >
        <.icon name="hero-chevron-left-micro" class="size-4 mr-1" />{@text}
      </.link>
    </div>
    """
  end
end
