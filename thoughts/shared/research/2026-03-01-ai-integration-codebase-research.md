---
date: 2026-03-01T12:20:00-06:00
researcher: Claude
git_commit: 7034f51633dde5b1dba5a4ab7a14748d811f9513
branch: main
repository: glossary
topic: "AI Integration Research: OpenAI Summarization and Auto-Tag/Summary Generation"
tags: [research, codebase, ai, openai, summarization, tags, entries]
status: complete
last_updated: 2026-03-01
last_updated_by: Claude
---

# Research: AI Integration for Entry Summarization and Tag/Summary Generation

**Date**: 2026-03-01T12:20:00-06:00
**Researcher**: Claude
**Git Commit**: 7034f51
**Branch**: main
**Repository**: glossary

## Research Question

How is the codebase currently structured to support integrating:
1. OpenAI API calls to summarize entries from certain projects or topics on demand
2. A local model (or OpenAI fallback) to generate AI-friendly tags and summaries when missing, or when the user clicks a button

## Summary

The glossary application has a clean foundation for AI integration but no AI functionality exists today. Key findings:

- **No HTTP client exists** — `Req` is listed in CLAUDE.md as the preferred HTTP library but is not yet a dependency
- **No external API integrations** of any kind exist
- **Plain text fields are already designed for AI** — `body_text`, `title_text`, `subtitle_text` on `Entry` are explicitly documented as intended for "LLM context" and "vector embeddings"
- **No summary field exists** on any schema — Entry has `subtitle`/`subtitle_text` (short description) but no dedicated `summary` field
- **No description/summary fields** on Project or Topic — both have only `name`
- **Tags are manual-only** — no auto-suggestion or AI generation, just a `name` field per user
- **The edit page has a placeholder** for an actions menu (commented-out `IDEA: entry actions menu` near an ellipsis icon) — a natural spot for "Generate Summary" / "Generate Tags" buttons
- **Cachex caching** and **PubSub broadcasting** patterns are well-established and can be reused for AI results
- **User-scoped data** — all operations go through `%Scope{}`, so AI features must respect user ownership

## Detailed Findings

### 1. Entry Schema — Current Fields and AI Readiness

**File**: `lib/glossary/entries/entry.ex`

The Entry schema has paired HTML/plain-text fields:

| HTML Field | Plain Text Field | Purpose |
|---|---|---|
| `title` | `title_text` | Entry title |
| `subtitle` | `subtitle_text` | Short description/tagline |
| `body` | `body_text` | Rich content |

The `body_text` field docstring (`entry.ex:10-19`) explicitly lists AI use cases:
- Vector embeddings and semantic search
- Full-text search indexing
- LLM context (avoids wasting tokens on HTML tags)

Plain text fields are populated client-side by Tiptap editor hooks. The `changeset/2` casts all fields but has no `validate_required` — all are optional.

**What's missing for AI**: No `summary` or `ai_summary` field exists. No `ai_tags` or `suggested_tags` field. The `subtitle` field serves as a manual short description but is not AI-generated.

### 2. Tag System — Manual Only

**Files**: `lib/glossary/tags/tag.ex`, `lib/glossary/tags.ex`

Tags have a single `name` field, are user-scoped, and attached to entries via `entry_tags` and projects via `project_tags`. There is no auto-generation, suggestion, or AI functionality. Tags are created entirely through:
- The tag picker on the entry edit page (inline create when no match found)
- The dedicated `/tags/new` page

Tags differ from topics: tags apply to both entries and projects, while topics apply only to entries. Both have only a `name` field.

### 3. Projects and Topics — No Summary Fields

**Files**: `lib/glossary/projects/project.ex`, `lib/glossary/topics/topic.ex`

Neither schema has a description, summary, or body field. Both carry only `name`, `user_id`, and timestamps. To summarize "entries in a project," the integration would need to:
1. Load entries associated with a project via `get_project!/2` (which preloads `:entries`)
2. Concatenate their `body_text` fields as context for the LLM

### 4. Entry Edit Page — UI Integration Points

**File**: `lib/glossary_web/live/entry_live/edit.ex`

The edit page layout (top to bottom):
1. Search modal (`Cmd+K` command palette)
2. Back link to `/entries`
3. **Title editor** (Tiptap)
4. **Subtitle editor** (Tiptap)
5. **Metadata bar**: Status dropdown, Projects picker, Topics picker, Tags picker
6. Divider
7. **Body editor** (Tiptap)

**Placeholder for actions menu** (`edit.ex:245`): A `hero-ellipsis-vertical-micro` icon is rendered next to the title but has no click handler. There's a comment `<%!-- IDEA: entry actions menu --%>` suggesting this was intended as an action menu trigger — a natural place for AI action buttons.

**Autosave pattern**: Field updates are debounced (1000ms client-side Tiptap → server event → `save_field/2` → `Entries.upsert_entry/3`). PubSub broadcasts are further debounced (5 seconds) to avoid flooding other tabs.

### 5. Dependencies and Configuration

**File**: `mix.exs`

Current dependencies relevant to AI integration:
- `{:jason, "~> 1.2"}` — JSON encoding/decoding (needed for API requests)
- `{:cachex, "~> 4.0"}` — Caching (can cache AI responses)
- `{:bandit, "~> 1.5"}` — HTTP server (not client)

**Not present**: No HTTP client library (`Req`, `HTTPoison`, `Tesla`, etc.). CLAUDE.md specifies `Req` as the preferred choice.

**File**: `config/runtime.exs`

Environment variable pattern for production config (`runtime.exs:24-29`): Uses `System.get_env("VAR_NAME") || raise "message"` for required vars, with optional vars using default values. An `OPENAI_API_KEY` would follow this exact pattern.

### 6. Application Supervision Tree

**File**: `lib/glossary/application.ex`

Six supervised children in order: Telemetry, Repo, DNSCluster, PubSub, Cachex, Endpoint. A new AI client GenServer or connection pool would be added here.

### 7. Cache and PubSub Patterns

**File**: `lib/glossary/cache.ex`

Cache-aside pattern with 5-minute TTL. Keys are user-scoped tuples like `{user_id, :recent_entries, 7}`. This pattern could be reused for caching AI-generated summaries with keys like `{user_id, :entry_summary, entry_id}`.

PubSub broadcasts use topic strings like `"user_entries:#{user_id}"` with tuple messages like `{:entry_updated, entry_id}`.

### 8. Search System — Available Context for AI

**File**: `lib/glossary/entries.ex`

The unified search (`search/3`) queries across entries, projects, topics, and tags. For AI summarization of "entries in a project," the relevant query paths are:
- `Projects.get_project!/2` — loads project with preloaded entries
- `Topics.get_topic!/2` — loads topic with preloaded entries
- Each entry's `body_text` is the plain-text content suitable for LLM input

## Code References

- `lib/glossary/entries/entry.ex:10-19` — AI use case documentation for `body_text`
- `lib/glossary/entries/entry.ex:29-45` — Entry schema with all fields
- `lib/glossary/tags/tag.ex:16-25` — Tag schema (name-only)
- `lib/glossary/projects/project.ex:15-24` — Project schema (name-only, no summary)
- `lib/glossary/topics/topic.ex:14-22` — Topic schema (name-only, no summary)
- `lib/glossary_web/live/entry_live/edit.ex:245` — Placeholder actions menu
- `lib/glossary_web/live/entry_live/edit.ex:289-508` — Association pickers (tags/projects/topics)
- `lib/glossary/application.ex:9-23` — Supervision tree
- `lib/glossary/cache.ex` — Cachex wrapper with TTL and invalidation
- `config/runtime.exs:24-29` — Environment variable pattern for secrets
- `mix.exs:42-74` — Current dependencies (no HTTP client)

## Architecture Documentation

### Current Patterns Relevant to AI Integration

1. **Context module pattern**: All domain logic lives in context modules (`Entries`, `Projects`, `Tags`, `Topics`) with `%Scope{}` for user authorization
2. **Cache-aside with Cachex**: `Cache.fetch/2` with tuple keys and 5-min TTL, `Cache.invalidate/1` on writes
3. **PubSub for cross-tab sync**: Broadcasts on user-scoped topics after mutations
4. **Autosave with debounce**: Client-side 1000ms debounce, server-side 5000ms PubSub debounce
5. **Association management**: `add_*/remove_*` functions with `Repo.insert_all(on_conflict: :nothing)` for idempotent joins
6. **Config pattern**: Compile-time defaults, runtime env vars with `System.get_env/1` and raise-on-missing for required values
7. **Plain text parallel fields**: HTML fields paired with `_text` variants for search/AI consumption

### Data Flow for Entry Content

```
User types in Tiptap → JS hook extracts HTML + plaintext
→ pushEvent("body_update", {body: html, body_text: plainText})
→ handle_event("body_update") → save_field/2
→ Entries.upsert_entry/3 → Repo.insert/update
→ PostgreSQL trigger updates search_tsv from *_text fields
→ Cache invalidation + debounced PubSub broadcast
```

## Related Research

- `thoughts/shared/research/2026-02-21-scalability-analysis.md` — Prior analysis of query patterns and caching

## Decisions (Resolved)

1. **Summary field location**: New columns on the `entries` table (`summary`, `ai_tags`)
2. **Tag generation scope**: AI tags are for making the LLM's life easier for sorting/searching — stored on the entry, not as `Tag` records
3. **Local model integration**: Ollama (with OpenAI API as fallback)
4. **Generation triggers**:
   - Entry summaries: automatic on save if no summary present; on button click if summary already exists
   - Project summaries: on demand only (button click)
5. **Project summaries**: Stored in a new `summary` column on the `projects` table
