defmodule Glossary.Entries.EntryTag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossary.Entries.{Entry, Tag}

  @primary_key false
  schema "entries_tags" do
    belongs_to :entry, Entry, type: :binary_id
    belongs_to :tag, Tag, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :description, :body, :status])
    |> validate_required([:status])
  end
end
