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
    <div class="space-y-2">
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
        <:col :let={{_id, entry}} label="Title">
          <%= if !entry.title_text || String.length(entry.title_text) <= 0 do %>
            <em class="text-base-content/25 italic">No Title</em>
          <% else %>
            {entry.title_text}
          <% end %>
        </:col>
        <:col :let={{_id, entry}} label="Subtitle">
          <%= if !entry.subtitle_text || String.length(entry.subtitle_text) <= 0 do %>
            <em class="text-base-content/25 italic">No Subtitle</em>
          <% else %>
            {entry.subtitle_text}
          <% end %>
        </:col>
        <:action :let={{_id, entry}}>
          <.link
            href="#"
            phx-click="delete"
            phx-value-id={entry.id}
            data-confirm="Are you sure you want to delete this entry?"
            data-disable-with="Deleting..."
          >
            Delete
          </.link>
        </:action>
        <:action :let={{_id, entry}}>
          <.link navigate={~p"/entries/#{entry}"}>View</.link>
        </:action>
      </.table>
    </div>
    """
  end
end
