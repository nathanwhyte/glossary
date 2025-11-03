defmodule Glossary.Repo.Migrations.ProjectHasManyEntries do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :project_id, references(:projects, type: :binary_id)
    end
  end
end
