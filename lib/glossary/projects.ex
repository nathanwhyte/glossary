defmodule Glossary.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias Glossary.Repo

  alias Glossary.Projects.Project
  alias Glossary.Entries.Entry

  @doc """
  Returns the list of projects, ordered by name.

  ## Examples

      iex> list_projects()
      [%Project{}, ...]

  """
  def list_projects do
    Project
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single project with its entries preloaded.

  Raises `Ecto.NoResultsError` if the Project does not exist.

  ## Examples

      iex> get_project!(123)
      %Project{entries: [%Entry{}, ...]}

      iex> get_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_project!(id) do
    Project
    |> Repo.get!(id)
    |> Repo.preload(:entries)
  end

  @doc """
  Creates a project.

  ## Examples

      iex> create_project(%{name: "My Project"})
      {:ok, %Project{}}

      iex> create_project(%{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.

  ## Examples

      iex> update_project(project, %{name: "New Name"})
      {:ok, %Project{}}

      iex> update_project(project, %{name: nil})
      {:error, %Ecto.Changeset{}}

  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.

  ## Examples

      iex> delete_project(project)
      {:ok, %Project{}}

  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.

  ## Examples

      iex> change_project(project)
      %Ecto.Changeset{data: %Project{}}

  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  @doc """
  Adds an entry to a project.

  Inserts a row into the `project_entries` join table. Returns `{:ok, _}` on
  success or if the association already exists (uses ON CONFLICT DO NOTHING).
  """
  def add_entry(%Project{} = project, %Entry{} = entry) do
    Repo.insert_all(
      "project_entries",
      [%{project_id: project.id, entry_id: entry.id}],
      on_conflict: :nothing
    )

    {:ok, Repo.preload(project, :entries, force: true)}
  end

  @doc """
  Removes an entry from a project.

  Deletes the row from the `project_entries` join table.
  """
  def remove_entry(%Project{} = project, %Entry{} = entry) do
    from(pe in "project_entries",
      where: pe.project_id == ^project.id and pe.entry_id == ^entry.id
    )
    |> Repo.delete_all()

    {:ok, Repo.preload(project, :entries, force: true)}
  end

  @doc """
  Returns entries that are NOT in the given project, optionally filtered by a
  search query on `title_text`. Used by the entry assignment UI.
  """
  def available_entries(%Project{} = project, query \\ "") do
    existing_ids =
      from(pe in "project_entries",
        where: pe.project_id == ^project.id,
        select: pe.entry_id
      )

    base =
      from(e in Entry,
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
  Searches projects by name using trigram similarity.
  Returns projects whose name is similar to the given query.
  """
  def search_projects(query) do
    query = String.trim(query)
    if query == "", do: [], else: do_search_projects(query)
  end

  defp do_search_projects(query) do
    from(p in Project,
      where: fragment("similarity(name, ?) > 0.1", ^query),
      order_by: [desc: fragment("similarity(name, ?)", ^query)],
      limit: 5
    )
    |> Repo.all()
  end
end
