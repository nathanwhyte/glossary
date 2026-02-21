defmodule Glossary.Repo.Migrations.AddTrigramIndexesToProjectsTopicsTags do
  use Ecto.Migration

  def up do
    execute """
    CREATE INDEX projects_name_trgm_gin
    ON projects
    USING gin (name gin_trgm_ops)
    """

    execute """
    CREATE INDEX topics_name_trgm_gin
    ON topics
    USING gin (name gin_trgm_ops)
    """

    execute """
    CREATE INDEX tags_name_trgm_gin
    ON tags
    USING gin (name gin_trgm_ops)
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS projects_name_trgm_gin"
    execute "DROP INDEX IF EXISTS topics_name_trgm_gin"
    execute "DROP INDEX IF EXISTS tags_name_trgm_gin"
  end
end
