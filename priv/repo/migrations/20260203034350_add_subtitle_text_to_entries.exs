defmodule Glossary.Repo.Migrations.AddSubtitleTextToEntries do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :subtitle_text, :text
    end
  end
end
