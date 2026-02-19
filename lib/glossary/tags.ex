defmodule Glossary.Tags do
  @moduledoc """
  The Tags context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Accounts.Scope
  alias Glossary.Entries.Entry
  alias Glossary.Projects.Project
  alias Glossary.Repo
  alias Glossary.Tags.Tag

  @doc """
  Returns the list of tags for the current scope, ordered by name.
  """
  def list_tags(%Scope{} = current_scope) do
    user_id = scope_user_id!(current_scope)

    Tag
    |> where([t], t.user_id == ^user_id)
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single tag with its entries and projects preloaded from the current scope.

  Raises `Ecto.NoResultsError` if the Tag does not exist.
  """
  def get_tag!(%Scope{} = current_scope, id) do
    user_id = scope_user_id!(current_scope)

    Tag
    |> Repo.get_by!(id: id, user_id: user_id)
    |> Repo.preload([:entries, :projects])
  end

  @doc """
  Creates a tag in the current scope.
  """
  def create_tag(%Scope{} = current_scope, attrs) do
    %Tag{user_id: scope_user_id!(current_scope)}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tag in the current scope.
  """
  def update_tag(%Scope{} = current_scope, %Tag{} = tag, attrs) do
    tag
    |> ensure_tag_owned!(current_scope)
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tag in the current scope.
  """
  def delete_tag(%Scope{} = current_scope, %Tag{} = tag) do
    tag
    |> ensure_tag_owned!(current_scope)
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.
  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end

  @doc """
  Adds an entry to a tag in the current scope.
  """
  def add_entry(%Scope{} = current_scope, %Tag{} = tag, %Entry{} = entry) do
    tag = ensure_tag_owned!(tag, current_scope)
    entry = ensure_entry_owned!(entry, current_scope)

    Repo.insert_all(
      "entry_tags",
      [%{tag_id: tag.id, entry_id: entry.id}],
      on_conflict: :nothing
    )

    {:ok, Repo.preload(tag, :entries, force: true)}
  end

  @doc """
  Removes an entry from a tag in the current scope.
  """
  def remove_entry(%Scope{} = current_scope, %Tag{} = tag, %Entry{} = entry) do
    tag = ensure_tag_owned!(tag, current_scope)
    entry = ensure_entry_owned!(entry, current_scope)

    from(et in "entry_tags",
      where: et.tag_id == ^tag.id and et.entry_id == ^entry.id
    )
    |> Repo.delete_all()

    {:ok, Repo.preload(tag, :entries, force: true)}
  end

  @doc """
  Adds a project to a tag in the current scope.
  """
  def add_project(%Scope{} = current_scope, %Tag{} = tag, %Project{} = project) do
    tag = ensure_tag_owned!(tag, current_scope)
    project = ensure_project_owned!(project, current_scope)

    Repo.insert_all(
      "project_tags",
      [%{tag_id: tag.id, project_id: project.id}],
      on_conflict: :nothing
    )

    {:ok, Repo.preload(tag, :projects, force: true)}
  end

  @doc """
  Removes a project from a tag in the current scope.
  """
  def remove_project(%Scope{} = current_scope, %Tag{} = tag, %Project{} = project) do
    tag = ensure_tag_owned!(tag, current_scope)
    project = ensure_project_owned!(project, current_scope)

    from(pt in "project_tags",
      where: pt.tag_id == ^tag.id and pt.project_id == ^project.id
    )
    |> Repo.delete_all()

    {:ok, Repo.preload(tag, :projects, force: true)}
  end

  @doc """
  Returns entries that are NOT tagged with the given tag, within the current scope.
  """
  def available_entries(%Scope{} = current_scope, %Tag{} = tag, query \\ "") do
    tag = ensure_tag_owned!(tag, current_scope)
    user_id = scope_user_id!(current_scope)

    existing_ids =
      from(et in "entry_tags",
        where: et.tag_id == ^tag.id,
        select: et.entry_id
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
  Returns projects that are NOT tagged with the given tag, within the current scope.
  """
  def available_projects(%Scope{} = current_scope, %Tag{} = tag, query \\ "") do
    tag = ensure_tag_owned!(tag, current_scope)
    user_id = scope_user_id!(current_scope)

    existing_ids =
      from(pt in "project_tags",
        where: pt.tag_id == ^tag.id,
        select: pt.project_id
      )

    base =
      from(p in Project,
        where: p.user_id == ^user_id,
        where: p.id not in subquery(existing_ids),
        order_by: [desc: p.updated_at],
        limit: 20
      )

    query = String.trim(query)

    if query == "" do
      Repo.all(base)
    else
      Repo.all(from(p in base, where: ilike(p.name, ^"%#{query}%")))
    end
  end

  @doc """
  Searches tags by name using trigram similarity in the current scope.
  """
  def search_tags(%Scope{} = current_scope, query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search_tags(current_scope, query)
  end

  defp do_search_tags(%Scope{} = current_scope, query) do
    user_id = scope_user_id!(current_scope)

    from(t in Tag,
      where: t.user_id == ^user_id,
      where: fragment("similarity(name, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(name, ?)", ^query)],
      limit: 5
    )
    |> Repo.all()
  end

  defp scope_user_id!(%Scope{user: %{id: user_id}}) when not is_nil(user_id), do: user_id

  defp ensure_tag_owned!(%Tag{user_id: user_id} = tag, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: tag,
      else: raise(Ecto.NoResultsError, queryable: Tag)
  end

  defp ensure_entry_owned!(%Entry{user_id: user_id} = entry, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: entry,
      else: raise(Ecto.NoResultsError, queryable: Entry)
  end

  defp ensure_project_owned!(%Project{user_id: user_id} = project, %Scope{} = current_scope) do
    if user_id == scope_user_id!(current_scope),
      do: project,
      else: raise(Ecto.NoResultsError, queryable: Project)
  end
end
