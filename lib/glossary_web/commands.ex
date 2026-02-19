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
      id: "go_dashboard",
      label: "Go to Dashboard",
      icon: "hero-home",
      scope: :global,
      action: {:navigate, :dashboard}
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
    %{
      id: "new_tag",
      label: "New Tag",
      icon: "hero-plus",
      scope: :global,
      action: {:navigate, :new_tag}
    },
    %{
      id: "go_tags",
      label: "Go to Tags",
      icon: "hero-hashtag",
      scope: :global,
      action: {:navigate, :tags}
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
    },
    # Context: tag_show
    %{
      id: "add_entry_to_tag",
      label: "Add Entry to Tag",
      icon: "hero-plus-circle",
      scope: {:context, :tag_show},
      action: {:action, :add_entry_to_tag}
    },
    %{
      id: "add_project_to_tag",
      label: "Add Project to Tag",
      icon: "hero-plus-circle",
      scope: {:context, :tag_show},
      action: {:action, :add_project_to_tag}
    },
    %{
      id: "edit_tag",
      label: "Edit Tag",
      icon: "hero-pencil-square",
      scope: {:context, :tag_show},
      action: {:navigate, :edit_tag}
    },
    # Context: entry_edit
    %{
      id: "entry_add_to_project",
      label: "Add to Project",
      icon: "hero-folder-plus",
      scope: {:context, :entry_edit},
      action: {:action, :add_entry_to_project_from_entry}
    },
    %{
      id: "entry_add_to_topic",
      label: "Add to Topic",
      icon: "hero-tag",
      scope: {:context, :entry_edit},
      action: {:action, :add_entry_to_topic_from_entry}
    },
    %{
      id: "entry_add_to_tag",
      label: "Add to Tag",
      icon: "hero-hashtag",
      scope: {:context, :entry_edit},
      action: {:action, :add_entry_to_tag_from_entry}
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
  Returns starter commands for the default search state.

  Context-specific commands are listed first, followed by global commands.
  """
  def starter_commands(context \\ %{}) do
    page = Map.get(context, :page)

    context_commands =
      Enum.filter(@commands, fn cmd ->
        match?({:context, ^page}, cmd.scope)
      end)

    global_commands = Enum.filter(@commands, &(&1.scope == :global))

    (context_commands ++ global_commands)
    |> Enum.uniq_by(& &1.id)
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

  def resolve_action(%{action: {:navigate, :dashboard}}, _ctx), do: {:navigate, ~p"/"}
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

  def resolve_action(%{action: {:navigate, :new_tag}}, _ctx), do: {:navigate, ~p"/tags/new"}
  def resolve_action(%{action: {:navigate, :tags}}, _ctx), do: {:navigate, ~p"/tags"}

  def resolve_action(%{action: {:navigate, :edit_tag}}, ctx) do
    {:navigate, ~p"/tags/#{ctx.tag}/edit"}
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
