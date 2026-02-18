defmodule Glossary.Repo.Migrations.AddStatusToEntries do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :status, :string, null: false, default: "draft"
    end
  end
end
