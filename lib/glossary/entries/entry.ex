defmodule Glossary.Entries.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "entries" do
    field :title, :string
    field :slug, :string
    field :description, :string
    field :content, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :slug, :description, :content])
    |> validate_required([:title, :slug, :description, :content])
  end
end
