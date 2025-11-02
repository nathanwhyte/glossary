defmodule Glossary.Entries.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "entries" do
    field :title, :string, default: ""
    field :description, :string, default: ""
    field :body, :string, default: ""
    field :status, Ecto.Enum, values: [:Draft, :Published, :Archived], default: :Draft

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :description, :body, :status])
    |> validate_required([:status])
  end
end
