defmodule Glossary.Entries.Entry do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossary.Entries.{Project, Tag, Topic}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "entries" do
    field :title, :string, default: ""
    field :description, :string, default: ""
    field :body, :string, default: ""
    field :status, Ecto.Enum, values: [:Draft, :Published, :Archived], default: :Draft

    belongs_to :project, Project

    many_to_many :tags, Tag, join_through: "entries_tags", on_replace: :delete
    many_to_many :topics, Topic, join_through: "entries_topics", on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :description, :body, :status, :project_id])
    |> validate_required([:status])
  end
end
