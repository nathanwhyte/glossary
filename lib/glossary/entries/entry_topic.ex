defmodule Glossary.Entries.EntryTopic do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glossary.Entries.{Entry, Topic}

  @primary_key false
  schema "entries_topics" do
    belongs_to :entry, Entry, type: :binary_id
    belongs_to :topic, Topic, type: :binary_id
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :description, :body, :status])
    |> validate_required([:status])
  end
end
