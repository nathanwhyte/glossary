defmodule Glossary.Entries.Entry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "entries" do
    field :title, :string
    field :subtitle, :string
    field :body, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:title, :subtitle, :body])
    |> validate_required([:title, :subtitle, :body])
  end
end
