defmodule Glossary.Repo.Migrations.EntriesJoinTables do
  use Ecto.Migration

  def change do
    create table(:entries_tags, primary_key: false) do
      add :entry_id, references(:entries, type: :binary_id, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, type: :binary_id, on_delete: :delete_all), null: false
    end

    create unique_index(:entries_tags, [:entry_id, :tag_id])

    create table(:entries_topics, primary_key: false) do
      add :entry_id, references(:entries, type: :binary_id, on_delete: :delete_all), null: false
      add :topic_id, references(:topics, type: :binary_id, on_delete: :delete_all), null: false
    end

    create unique_index(:entries_topics, [:entry_id, :topic_id])
  end
end
