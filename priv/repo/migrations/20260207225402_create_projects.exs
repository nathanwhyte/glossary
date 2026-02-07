defmodule Glossary.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:project_entries, primary_key: false) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :entry_id, references(:entries, on_delete: :delete_all), null: false
    end

    create unique_index(:project_entries, [:project_id, :entry_id])
    create index(:project_entries, [:entry_id])
  end
end
