defmodule Glossary.Projects do
  @moduledoc """
  The Projects context provides functions for managing projects.
  """

  alias Glossary.Entries.Project
  alias Glossary.Repo

  @doc """
  Lists all projects.
  """
  def list_projects do
    Repo.all(Project)
  end

  @doc """
  Lists all projects.
  """
  def list_recent_projects(limit \\ 5) do
    import Ecto.Query

    Repo.all(
      from p in Project,
        select: [:id, :name, :updated_at],
        order_by: [desc: p.updated_at],
        limit: ^limit
    )
  end

  @doc """
  Gets a single project by ID.
  """
  def get_project!(id), do: Repo.get!(Project, id)
end
