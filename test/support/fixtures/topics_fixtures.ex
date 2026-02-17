defmodule Glossary.TopicsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossary.Topics` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(%Glossary.Accounts.Scope{} = current_scope, attrs) do
    merged_attrs =
      attrs
      |> Enum.into(%{
        name: "some topic"
      })

    {:ok, topic} = Glossary.Topics.create_topic(current_scope, merged_attrs)

    topic
  end

  def topic_fixture(attrs \\ %{}) do
    current_scope = Glossary.AccountsFixtures.user_scope_fixture()
    topic_fixture(current_scope, attrs)
  end
end
