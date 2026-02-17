defmodule Glossary.Projects.Project do
  @moduledoc """
  Schema for projects.

  Projects are a lightweight grouping mechanism for entries. They have a name
  and a many-to-many relationship with entries via the `project_entries` join table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Glossary.Accounts.User
  alias Glossary.Entries.Entry

  schema "projects" do
    field :name, :string

    belongs_to :user, User

    many_to_many :entries, Entry, join_through: "project_entries"

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for a project.

  ## Params

    * `name` - The project name (required)
  """
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :projects_user_id_name_index)
  end
end
