defmodule Glossary.Repo.Migrations.AddTitleTextToEntries do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :title_text, :text
    end
  end
end
