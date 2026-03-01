defmodule Glossary.AI do
  @moduledoc """
  AI-powered content generation for entries and projects.

  Uses Ollama (local) or OpenAI (cloud) via the OpenAI-compatible
  chat completions API. Runs LLM calls asynchronously via Task.Supervisor.
  """

  alias Glossary.AI.LLM
  alias Glossary.Entries.Entry
  alias Glossary.Projects.Project
  alias Glossary.Repo

  @doc """
  Generates a summary and AI tags for an entry asynchronously.

  Sends `{:ai_generated, entry_id}` to `notify_pid` (defaults to caller) on success,
  or `{:ai_error, entry_id, reason}` on failure.
  """
  def generate_entry_ai(%Entry{} = entry, notify_pid \\ nil) do
    if enabled?() and has_content?(entry) do
      pid = notify_pid || self()

      Task.Supervisor.start_child(Glossary.TaskSupervisor, fn ->
        do_generate_entry_ai(entry, pid)
      end)
    end
  end

  @doc """
  Generates a summary for a project from its entries asynchronously.

  Sends `{:project_ai_generated, project_id}` to `notify_pid` on success,
  or `{:project_ai_error, project_id, reason}` on failure.
  """
  def generate_project_summary(%{entries: entries} = project, notify_pid \\ nil)
      when is_list(entries) do
    if enabled?() do
      pid = notify_pid || self()

      Task.Supervisor.start_child(Glossary.TaskSupervisor, fn ->
        do_generate_project_summary(project, pid)
      end)
    end
  end

  defp do_generate_entry_ai(entry, pid) do
    with {:ok, summary} <- generate_summary(entry),
         {:ok, tags} <- generate_tags(entry) do
      {:ok, _} =
        entry
        |> Entry.changeset(%{summary: summary, ai_tags: tags})
        |> Repo.update()

      send(pid, {:ai_generated, entry.id})
    else
      {:error, reason} ->
        send(pid, {:ai_error, entry.id, reason})
    end
  end

  defp do_generate_project_summary(project, pid) do
    entries_context =
      project.entries
      |> Enum.filter(&has_content?/1)
      |> Enum.map_join("\n\n---\n\n", fn entry ->
        "## #{entry.title_text}\n#{entry.body_text}"
      end)

    if entries_context == "" do
      send(pid, {:project_ai_error, project.id, :no_content})
    else
      do_project_llm_call(project, entries_context, pid)
    end
  end

  defp do_project_llm_call(project, entries_context, pid) do
    prompt = """
    Summarize the following project that contains multiple knowledge base entries.
    Provide a 2-4 sentence overview of what this project covers.

    Project: #{project.name}

    Entries:
    #{entries_context}
    """

    case LLM.chat([
           %{
             role: "system",
             content:
               "You are a concise technical writer. Respond with only the summary, no preamble."
           },
           %{role: "user", content: prompt}
         ]) do
      {:ok, summary} ->
        {:ok, _} =
          project
          |> Project.changeset(%{summary: summary})
          |> Repo.update()

        send(pid, {:project_ai_generated, project.id})

      {:error, reason} ->
        send(pid, {:project_ai_error, project.id, reason})
    end
  end

  defp generate_summary(entry) do
    prompt = """
    Summarize the following knowledge base entry in 1-2 concise sentences.
    Focus on the key concept or information being documented.

    Title: #{entry.title_text}
    #{if entry.subtitle_text, do: "Subtitle: #{entry.subtitle_text}\n", else: ""}
    Content:
    #{entry.body_text}
    """

    LLM.chat([
      %{
        role: "system",
        content: "You are a concise technical writer. Respond with only the summary, no preamble."
      },
      %{role: "user", content: prompt}
    ])
  end

  defp generate_tags(entry) do
    prompt = """
    Generate 3-7 short, lowercase tags for the following knowledge base entry.
    Tags should help an AI system categorize, sort, and find this entry.
    Return ONLY a JSON array of strings, nothing else. Example: ["elixir", "web", "api"]

    Title: #{entry.title_text}
    #{if entry.subtitle_text, do: "Subtitle: #{entry.subtitle_text}\n", else: ""}
    Content:
    #{entry.body_text}
    """

    case LLM.chat([
           %{
             role: "system",
             content:
               "You are a tagging system. Respond with only a JSON array of lowercase strings."
           },
           %{role: "user", content: prompt}
         ]) do
      {:ok, content} ->
        parse_tags(content)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_tags(content) do
    case Jason.decode(content) do
      {:ok, tags} when is_list(tags) ->
        {:ok, Enum.filter(tags, &is_binary/1)}

      _ ->
        extract_tags_from_markdown(content)
    end
  end

  defp extract_tags_from_markdown(content) do
    case Regex.run(~r/\[.*\]/s, content) do
      [json] -> decode_tag_array(json)
      nil -> {:ok, []}
    end
  end

  defp decode_tag_array(json) do
    case Jason.decode(json) do
      {:ok, tags} when is_list(tags) -> {:ok, Enum.filter(tags, &is_binary/1)}
      _ -> {:ok, []}
    end
  end

  defp has_content?(%{body_text: body_text}) do
    body_text != nil and String.trim(body_text) != ""
  end

  defp enabled? do
    config = Application.get_env(:glossary, Glossary.AI.LLM, [])
    Keyword.get(config, :enabled, true)
  end
end
