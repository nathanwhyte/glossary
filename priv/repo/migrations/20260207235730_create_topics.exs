defmodule Glossary.Repo.Migrations.CreateTopics do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:entry_topics, primary_key: false) do
      add :topic_id, references(:topics, on_delete: :delete_all), null: false
      add :entry_id, references(:entries, on_delete: :delete_all), null: false
    end

    create unique_index(:entry_topics, [:topic_id, :entry_id])
    create index(:entry_topics, [:entry_id])
  end
end
