defmodule Glossary.Repo.Migrations.EntriesTags do
  use Ecto.Migration

  def change do
    create table(:entries_tags, primary_key: false) do
      add :entry_id, references(:entries, type: :binary_id, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:entries_tags, [:entry_id, :tag_id])
  end
end
