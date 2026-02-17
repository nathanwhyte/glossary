defmodule Glossary.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossary.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(%Glossary.Accounts.Scope{} = current_scope, attrs) do
    merged_attrs =
      attrs
      |> Enum.into(%{
        name: "some project"
      })

    {:ok, project} = Glossary.Projects.create_project(current_scope, merged_attrs)

    project
  end

  def project_fixture(attrs \\ %{}) do
    current_scope = Glossary.AccountsFixtures.user_scope_fixture()
    project_fixture(current_scope, attrs)
  end
end
