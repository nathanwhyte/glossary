defmodule Glossary.Entries.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossary.Entries.Entry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string, default: ""
    field :description, :string, default: ""

    has_many :entries, Entry

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
