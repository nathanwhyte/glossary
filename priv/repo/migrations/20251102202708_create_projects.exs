defmodule Glossary.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, default: ""
      add :description, :string, default: ""

      # IDEA: store project icon and its styling

      timestamps(type: :utc_datetime)
    end
  end
end
