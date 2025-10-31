defmodule Glossary.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS pgcrypto", "")

    create table(:entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, default: ""
      add :description, :string, default: ""
      add :content, :text, default: ""
      add :status, :string, default: "draft"

      timestamps(type: :utc_datetime)
    end
  end
end
