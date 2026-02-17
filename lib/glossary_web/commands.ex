defmodule GlossaryWeb.Commands do
  @moduledoc """
  Defines and filters executable commands for the search modal command palette.

  Commands are triggered by the `!` prefix in the search modal.
  """

  use Phoenix.VerifiedRoutes,
    endpoint: GlossaryWeb.Endpoint,
    router: GlossaryWeb.Router,
    statics: GlossaryWeb.static_paths()

  @commands [
    # Global commands
    %{
      id: "new_entry",
      label: "New Entry",
      icon: "hero-plus",
      scope: :global,
      action: {:navigate, :new_entry}
    },
    %{
      id: "new_project",
      label: "New Project",
      icon: "hero-plus",
      scope: :global,
      action: {:navigate, :new_project}
    },
    %{
      id: "new_topic",
      label: "New Topic",
      icon: "hero-plus",
      scope: :global,
      action: {:navigate, :new_topic}
    },
    %{
      id: "go_entries",
      label: "Go to Entries",
      icon: "hero-document-text",
      scope: :global,
      action: {:navigate, :entries}
    },
    %{
      id: "go_projects",
      label: "Go to Projects",
      icon: "hero-folder",
      scope: :global,
      action: {:navigate, :projects}
    },
    %{
      id: "go_topics",
      label: "Go to Topics",
      icon: "hero-tag",
      scope: :global,
      action: {:navigate, :topics}
    },
    # Context: project_show
    %{
      id: "add_entry_to_project",
      label: "Add Entry to Project",
      icon: "hero-plus-circle",
      scope: {:context, :project_show},
      action: {:action, :add_entry_to_project}
    },
    %{
      id: "edit_project",
      label: "Edit Project",
      icon: "hero-pencil-square",
      scope: {:context, :project_show},
      action: {:navigate, :edit_project}
    },
    # Context: topic_show
    %{
      id: "add_entry_to_topic",
      label: "Add Entry to Topic",
      icon: "hero-plus-circle",
      scope: {:context, :topic_show},
      action: {:action, :add_entry_to_topic}
    },
    %{
      id: "edit_topic",
      label: "Edit Topic",
      icon: "hero-pencil-square",
      scope: {:context, :topic_show},
      action: {:navigate, :edit_topic}
    }
  ]

  @doc """
  Returns commands matching the given context and query string.
  """
  def list_commands(context \\ %{}, query \\ "") do
    page = Map.get(context, :page)

    @commands
    |> Enum.filter(fn cmd ->
      case cmd.scope do
        :global -> true
        {:context, ^page} -> true
        _ -> false
      end
    end)
    |> filter_by_query(query)
  end

  @doc """
  Looks up a command by its id.
  """
  def get_command(id) do
    Enum.find(@commands, &(&1.id == id))
  end

  @doc """
  Resolves the action for a command, returning `{:navigate, path}` or `{:action, name}`.
  """
  def resolve_action(command, context \\ %{})

  def resolve_action(%{action: {:navigate, :new_entry}}, _ctx), do: {:navigate, ~p"/entries/new"}

  def resolve_action(%{action: {:navigate, :new_project}}, _ctx),
    do: {:navigate, ~p"/projects/new"}

  def resolve_action(%{action: {:navigate, :new_topic}}, _ctx), do: {:navigate, ~p"/topics/new"}
  def resolve_action(%{action: {:navigate, :entries}}, _ctx), do: {:navigate, ~p"/entries"}
  def resolve_action(%{action: {:navigate, :projects}}, _ctx), do: {:navigate, ~p"/projects"}
  def resolve_action(%{action: {:navigate, :topics}}, _ctx), do: {:navigate, ~p"/topics"}

  def resolve_action(%{action: {:navigate, :edit_project}}, ctx) do
    {:navigate, ~p"/projects/#{ctx.project}/edit"}
  end

  def resolve_action(%{action: {:navigate, :edit_topic}}, ctx) do
    {:navigate, ~p"/topics/#{ctx.topic}/edit"}
  end

  def resolve_action(%{action: {:action, _} = action}, _ctx), do: action

  defp filter_by_query(commands, ""), do: commands

  defp filter_by_query(commands, query) do
    query_down = String.downcase(query)

    Enum.filter(commands, fn cmd ->
      String.contains?(String.downcase(cmd.label), query_down)
    end)
  end
end
