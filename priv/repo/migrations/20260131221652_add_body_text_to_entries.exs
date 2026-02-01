defmodule Glossary.Repo.Migrations.AddBodyTextToEntries do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :body_text, :text
    end
  end
end
