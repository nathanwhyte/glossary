defmodule GlossaryWeb.EntryLayouts do
  @moduledoc """
  This module holds layouts used for entry-related pages.
  """
  use GlossaryWeb, :html

  @doc """
  Renders a table layout for displaying entries.
  """

  attr :table_title, :string, required: true, doc: "the title of the table"
  attr :table_rows, :list, required: true, doc: "list of entries to display"

  def entry_table(assigns) do
    ~H"""
    <.header>
      {@table_title}
      <:actions>
        <.button variant="primary" navigate={~p"/entries/new"}>
          <.icon name="hero-plus" /> New Entry
        </.button>
      </:actions>
    </.header>

    <.table
      id="entries"
      rows={@table_rows}
      row_click={fn {_id, entry} -> JS.navigate(~p"/entries/#{entry}") end}
    >
      <:col :let={{_id, entry}} label="Title">{entry.title}</:col>
      <:col :let={{_id, entry}} label="Subtitle">{entry.subtitle}</:col>
      <:action :let={{_id, entry}}>
        <div class="sr-only">
          <.link navigate={~p"/entries/#{entry}"}>Show</.link>
        </div>
        <.link navigate={~p"/entries/#{entry}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, entry}}>
        <.link
          phx-click={JS.push("delete", value: %{id: entry.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    """
  end
end
