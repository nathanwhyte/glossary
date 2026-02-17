defmodule Glossary.Topics.Topic do
  @moduledoc """
  Schema for topics.

  Topics are tags that can be attached to entries. They have a name and a
  many-to-many relationship with entries via the `entry_topics` join table.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Glossary.Accounts.User
  alias Glossary.Entries.Entry

  schema "topics" do
    field :name, :string

    belongs_to :user, User

    many_to_many :entries, Entry, join_through: "entry_topics"

    timestamps(type: :utc_datetime)
  end

  @doc """
  Builds a changeset for a topic.

  ## Params

    * `name` - The topic name (required)
  """
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name, name: :topics_user_id_name_index)
  end
end
