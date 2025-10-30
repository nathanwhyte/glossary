defmodule Glossary.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto", "")

    create table(:entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :slug, :string
      add :description, :string
      add :content, :string
      # TODO: add `status` field (draft, published, archived, etc.)

      timestamps(type: :utc_datetime)
    end
  end
end
