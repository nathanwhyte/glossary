defmodule Glossary.Repo.Migrations.AddTrigramIndexToEntries do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"

    execute """
    CREATE INDEX entries_title_text_trgm_gin
    ON entries
    USING gin (title_text gin_trgm_ops)
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS entries_title_text_trgm_gin"
    execute "DROP EXTENSION IF EXISTS pg_trgm"
  end
end
