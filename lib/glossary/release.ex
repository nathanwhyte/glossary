defmodule Glossary.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :glossary

  def migrate do
    load_app()

    repos()
    |> Enum.each(fn repo ->
      case Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true)) do
        {:ok, _, _} ->
          require Logger
          Logger.info("Successfully migrated #{inspect(repo)}")

        {:error, error} ->
          require Logger
          Logger.error("Migration failed for #{inspect(repo)}: #{inspect(error)}")
          raise "Migration failed for #{inspect(repo)}: #{inspect(error)}"
      end
    end)
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Many platforms require SSL when connecting to the database
    Application.ensure_all_started(:ssl)
    Application.ensure_loaded(@app)
  end
end
