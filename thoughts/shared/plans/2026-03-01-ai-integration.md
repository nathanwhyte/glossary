# AI Integration Implementation Plan

## Overview

Add AI-powered summary and tag generation to the glossary app using Ollama (local) with OpenAI as a fallback. A thin Req-based LLM client module targets the OpenAI-compatible `/v1/chat/completions` endpoint that both Ollama and OpenAI expose. Entry summaries and AI tags are generated automatically on save (when missing) or on button click, and project summaries are generated on demand.

## Current State Analysis

- **Entry schema** (`lib/glossary/entries/entry.ex:29-45`): Has `title`/`title_text`, `subtitle`/`subtitle_text`, `body`/`body_text`, `status`. No `summary` or `ai_tags` fields.
- **Project schema** (`lib/glossary/projects/project.ex:15-24`): Has only `name`. No `summary` field.
- **No HTTP client**: `Req` is the preferred library (CLAUDE.md) but is not a dependency.
- **No async Task usage**: All operations are synchronous within LiveView processes. No `Task.Supervisor` in the supervision tree.
- **Autosave flow** (`edit.ex:202-219`): `save_field/2` calls `Entries.upsert_entry/3`, debounces PubSub broadcasts via `Process.send_after` with a 5-second timer.
- **Entry edit page** (`edit.ex:245`): Has a placeholder `<%!-- IDEA: entry actions menu --%>` with an ellipsis icon — no click handler.
- **Project show page** (`project_live/show.ex:110-249`): Shows project name + entry table. No summary/description area.

### Key Discoveries:
- `body_text` docstring (`entry.ex:10-19`) explicitly mentions LLM context as a use case
- Ollama exposes an OpenAI-compatible API at `/v1/chat/completions` — same request/response shape
- The `ollama` hex package exists but we'll use a thin Req module for both providers
- Cache (`lib/glossary/cache.ex`) uses 5-min TTL with user-scoped tuple keys

## Desired End State

1. Entries have `summary` (text) and `ai_tags` (JSON array of strings) columns
2. Projects have a `summary` (text) column
3. A `Glossary.AI` context with an LLM client that calls Ollama locally and falls back to OpenAI
4. Entry summaries/tags auto-generate on save when missing, and regenerate on button click
5. Project summaries generate on button click from the project show page
6. AI generation runs async (Task.Supervisor) so it doesn't block the UI
7. The entry edit page shows summary and AI tags below the metadata bar, with a regenerate button
8. The project show page shows summary below the header, with a generate/regenerate button

### Verification:
- `mix test` passes
- `mix precommit` passes
- Entry edit page shows summary/tags section with regenerate button
- Project show page shows summary with generate button
- With Ollama running locally, clicking regenerate produces a summary and tags
- Auto-generation fires when saving an entry that has body content but no summary

## What We're NOT Doing

- Streaming LLM responses (we'll use non-streaming for simplicity)
- Vector embeddings or semantic search
- Topic-level summarization (only entries and projects)
- Background job processing (Oban) — we'll use `Task.Supervisor` for now
- Rate limiting or token counting
- Model selection UI — model is configured via env vars

## Implementation Approach

Four phases, each independently testable. Phase 1 lays the foundation (deps, schema, LLM client). Phase 2 wires up entry AI generation in the backend. Phase 3 adds the UI for entries. Phase 4 adds project summarization.

---

## Phase 1: Foundation — Dependencies, Schema, LLM Client

### Overview
Add `Req` dependency, create the `Glossary.AI` context with an OpenAI-compatible LLM client, add database columns, update schemas, and add configuration.

### Changes Required:

#### 1.1 Add Req Dependency

**File**: `mix.exs`
**Changes**: Add `{:req, "~> 0.5"}` to deps

#### 1.2 Migration — Entry and Project Columns

**File**: New migration via `mix ecto.gen.migration add_ai_fields`
**Changes**: Add `summary` (text) and `ai_tags` (json, default `[]`) to `entries`; add `summary` (text) to `projects`

```elixir
def change do
  alter table(:entries) do
    add :summary, :text
    add :ai_tags, :jsonb, default: "[]"
  end

  alter table(:projects) do
    add :summary, :text
  end
end
```

#### 1.3 Update Entry Schema

**File**: `lib/glossary/entries/entry.ex`
**Changes**: Add `summary` and `ai_tags` fields, update changeset to cast them

```elixir
# In the schema block, after :status
field :summary, :string
field :ai_tags, {:array, :string}, default: []
```

```elixir
# In changeset/2, add to the cast list
|> cast(attrs, [:title, :subtitle, :body, :body_text, :title_text, :subtitle_text, :status, :summary, :ai_tags])
```

#### 1.4 Update Project Schema

**File**: `lib/glossary/projects/project.ex`
**Changes**: Add `summary` field, update changeset to cast it

```elixir
# In the schema block, after :name
field :summary, :string
```

```elixir
# In changeset/2
|> cast(attrs, [:name, :summary])
```

#### 1.5 LLM Client Module

**File**: `lib/glossary/ai/llm.ex` (new)
**Changes**: A thin module that sends chat completions to `/v1/chat/completions`. Works with both Ollama and OpenAI since they share the same API shape.

```elixir
defmodule Glossary.AI.LLM do
  @moduledoc """
  OpenAI-compatible chat completions client.

  Works with both Ollama (local, default) and OpenAI (cloud fallback)
  since Ollama exposes an OpenAI-compatible API at /v1/chat/completions.
  """

  def chat(messages, opts \\ []) do
    config = config()
    model = Keyword.get(opts, :model, config.model)

    body = %{
      model: model,
      messages: messages,
      stream: false
    }

    case Req.post(
           "#{config.base_url}/chat/completions",
           json: body,
           auth: {:bearer, config.api_key},
           receive_timeout: 120_000
         ) do
      {:ok, %{status: 200, body: body}} ->
        content = get_in(body, ["choices", Access.at(0), "message", "content"])
        {:ok, content}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp config do
    app_config = Application.get_env(:glossary, __MODULE__, [])

    %{
      base_url: Keyword.get(app_config, :base_url, "http://localhost:11434/v1"),
      api_key: Keyword.get(app_config, :api_key, "ollama"),
      model: Keyword.get(app_config, :model, "llama3.2")
    }
  end
end
```

#### 1.6 Configuration

**File**: `config/config.exs`
**Changes**: Add default LLM config (Ollama defaults)

```elixir
config :glossary, Glossary.AI.LLM,
  base_url: "http://localhost:11434/v1",
  api_key: "ollama",
  model: "llama3.2"
```

**File**: `config/runtime.exs`
**Changes**: Allow env var overrides for production/cloud deployments

```elixir
# Outside the `if config_env() == :prod` block, so it applies to all envs:
if llm_provider = System.get_env("LLM_PROVIDER") do
  case llm_provider do
    "openai" ->
      config :glossary, Glossary.AI.LLM,
        base_url: "https://api.openai.com/v1",
        api_key: System.get_env("OPENAI_API_KEY") || raise("OPENAI_API_KEY required when LLM_PROVIDER=openai"),
        model: System.get_env("LLM_MODEL") || "gpt-4o-mini"

    "ollama" ->
      config :glossary, Glossary.AI.LLM,
        base_url: System.get_env("OLLAMA_URL") || "http://localhost:11434/v1",
        api_key: "ollama",
        model: System.get_env("LLM_MODEL") || "llama3.2"
  end
end
```

**File**: `config/test.exs`
**Changes**: Disable AI in tests by default

```elixir
config :glossary, Glossary.AI.LLM,
  enabled: false
```

#### 1.7 Add Task.Supervisor to Supervision Tree

**File**: `lib/glossary/application.ex`
**Changes**: Add `{Task.Supervisor, name: Glossary.TaskSupervisor}` before Endpoint

```elixir
children = [
  GlossaryWeb.Telemetry,
  Glossary.Repo,
  {DNSCluster, query: Application.get_env(:glossary, :dns_cluster_query) || :ignore},
  {Phoenix.PubSub, name: Glossary.PubSub},
  {Cachex, name: :glossary_cache},
  {Task.Supervisor, name: Glossary.TaskSupervisor},
  GlossaryWeb.Endpoint
]
```

### Success Criteria:

#### Automated Verification:
- [ ] `mix deps.get` succeeds
- [ ] Migration applies cleanly: `mix ecto.migrate`
- [ ] `mix compile --warnings-as-errors` passes
- [ ] `mix test` passes
- [ ] `mix format` passes
- [ ] Verify LLM client connects to Ollama: `Glossary.AI.LLM.chat([%{role: "user", content: "hello"}])` returns `{:ok, _}` in iex (requires Ollama running)

#### Manual Verification:
- [ ] Confirm Ollama is accessible at `http://localhost:11434/v1/chat/completions`
- [ ] Confirm the `llama3.2` model is pulled in Ollama

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation before proceeding to Phase 2.

---

## Phase 2: Entry AI Generation — Backend

### Overview
Create the AI context module with prompt engineering for summarization and tag generation. Hook into the entry save flow to auto-generate when summary is missing.

### Changes Required:

#### 2.1 AI Context Module

**File**: `lib/glossary/ai.ex` (new)
**Changes**: Context module with functions for generating entry summaries and tags

```elixir
defmodule Glossary.AI do
  @moduledoc """
  AI-powered content generation for entries and projects.
  """

  alias Glossary.AI.LLM
  alias Glossary.Entries.Entry
  alias Glossary.Repo

  @doc """
  Generates a summary and AI tags for an entry asynchronously.
  Sends `{:ai_generated, entry_id}` to the caller when complete.
  """
  def generate_entry_ai(entry, notify_pid \\ nil) do
    if enabled?() and has_content?(entry) do
      pid = notify_pid || self()

      Task.Supervisor.start_child(Glossary.TaskSupervisor, fn ->
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
      end)
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
      %{role: "system", content: "You are a concise technical writer. Respond with only the summary, no preamble."},
      %{role: "user", content: prompt}
    ])
  end

  defp generate_tags(entry) do
    prompt = """
    Generate 3-7 short, lowercase tags for the following knowledge base entry.
    Tags should help an AI system categorize, sort, and find this entry.
    Return ONLY a JSON array of strings, nothing else.

    Title: #{entry.title_text}
    #{if entry.subtitle_text, do: "Subtitle: #{entry.subtitle_text}\n", else: ""}
    Content:
    #{entry.body_text}
    """

    case LLM.chat([
           %{role: "system", content: "You are a tagging system. Respond with only a JSON array of lowercase strings."},
           %{role: "user", content: prompt}
         ]) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, tags} when is_list(tags) ->
            {:ok, Enum.filter(tags, &is_binary/1)}

          _ ->
            # Try to extract tags if LLM wrapped them in markdown
            case Regex.run(~r/\[.*\]/s, content) do
              [json] -> case Jason.decode(json) do
                {:ok, tags} when is_list(tags) -> {:ok, Enum.filter(tags, &is_binary/1)}
                _ -> {:ok, []}
              end
              nil -> {:ok, []}
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp has_content?(entry) do
    entry.body_text != nil and String.trim(entry.body_text) != ""
  end

  defp enabled? do
    config = Application.get_env(:glossary, Glossary.AI.LLM, [])
    Keyword.get(config, :enabled, true)
  end
end
```

#### 2.2 Hook Auto-Generation into Entry Save Flow

**File**: `lib/glossary_web/live/entry_live/edit.ex`
**Changes**: After `save_field/2` succeeds, if the entry has body content but no summary, trigger async AI generation. Add `handle_info` for `{:ai_generated, entry_id}` to refresh the entry.

In `save_field/2`, after the successful case branch (after `assign(:broadcast_timer, timer)`), add a check:

```elixir
# After assigning the updated entry in save_field/2:
|> maybe_generate_ai(entry)
```

New private function:

```elixir
defp maybe_generate_ai(socket, entry) do
  if is_nil(entry.summary) and entry.body_text && String.trim(entry.body_text) != "" do
    Glossary.AI.generate_entry_ai(entry)
  end
  socket
end
```

New `handle_info` clauses:

```elixir
def handle_info({:ai_generated, entry_id}, socket) do
  if socket.assigns.entry.id == entry_id do
    entry = Entries.get_entry_all!(socket.assigns.current_scope, entry_id)
    {:noreply, assign(socket, :entry, entry)}
  else
    {:noreply, socket}
  end
end

def handle_info({:ai_error, _entry_id, _reason}, socket) do
  {:noreply, put_flash(socket, :error, "AI generation failed. You can try again manually.")}
end
```

### Success Criteria:

#### Automated Verification:
- [ ] `mix compile --warnings-as-errors` passes
- [ ] `mix test` passes
- [ ] `mix format` passes

#### Manual Verification:
- [ ] Create an entry with body content — summary and AI tags populate within a few seconds
- [ ] Edit an entry that already has a summary — no auto-regeneration occurs
- [ ] Check that the summary and tags are stored in the database

**Implementation Note**: After completing this phase, pause for manual verification before proceeding to Phase 3.

---

## Phase 3: Entry AI Generation — UI

### Overview
Display the summary and AI tags on the entry edit page, add a regenerate button using the placeholder actions menu.

### Changes Required:

#### 3.1 Entry Edit Page — AI Section and Actions Menu

**File**: `lib/glossary_web/live/entry_live/edit.ex`
**Changes**:

1. Replace the placeholder actions menu (`edit.ex:245-248`) with a working dropdown containing "Regenerate Summary & Tags"
2. Add a collapsible AI section between the metadata bar and the divider showing the summary and AI tags
3. Add `ai_loading` assign to track loading state
4. Add `handle_event("regenerate_ai", ...)` handler

**Actions menu replacement** (replacing lines 245-248):

```heex
<div class="shrink-0">
  <details id="entry-actions" class="dropdown dropdown-end">
    <summary class="btn btn-ghost btn-sm btn-square list-none">
      <.icon name="hero-ellipsis-vertical-micro" class="size-6 text-base-content/50" />
    </summary>
    <ul class="dropdown-content menu bg-base-200 border-base-300 rounded-box z-10 mt-1 w-56 border p-2 shadow shadow-xl">
      <li>
        <button
          phx-click={JS.push("regenerate_ai") |> JS.remove_attribute("open", to: "#entry-actions")}
          type="button"
          disabled={@ai_loading}
        >
          <.icon name="hero-sparkles" class="size-4" />
          <%= if @ai_loading, do: "Generating...", else: "Regenerate Summary & Tags" %>
        </button>
      </li>
    </ul>
  </details>
</div>
```

**AI section** (between metadata bar and divider, new block around line 510):

```heex
<div :if={@entry.summary || @entry.ai_tags != []} class="bg-base-200/50 mt-4 rounded-lg p-4">
  <div class="flex items-center gap-2 text-sm font-medium text-base-content/70 mb-2">
    <.icon name="hero-sparkles" class="size-4" />
    AI Generated
  </div>
  <p :if={@entry.summary} class="text-sm text-base-content/80">{@entry.summary}</p>
  <div :if={@entry.ai_tags != []} class="mt-2 flex flex-wrap gap-1">
    <span :for={tag <- @entry.ai_tags} class="badge badge-ghost badge-sm">{tag}</span>
  </div>
</div>

<div :if={@ai_loading} class="mt-4 flex items-center gap-2 text-sm text-base-content/50">
  <span class="loading loading-spinner loading-xs"></span>
  Generating summary and tags...
</div>
```

**New assigns** in `assign_picker_defaults/1`:

```elixir
|> assign(:ai_loading, false)
```

**New event handler**:

```elixir
def handle_event("regenerate_ai", _params, socket) do
  entry = socket.assigns.entry
  Glossary.AI.generate_entry_ai(entry)
  {:noreply, assign(socket, :ai_loading, true)}
end
```

**Update handle_info for ai_generated** to clear loading state:

```elixir
def handle_info({:ai_generated, entry_id}, socket) do
  if socket.assigns.entry.id == entry_id do
    entry = Entries.get_entry_all!(socket.assigns.current_scope, entry_id)
    {:noreply, socket |> assign(:entry, entry) |> assign(:ai_loading, false)}
  else
    {:noreply, socket}
  end
end

def handle_info({:ai_error, _entry_id, _reason}, socket) do
  {:noreply,
   socket
   |> assign(:ai_loading, false)
   |> put_flash(:error, "AI generation failed. You can try again manually.")}
end
```

### Success Criteria:

#### Automated Verification:
- [ ] `mix compile --warnings-as-errors` passes
- [ ] `mix test` passes
- [ ] `mix format` passes

#### Manual Verification:
- [ ] Entry edit page shows summary and AI tags below the metadata bar
- [ ] Ellipsis icon opens a dropdown with "Regenerate Summary & Tags"
- [ ] Clicking regenerate shows a loading spinner, then the updated summary/tags appear
- [ ] New entries with body content auto-generate summary/tags after a save
- [ ] Loading state clears on success or error

**Implementation Note**: After completing this phase, pause for manual verification before proceeding to Phase 4.

---

## Phase 4: Project Summarization — On Demand

### Overview
Add a "Generate Summary" button to the project show page that summarizes all entries in the project.

### Changes Required:

#### 4.1 AI Context — Project Summary Function

**File**: `lib/glossary/ai.ex`
**Changes**: Add `generate_project_summary/2`

```elixir
def generate_project_summary(project, notify_pid \\ nil) do
  if enabled?() do
    pid = notify_pid || self()

    Task.Supervisor.start_child(Glossary.TaskSupervisor, fn ->
      entries_context =
        project.entries
        |> Enum.map(fn entry ->
          "## #{entry.title_text}\n#{entry.body_text}"
        end)
        |> Enum.join("\n\n---\n\n")

      prompt = """
      Summarize the following project that contains multiple knowledge base entries.
      Provide a 2-4 sentence overview of what this project covers.

      Project: #{project.name}

      Entries:
      #{entries_context}
      """

      case LLM.chat([
             %{role: "system", content: "You are a concise technical writer. Respond with only the summary, no preamble."},
             %{role: "user", content: prompt}
           ]) do
        {:ok, summary} ->
          alias Glossary.Projects.Project, as: P

          {:ok, _} =
            project
            |> P.changeset(%{summary: summary})
            |> Glossary.Repo.update()

          send(pid, {:project_ai_generated, project.id})

        {:error, reason} ->
          send(pid, {:project_ai_error, project.id, reason})
      end
    end)
  end
end
```

#### 4.2 Project Show Page — Summary Display and Button

**File**: `lib/glossary_web/live/project_live/show.ex`
**Changes**:

1. Add `:ai_loading` assign in `mount/3`
2. Add summary display and generate button below the header
3. Add `handle_event("generate_summary", ...)` and `handle_info` callbacks

**New assign in mount**:

```elixir
|> assign(:ai_loading, false)
```

**Summary section** (between the `<.header>` and `<section>`, around line 131):

```heex
<div class="space-y-2">
  <div class="flex items-center justify-between">
    <h3 :if={@project.summary} class="text-sm font-medium text-base-content/70 flex items-center gap-1">
      <.icon name="hero-sparkles" class="size-4" /> Summary
    </h3>
    <button
      phx-click="generate_summary"
      type="button"
      class="btn btn-ghost btn-xs"
      disabled={@ai_loading}
    >
      <%= if @ai_loading do %>
        <span class="loading loading-spinner loading-xs"></span> Generating...
      <% else %>
        <.icon name="hero-sparkles" class="size-4" />
        <%= if @project.summary, do: "Regenerate", else: "Generate Summary" %>
      <% end %>
    </button>
  </div>
  <p :if={@project.summary} class="text-sm text-base-content/80 bg-base-200/50 rounded-lg p-3">
    {@project.summary}
  </p>
</div>
```

**New event handler**:

```elixir
def handle_event("generate_summary", _params, socket) do
  project = socket.assigns.project
  Glossary.AI.generate_project_summary(project)
  {:noreply, assign(socket, :ai_loading, true)}
end
```

**New handle_info callbacks**:

```elixir
def handle_info({:project_ai_generated, project_id}, socket) do
  if socket.assigns.project.id == project_id do
    project = Projects.get_project!(socket.assigns.current_scope, project_id)
    {:noreply, socket |> assign(:project, project) |> assign(:ai_loading, false)}
  else
    {:noreply, socket}
  end
end

def handle_info({:project_ai_error, _project_id, _reason}, socket) do
  {:noreply,
   socket
   |> assign(:ai_loading, false)
   |> put_flash(:error, "AI summary generation failed. Try again.")}
end
```

### Success Criteria:

#### Automated Verification:
- [ ] `mix compile --warnings-as-errors` passes
- [ ] `mix test` passes
- [ ] `mix format` passes
- [ ] `mix credo` passes
- [ ] `mix precommit` passes

#### Manual Verification:
- [ ] Project show page has a "Generate Summary" button
- [ ] Clicking it shows a loading spinner, then displays the generated summary
- [ ] Summary is persisted — navigating away and back shows the saved summary
- [ ] "Regenerate" replaces the existing summary
- [ ] Projects with no entries show a reasonable message or error

---

## Testing Strategy

### Unit Tests:
- `Glossary.AI.LLM` — mock or skip in test env (configured via `enabled: false`)
- `Entry` changeset casts `summary` and `ai_tags` correctly
- `Project` changeset casts `summary` correctly
- AI tag JSON parsing handles edge cases (markdown-wrapped JSON, non-array responses)

### Integration Tests:
- Entry create/update still works with new fields
- New fields survive round-trip through the database

### Manual Testing Steps:
1. Start Ollama with `llama3.2` model
2. Create a new entry, add body content — verify auto-generation
3. Click "Regenerate Summary & Tags" — verify update
4. Navigate to a project with entries, click "Generate Summary"
5. Set `LLM_PROVIDER=openai` and `OPENAI_API_KEY=...` — verify fallback works

## Performance Considerations

- LLM calls run in `Task.Supervisor` child processes — never block the LiveView
- Ollama local calls take 2-30s depending on model size and hardware
- OpenAI calls take 1-5s typically
- Auto-generation only fires when summary is nil AND body has content — not on every save
- No caching of AI results (they're persisted to the DB)
- `receive_timeout: 120_000` on Req calls to handle slow local models

## Migration Notes

- All new columns are nullable with defaults — no data migration needed
- Existing entries will have `summary: nil` and `ai_tags: []`
- Auto-generation triggers on the next save of any entry with body content but no summary
- No destructive changes to existing data

## File Summary

| File | Action | Phase |
|---|---|---|
| `mix.exs` | Add `{:req, "~> 0.5"}` | 1 |
| `priv/repo/migrations/*_add_ai_fields.exs` | New migration | 1 |
| `lib/glossary/entries/entry.ex` | Add `summary`, `ai_tags` fields | 1 |
| `lib/glossary/projects/project.ex` | Add `summary` field | 1 |
| `lib/glossary/ai/llm.ex` | New — LLM client | 1 |
| `config/config.exs` | Add LLM config defaults | 1 |
| `config/runtime.exs` | Add env var overrides | 1 |
| `config/test.exs` | Disable AI in tests | 1 |
| `lib/glossary/application.ex` | Add Task.Supervisor | 1 |
| `lib/glossary/ai.ex` | New — AI context module | 2 |
| `lib/glossary_web/live/entry_live/edit.ex` | Auto-gen hook, handle_info | 2 |
| `lib/glossary_web/live/entry_live/edit.ex` | Actions menu, AI display, regenerate | 3 |
| `lib/glossary/ai.ex` | Add project summary function | 4 |
| `lib/glossary_web/live/project_live/show.ex` | Summary display, generate button | 4 |

## References

- Research: `thoughts/shared/research/2026-03-01-ai-integration-codebase-research.md`
- Ollama OpenAI compatibility: https://docs.ollama.com/api/openai-compatibility
- Req documentation: https://hexdocs.pm/req/
