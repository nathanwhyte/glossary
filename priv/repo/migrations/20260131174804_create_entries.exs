defmodule Glossary.Repo.Migrations.CreateEntries do
  use Ecto.Migration

  def change do
    create table(:entries) do
      add :title, :string
      add :subtitle, :string
      add :body, :text

      timestamps(type: :utc_datetime)
    end
  end
end
