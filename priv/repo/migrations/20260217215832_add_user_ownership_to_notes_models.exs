defmodule Glossary.Repo.Migrations.AddUserOwnershipToNotesModels do
  use Ecto.Migration

  def up do
    execute("DELETE FROM entry_topics", "")
    execute("DELETE FROM project_entries", "")
    execute("DELETE FROM topics", "")
    execute("DELETE FROM projects", "")
    execute("DELETE FROM entries", "")

    alter table(:entries) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    alter table(:projects) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    alter table(:topics) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end

    create index(:entries, [:user_id])
    create index(:projects, [:user_id])
    create index(:topics, [:user_id])

    create unique_index(:projects, [:user_id, :name])
    create unique_index(:topics, [:user_id, :name])
  end

  def down do
    drop_if_exists unique_index(:topics, [:user_id, :name])
    drop_if_exists unique_index(:projects, [:user_id, :name])

    drop_if_exists index(:topics, [:user_id])
    drop_if_exists index(:projects, [:user_id])
    drop_if_exists index(:entries, [:user_id])

    alter table(:topics) do
      remove :user_id
    end

    alter table(:projects) do
      remove :user_id
    end

    alter table(:entries) do
      remove :user_id
    end
  end
end
