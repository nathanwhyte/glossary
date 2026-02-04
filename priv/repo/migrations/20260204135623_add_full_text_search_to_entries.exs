defmodule Glossary.Repo.Migrations.AddFullTextSearchToEntries do
  use Ecto.Migration

  def up do
    alter table(:entries) do
      add :search_tsv, :tsvector
    end

    # Backfill existing rows
    execute """
    UPDATE entries SET search_tsv =
      setweight(to_tsvector('english', coalesce(title_text, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(subtitle_text, '')), 'B') ||
      setweight(to_tsvector('english', coalesce(body_text, '')), 'C')
    """

    execute """
    CREATE INDEX entries_search_tsv_gin ON entries USING gin (search_tsv)
    """

    # Trigger: auto-update search_tsv when text fields change
    execute """
    CREATE OR REPLACE FUNCTION entries_search_tsv_trigger() RETURNS trigger AS $$
    BEGIN
      NEW.search_tsv :=
        setweight(to_tsvector('english', coalesce(NEW.title_text, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.subtitle_text, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(NEW.body_text, '')), 'C');
      RETURN NEW;
    END
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE TRIGGER entries_search_tsv_update
    BEFORE INSERT OR UPDATE OF title_text, subtitle_text, body_text
    ON entries
    FOR EACH ROW EXECUTE FUNCTION entries_search_tsv_trigger()
    """
  end

  def down do
    execute "DROP TRIGGER IF EXISTS entries_search_tsv_update ON entries"
    execute "DROP FUNCTION IF EXISTS entries_search_tsv_trigger()"
    execute "DROP INDEX IF EXISTS entries_search_tsv_gin"

    alter table(:entries) do
      remove :search_tsv
    end
  end
end
