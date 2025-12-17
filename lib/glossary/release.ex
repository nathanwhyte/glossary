defmodule Glossary.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :glossary

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Seeds the database with initial data.

  This function can be called from production releases using the eval command:

      bin/glossary eval "Glossary.Release.seed()"

  It runs the seed script located at priv/repo/seeds.exs
  """
  def seed do
    load_app()

    seed_file = Path.join([:code.priv_dir(@app), "repo", "seeds.exs"])

    if File.exists?(seed_file) do
      for repo <- repos() do
        Ecto.Migrator.with_repo(repo, fn _repo ->
          Code.eval_file(seed_file)
        end)
      end

      IO.puts("✓ Database seeded successfully")
      :ok
    else
      IO.puts("Seed file not found: #{seed_file}")
      {:error, :seed_file_not_found}
    end
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
