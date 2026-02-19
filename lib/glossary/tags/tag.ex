defmodule Glossary.Tags.Tag do
  @moduledoc """
  Schema for tags.

  Tags are labels that can be attached to entries and projects. They have a name
  and many-to-many relationships with entries via `entry_tags` and with projects
  via `project_tags` join tables.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Glossary.Accounts.User
  alias Glossary.Entries.Entry
  alias Glossary.Projects.Project

  schema "tags" do
    field :name, :string

    belongs_to :user, User

    many_to_many :entries, Entry, join_through: "entry_tags"
    many_to_many :projects, Project, join_through: "project_tags"

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for a tag.

  ## Params

    * `name` - The tag name (required)
  """
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :tags_user_id_name_index)
  end
end
