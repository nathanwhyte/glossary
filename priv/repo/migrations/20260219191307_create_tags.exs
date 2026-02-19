defmodule Glossary.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:tags, [:user_id])
    create unique_index(:tags, [:user_id, :name])

    create table(:entry_tags, primary_key: false) do
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :entry_id, references(:entries, on_delete: :delete_all), null: false
    end

    create unique_index(:entry_tags, [:tag_id, :entry_id])
    create index(:entry_tags, [:entry_id])

    create table(:project_tags, primary_key: false) do
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
    end

    create unique_index(:project_tags, [:tag_id, :project_id])
    create index(:project_tags, [:project_id])
  end
end
