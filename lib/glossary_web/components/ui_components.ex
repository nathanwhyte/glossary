defmodule GlossaryWeb.Components.UiComponents do
  @moduledoc """
  Small, reusable UI components.
  """

  use Phoenix.Component

  @doc """
  Renders an attribute badge for displaying entry attributes.

  ## Examples

      <.attribute_badge attribute="@lambda" />
      <.attribute_badge attribute="#aws" />
  """
  attr :attribute, :string, required: true, doc: "the entry's attribute"

  def attribute_badge(assigns) do
    ~H"""
    <code class="badge badge-xs bg-base-content/10 border-none">
      {@attribute}
    </code>
    """
  end
end
