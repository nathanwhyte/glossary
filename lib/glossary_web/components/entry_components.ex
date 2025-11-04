defmodule GlossaryWeb.Components.EntryComponents do
  @moduledoc """
  Entry-specific UI components for displaying glossary entries.

  These components are used throughout the application to display
  entry information in a consistent way.
  """

  use GlossaryWeb, :html

  alias Glossary.Entries.{Entry, Project}

  @doc """
  Renders a card displaying an entry's information.

  ## Examples

      <.entry_card entry={entry} timezone="America/New_York" />
  """
  attr :entry, Entry, required: true, doc: "the entry to display"
  attr :timezone, :string, required: true, doc: "the timezone for displaying timestamps"

  def entry_card(assigns) do
    ~H"""
    <div class="card card-sm border-base-content/20 border shadow-md">
      <div class="card-body">
        <div class="flex items-center gap-2">
          <%= if @entry.title != "" do %>
            <div class="recent-entry-title">
              {Phoenix.HTML.raw(@entry.title)}
            </div>
          <% else %>
            <div class="recent-entry-title text-base-content/25 italic">
              No Title
            </div>
          <% end %>
          <div class="text-base-content/50 mx-1 shrink-0">
            <.icon name="hero-ellipsis-horizontal-mini" class="size-5" />
          </div>
        </div>
        <div :if={@entry.description != ""} class="recent-entry-description">
          {Phoenix.HTML.raw(@entry.description)}
        </div>
        <div class="flex items-center gap-3 pt-1">
          <.status_indicator status={@entry.status} />
          <.project_select project={@entry.project} />
          <.topic_badges topics={@entry.topics} />
          <.tag_badges tags={@entry.tags} />
        </div>

        <div class="flex items-center justify-between">
          <.last_updated_timestamp updated={@entry.updated_at} timezone={@timezone} />
          <.button class="btn btn-ghost btn-xs" navigate={~p"/entries/#{@entry.id}"}>
            Edit <.icon name="hero-pencil-square-micro" class="size-3.5" />
          </.button>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a status indicator badge for an entry.

  ## Examples

      <.status_indicator status={:Published} />
      <.status_indicator status={:Draft} />
  """
  attr :status, :atom, required: true, doc: "the entry status (:Published or :Draft)"

  def status_indicator(assigns) do
    base_style = "badge badge-xs join-item font-medium"

    assigns =
      assign(
        assigns,
        :style,
        base_style <>
          if(assigns[:status] == :Published,
            do: " badge-success",
            else: " badge-warning"
          )
      )

    ~H"""
    <div class="join">
      <span class="badge badge-xs bg-base-content/5 border-base-content/10 join-item">
        Status
      </span>
      <span class={@style}>
        {@status}
      </span>
    </div>
    """
  end

  @doc """
  Renders a project selector badge for an entry.

  ## Examples

      <.project_select project={project} />
      <.project_select project={nil} />
  """
  attr :project, Project, default: nil, doc: "the entry's project, or nil if none"

  def project_select(assigns) do
    base_style = "badge badge-xs join-item font-medium"

    assigns =
      assign(
        assigns,
        :style,
        base_style <>
          if(is_nil(assigns[:project]),
            do: " border-base-content/10",
            else: " badge-secondary"
          )
      )
      |> assign_new(:project_name, fn ->
        if is_nil(assigns[:project]), do: "None", else: assigns.project.name
      end)

    ~H"""
    <div class="join">
      <span class="badge badge-xs bg-base-content/5 border-base-content/10 join-item">
        Project
      </span>
      <span class={@style}>
        {@project_name} <.icon name="hero-chevron-up-down-micro" class="size-3 -mx-0.5" />
      </span>
    </div>
    """
  end

  @doc """
  Renders topic badges for an entry.

  ## Examples

      <.topic_badges topics={[%{name: "AWS"}, %{name: "Cloud"}]} />
      <.topic_badges topics={[]} />
  """
  attr :topics, :list, required: true, doc: "the list of topics for the entry"

  def topic_badges(assigns) do
    ~H"""
    <div class="flex items-center gap-1.5 text-xs">
      <div>Topics</div>
      <%= if length(@topics) <= 0 do %>
        <div class="text-base-content/25 pl-1 font-semibold italic">
          None
        </div>
      <% else %>
        <%= for topic <- @topics do %>
          <div class="badge badge-info badge-xs font-semibold">
            #{topic.name}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders tag badges for an entry.

  ## Examples

      <.tag_badges tags={[%{name: "lambda"}, %{name: "serverless"}]} />
      <.tag_badges tags={[]} />
  """
  attr :tags, :list, required: true, doc: "the list of tags for the entry"

  def tag_badges(assigns) do
    ~H"""
    <div class="flex items-center gap-1.5 text-xs">
      <div>Tags</div>
      <%= if length(@tags) <= 0 do %>
        <div class="text-base-content/25 pl-1 font-semibold italic">
          None
        </div>
      <% else %>
        <%= for tag <- @tags do %>
          <div class="badge badge-primary badge-xs font-semibold">
            @{tag.name}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a formatted last updated timestamp for an entry.

  ## Examples

      <.last_updated_timestamp updated={~U[2024-01-15 10:30:00Z]} timezone="America/New_York" />
  """
  attr :updated, DateTime, required: true, doc: "the DateTime when the entry was last updated"
  attr :timezone, :string, required: true, doc: "the timezone to display the timestamp in"

  def last_updated_timestamp(assigns) do
    updated_localized =
      case DateTime.shift_zone(assigns.updated, assigns.timezone) do
        {:ok, dt} -> dt
        {:error, _reason} -> assigns.updated
      end

    assigns = assign(assigns, :updated_localized, updated_localized)

    ~H"""
    <div class="text-base-content/50 pt-1 text-xs">
      Updated
      <span class="font-semibold">
        {@updated_localized |> Calendar.strftime("%a, %m/%d/%y")}
      </span>
      at
      <span class="font-semibold">
        {@updated_localized |> Calendar.strftime("%H:%M")}
      </span>
    </div>
    """
  end
end
