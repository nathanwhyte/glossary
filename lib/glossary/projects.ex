defmodule Glossary.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Accounts.Scope
  alias Glossary.Entries.Entry
  alias Glossary.Projects.Project
  alias Glossary.Repo

  @doc """
  Returns the list of projects for the current scope, ordered by name.
  """
  def list_projects(%Scope{} = current_scope) do
    user_id = scope_user_id!(current_scope)

    Project
    |> where([p], p.user_id == ^user_id)
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single project with its entries preloaded from the current scope.

  Raises `Ecto.NoResultsError` if the Project does not exist.
  """
  def get_project!(%Scope{} = current_scope, id) do
    user_id = scope_user_id!(current_scope)

    Project
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.preload(:entries)
  end

  @doc """
  Creates a project in the current scope.
  """
  def create_project(%Scope{} = current_scope, attrs) do
    %Project{user_id: scope_user_id!(current_scope)}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project in the current scope.
  """
  def update_project(%Scope{} = current_scope, %Project{} = project, attrs) do
    project
    |> ensure_project_owned!(current_scope)
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project in the current scope.
  """
  def delete_project(%Scope{} = current_scope, %Project{} = project) do
    project
    |> ensure_project_owned!(current_scope)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.
  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  @doc """
  Adds an entry to a project in the current scope.
  """
  def add_entry(%Scope{} = current_scope, %Project{} = project, %Entry{} = entry) do
    project = ensure_project_owned!(project, current_scope)
    entry = ensure_entry_owned!(entry, current_scope)

    Repo.insert_all(
      "project_entries",
      [%{project_id: project.id, entry_id: entry.id}],
      on_conflict: :nothing
    )

    {:ok, Repo.preload(project, :entries, force: true)}
  end

  @doc """
  Removes an entry from a project in the current scope.
  """
  def remove_entry(%Scope{} = current_scope, %Project{} = project, %Entry{} = entry) do
    project = ensure_project_owned!(project, current_scope)
    entry = ensure_entry_owned!(entry, current_scope)

    from(pe in "project_entries",
      where: pe.project_id == ^project.id and pe.entry_id == ^entry.id
    )
    |> Repo.delete_all()

    {:ok, Repo.preload(project, :entries, force: true)}
  end

  @doc """
  Returns entries that are NOT in the given project, within the current scope.
  """
  def available_entries(%Scope{} = current_scope, %Project{} = project, query \\ "") do
    project = ensure_project_owned!(project, current_scope)
    user_id = scope_user_id!(current_scope)

    existing_ids =
      from(pe in "project_entries",
        where: pe.project_id == ^project.id,
        select: pe.entry_id
      )

    base =
      from(e in Entry,
        where: e.user_id == ^user_id,
        where: e.id not in subquery(existing_ids),
        order_by: [desc: e.updated_at],
        limit: 20
      )

    query = String.trim(query)

    if query == "" do
      Repo.all(base)
    else
      from(e in base,
        where: fragment("similarity(title_text, ?) > 0.1", ^query),
        order_by: [desc: fragment("similarity(title_text, ?)", ^query)]
      )
      |> Repo.all()
    end
  end

  @doc """
  Searches projects by name using trigram similarity in the current scope.
  """
  def search_projects(%Scope{} = current_scope, query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search_projects(current_scope, query)
  end

  defp do_search_projects(%Scope{} = current_scope, query) do
    user_id = scope_user_id!(current_scope)

    from(p in Project,
      where: p.user_id == ^user_id,
      where: fragment("similarity(name, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(name, ?)", ^query)],
      limit: 5
    )
    |> Repo.all()
  end

  defp scope_user_id!(%Scope{user: %{id: user_id}}) when not is_nil(user_id), do: user_id

  defp ensure_project_owned!(%Project{user_id: user_id} = project, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: project,
      else: raise(Ecto.NoResultsError, queryable: Project)
  end

  defp ensure_entry_owned!(%Entry{user_id: user_id} = entry, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: entry,
      else: raise(Ecto.NoResultsError, queryable: Entry)
  end
end
