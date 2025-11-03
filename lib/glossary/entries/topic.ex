defmodule Glossary.Entries.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  alias Glossary.Entries.Entry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "topics" do
    field :name, :string
    field :description, :string

    many_to_many :entries, Entry,
      join_through: "entries_topics",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
  end
end
