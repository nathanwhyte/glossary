defmodule Glossary.Repo.Migrations.AddAiFields do
  use Ecto.Migration

  def change do
    alter table(:entries) do
      add :summary, :text
      add :ai_tags, :jsonb, default: "[]"
    end

    alter table(:projects) do
      add :summary, :text
    end
  end
end
