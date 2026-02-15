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

  attr :allow_delete, :boolean,
    default: false,
    doc: "whether to show delete buttons for each entry"

  def entry_table(assigns) do
    ~H"""
    <div class="max-w-7xl space-y-2">
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
            <span class="font-semibold">
              {entry.title_text}
            </span>
          <% end %>
        </:col>
        <:col :let={{_id, entry}} label="Subtitle">
          <%= if !entry.subtitle_text || String.length(entry.subtitle_text) <= 0 do %>
            <em class="text-base-content/25 italic">No Subtitle</em>
          <% else %>
            <span class="text-base-content/50 text-sm">
              {entry.subtitle_text}
            </span>
          <% end %>
        </:col>
        <:col :let={{_id, entry}} label="Projects">
          <%= if !entry.projects || length(entry.projects) <= 0 do %>
            <em class="text-base-content/25 italic">None</em>
          <% else %>
            <div class="flex flex-wrap gap-1">
              <%= for project <- entry.projects do %>
                <div class="badge badge-sm badge-accent text-nowrap">
                  {project.name}
                </div>
              <% end %>
            </div>
          <% end %>
        </:col>
        <:col :let={{_id, entry}} label="Topics">
          <%= if !entry.topics || length(entry.topics) <= 0 do %>
            <em class="text-base-content/25 italic">None</em>
          <% else %>
            <div class="flex flex-wrap">
              <%= for topic <- entry.topics do %>
                <div class="badge badge-sm badge-primary text-nowrap">
                  {topic.name}
                </div>
              <% end %>
            </div>
          <% end %>
        </:col>
        <:action :let={{_id, entry}}>
          <.link
            :if={@allow_delete}
            href="#"
            phx-click="delete"
            phx-value-id={entry.id}
            data-confirm="Are you sure you want to delete this entry?"
            data-disable-with="Deleting..."
          >
            <.icon
              name="hero-trash-micro"
              class="size-4 text-base-content/25 transition-colors hover:bg-error/75 focus:bg-error/75"
            />
          </.link>
        </:action>
        <:action :let={{_id, entry}}>
          <.link navigate={~p"/entries/#{entry}"}>
            <.icon name="hero-chevron-right-micro" class="size-4 text-base-content/25" />
          </.link>
        </:action>
      </.table>
    </div>
    """
  end
end
