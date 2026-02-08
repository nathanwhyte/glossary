defmodule Glossary.TopicsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glossary.Topics` context.
  """

  @doc """
  Generate a topic.
  """
  def topic_fixture(attrs \\ %{}) do
    {:ok, topic} =
      attrs
      |> Enum.into(%{
        name: "some topic"
      })
      |> Glossary.Topics.create_topic()

    topic
  end
end
