---
date: 2026-02-21T13:30:00-06:00
researcher: Claude
git_commit: 3a2dda0062e12259432271d91c28830cc44c35e0
branch: main
repository: glossary
topic: "How would this app perform at scale? Strengths and bottlenecks"
tags: [research, scalability, performance, postgresql, liveview, search]
status: complete
last_updated: 2026-02-21
last_updated_by: Claude
---

# Research: Scalability Analysis — Strengths and Bottlenecks

**Date**: 2026-02-21T13:30:00-06:00
**Researcher**: Claude
**Git Commit**: 3a2dda0
**Branch**: main
**Repository**: glossary

## Research Question

How would this app perform at scale? What are the strengths? What are the bottlenecks?

## Summary

Glossary is a single-node Phoenix 1.8 LiveView application backed by PostgreSQL. Its architecture is well-suited for a single-user or small-team knowledge base, with several strong design choices around search indexing and LiveView state management. The main scalability concerns involve unbounded list queries, lack of pagination, per-user data scoping without connection pooling strategies, and the absence of caching or background processing infrastructure.

---

## Strengths

### 1. PostgreSQL Full-Text Search with Weighted tsvector + Trigger

**Files**: `priv/repo/migrations/20260204135623_add_full_text_search_to_entries.exs`, `lib/glossary/entries.ex:185-198`

The search implementation uses a database-maintained `search_tsv` tsvector column with a `BEFORE INSERT OR UPDATE` trigger. This is a strong pattern because:

- **Zero application-layer overhead**: The trigger fires automatically when `title_text`, `subtitle_text`, or `body_text` change. The Ecto schema doesn't even declare the `search_tsv` field — it's invisible to the application.
- **Weighted ranking**: Title (A), subtitle (B), body (C) weights mean title matches rank highest via `ts_rank_cd`, which is the cover-density ranking function accounting for lexeme proximity.
- **GIN index** (`entries_search_tsv_gin`): The GIN index on `search_tsv` allows PostgreSQL to perform index scans for FTS queries. GIN indexes handle high-cardinality tsvector data efficiently.
- **`websearch_to_tsquery`**: Supports natural web-search syntax (quoted phrases, `-` exclusion, `OR`) without custom parsing.

### 2. Two-Tier Search Strategy (FTS + Trigram Fallback)

**File**: `lib/glossary/entries.ex:173-210`

The `do_search/2` function tries FTS first, and only falls back to trigram similarity if fewer than 3 FTS results are returned. This gives:

- **Fast path for exact/stemmed matches**: FTS handles the common case efficiently.
- **Fuzzy fallback for typos/partial matches**: `pg_trgm` with `similarity(title_text, ?) > 0.1` catches what FTS misses.
- **Deduplication via MapSet**: FTS results are never duplicated by the trigram pass.
- The trigram index (`entries_title_text_trgm_gin`) is a GIN index using `gin_trgm_ops`, which supports the `similarity()` function efficiently.

### 3. LiveView Streams for All Rendered Collections

**Files**: All Index/Show LiveViews

Every list rendered in the UI uses LiveView streams (`stream/3`, `stream_insert/3`, `stream_delete/3`):

| LiveView | Stream |
|---|---|
| Dashboard | `:recent_entries` |
| EntryLive.Index | `:entries` |
| ProjectLive.Index | `:projects` |
| ProjectLive.Show | `:project_entries` |
| TopicLive.Index | `:topics` |
| TopicLive.Show | `:topic_entries` |
| TagLive.Index | `:tags` |
| TagLive.Show | `:tag_entries`, `:tag_projects` |

This means:
- **Collection data is not held in server memory** after the initial render. Streams are a DOM-patching mechanism — the server tracks only DOM IDs, not the full struct list.
- **Granular updates**: `stream_insert` and `stream_delete` patch individual items without re-rendering the entire list.

### 4. User-Scoped Data with Indexed Foreign Keys

**Files**: All context modules, `priv/repo/migrations/20260217215832_add_user_ownership_to_notes_models.exs`

Every query filters by `user_id`, and every table with user ownership has a B-tree index on `user_id`. This means:
- Queries naturally partition by user — one user's data volume doesn't affect another's query performance.
- The `(user_id, name)` composite unique indexes on projects, topics, and tags serve double duty: uniqueness enforcement and efficient lookups.

### 5. Minimal Server-Side State per Connection

Most LiveViews hold very little in assigns:
- Index pages: `page_title` + a stream reference
- Show pages: The parent record + a stream + picker state (small lists, loaded on demand)
- Forms: A changeset-backed form struct

The `EntryLive.Edit` page is the heaviest, holding `all_projects`, `all_tags`, `all_topics` as full lists — but these are small lookup tables in practice.

### 6. Efficient Join Table Operations

**File**: `lib/glossary/entries.ex:225-303`

Association mutations use `Repo.insert_all` with `on_conflict: :nothing` (upsert-safe) and `Repo.delete_all` with targeted where clauses. This avoids loading the full association just to add/remove a single link. The `force: true` preload after mutation ensures fresh data without stale cache issues.

### 7. Cookie-Based Sessions

**File**: `lib/glossary_web/endpoint.ex:7-12`

Sessions are stored in signed cookies, not in a database or ETS table. This means:
- No session store to scale or clean up.
- No database queries on every request just to load the session.

### 8. Health Check Short-Circuit

**File**: `lib/glossary_web/plugs/health_check.ex`

The `/health` endpoint is handled at the top of the plug pipeline (before telemetry, parsers, session, and routing), responding with a simple `200 ok`. Load balancers and orchestrators hitting this endpoint create minimal overhead.

---

## Bottlenecks

### 1. Unbounded `list_*` Queries (No Pagination)

**Files**: `lib/glossary/entries.ex:24-33`, `lib/glossary/projects.ex:18-26`, `lib/glossary/topics.ex:18-25`, `lib/glossary/tags.ex:18-25`

The `list_entries/1`, `list_projects/1`, `list_topics/1`, and `list_tags/1` functions have **no LIMIT clause**. They load every record belonging to the user:

```elixir
# entries.ex:24
def list_entries(%Scope{} = scope) do
  from(e in Entry,
    where: e.user_id == ^user_id,
    order_by: [desc: e.inserted_at],
    preload: [:projects, :topics]
  ) |> Repo.all()
end
```

- With hundreds or thousands of entries, this loads all rows into memory.
- The `preload: [:projects, :topics]` on `list_entries` adds two additional queries per call (Ecto's default preload strategy).
- These unbounded lists are the initial data for Index page streams — so the full dataset must be loaded, serialized, and sent over the WebSocket on mount.

### 2. Preload Strategy: Separate Queries (Not Joins)

**Files**: `lib/glossary/entries.ex:30,46,70`, `lib/glossary/projects.ex:35`, etc.

All preloads use `Repo.preload/2` or inline `preload()` in queries, which executes separate `SELECT ... WHERE id IN (...)` queries for each association. For example, `list_entries` with `preload: [:projects, :topics]` executes:

1. `SELECT * FROM entries WHERE user_id = ? ORDER BY inserted_at DESC`
2. `SELECT * FROM projects WHERE id IN (SELECT project_id FROM project_entries WHERE entry_id IN (...))`
3. `SELECT * FROM topics WHERE id IN (SELECT topic_id FROM entry_topics WHERE entry_id IN (...))`

This is 3 queries minimum per page load. With tags added to preloads, it would be 4. The query count is fixed (not N+1), but the IN-clause size grows with the number of entries.

### 3. Search Hard Limits Without Pagination

**File**: `lib/glossary/entries.ex:185-210`

Search results are capped at hard limits:
- FTS: `limit: 20`
- Trigram: `limit: 10`
- Projects/topics/tags search: `limit: 5`

There is no "load more" or offset-based pagination. Users with large datasets may not find what they need if it falls outside the top 20 results.

### 4. Trigram Index Only on `title_text`

**File**: `priv/repo/migrations/20260203161148_add_trigram_index_to_entries.exs`

The trigram GIN index exists only on `entries.title_text`. The `trigram_search` function at `entries.ex:200` queries `similarity(title_text, ?)`. Fuzzy matching against subtitle or body content is not supported by the trigram path.

Similarly, `projects`, `topics`, and `tags` use `similarity(name, ?)` but have **no trigram index** on `name` — these queries will do sequential scans:

```elixir
# projects.ex:175
from(p in Project,
  where: p.user_id == ^user_id,
  where: fragment("similarity(name, ?) > 0.1", ^query),
  order_by: [desc: fragment("similarity(name, ?)", ^query)],
  limit: 5
)
```

### 5. `EntryLive.Edit` Loads All Projects/Topics/Tags on Mount

**File**: `lib/glossary_web/live/entry_live/edit.ex:448-461`

When editing an entry, `apply_action(:edit, ...)` loads:
- The full entry with all associations
- `Projects.list_projects(scope)` — all projects for the user
- `Tags.list_tags(scope)` — all tags for the user
- `Topics.list_topics(scope)` — all topics for the user

These are held as plain list assigns (`all_projects`, `all_tags`, `all_topics`) for client-side filtering. With thousands of projects/topics/tags, this would be a large assign payload sent over the WebSocket.

### 6. No Caching Layer

There is no ETS, Cachex, ConCache, or application-level caching anywhere. Every navigation to a page re-queries the database. For a single-user app this is fine, but under concurrent load:
- Repeated `list_*` calls from multiple sessions hit the database every time.
- The search modal dispatches a database query on every keystroke (no client-side debounce beyond what the JS hooks provide for Tiptap — the search input has no visible debounce).

### 7. Database Pool Size: 10 (Default)

**Files**: `config/dev.exs:10`, `config/runtime.exs:37`

Both dev and production default to `pool_size: 10`. Each LiveView WebSocket connection can hold a database connection during query execution. Under concurrent load:
- 10 simultaneous queries would exhaust the pool.
- Additional requests would queue, increasing latency.
- The commented-out `pool_count: 4` in `runtime.exs` hints at awareness of this but it's not enabled.

### 8. No Background Job Processing

All work is synchronous and request-scoped. There is no Oban, Exq, or Task.Supervisor for:
- Deferred operations (e.g., reindexing search vectors in bulk)
- Sending notifications
- Data exports
- Any operation that might take longer than a request cycle

### 9. No PubSub Broadcasting

**Observation**: No `Phoenix.PubSub.broadcast` or `subscribe` calls exist in any LiveView.

This means:
- If two browser tabs are open to the same Index page and one deletes an entry, the other tab won't reflect the change until a full page reload.
- Multi-user scenarios (if the app were shared) would have no real-time sync between users viewing the same data.

### 10. Single-Node Architecture

**File**: `lib/glossary/application.ex`

The supervision tree starts a `DNSCluster` child (for Erlang node clustering), but there is no distributed state, no distributed PubSub adapter configuration (defaults to `Phoenix.PubSub.PG2` which is local-node only), and no session sharing mechanism. Deploying to multiple nodes would require:
- A distributed PubSub adapter (e.g., `Phoenix.PubSub.Redis`)
- Sticky sessions or session externalization (currently cookie-based, so sessions do transfer)
- DNS cluster configuration via `$DNS_CLUSTER_QUERY`

### 11. `ilike` Without Index for Some Filters

**Files**: `lib/glossary/entries.ex:334`, `lib/glossary/tags.ex:195`

The `available_projects/3` and `available_tags/3` filter functions use `ilike(p.name, ^"%#{query}%")` for text filtering. `ILIKE` with leading `%` wildcards cannot use B-tree indexes — these will always be sequential scans on the matching subset.

---

## Architecture Documentation

### Data Flow Pattern

```
Browser (Tiptap JS) → phx-hook pushEvent → LiveView handle_event
  → Context module function → Ecto query → PostgreSQL
  → assign/stream update → LiveView diff → WebSocket → DOM patch
```

### Search Architecture

```
Search Input → parse_prefix ($, @, #, %, !) → mode routing
  → :all    → FTS + trigram entries + trigram projects/topics/tags
  → :entries → FTS + trigram fallback
  → :projects/:topics/:tags → trigram similarity on name
  → :commands → in-memory label substring match (no DB)
```

### Association Management Pattern

```
toggle_project/topic/tag event
  → check if already associated (Enum.any? on preloaded list)
  → add: Repo.insert_all into join table (on_conflict: :nothing)
  → remove: Repo.delete_all from join table
  → Repo.preload(entry, :association, force: true)
  → re-assign entry to socket
```

## Code References

- `lib/glossary/entries.ex:24-33` — Unbounded `list_entries/1`
- `lib/glossary/entries.ex:173-210` — Two-tier search (FTS + trigram)
- `lib/glossary/entries.ex:185-198` — FTS query with `ts_rank_cd`
- `lib/glossary/entries.ex:200-210` — Trigram fallback query
- `lib/glossary/entries.ex:225-303` — Join table insert/delete operations
- `lib/glossary_web/live/entry_live/edit.ex:448-461` — Heavy assign loading on edit mount
- `lib/glossary_web/live/search.ex:342` — Prefix-based search mode parsing
- `priv/repo/migrations/20260204135623_add_full_text_search_to_entries.exs:22-39` — tsvector trigger
- `priv/repo/migrations/20260203161148_add_trigram_index_to_entries.exs` — Trigram index (title_text only)
- `config/runtime.exs:33-39` — Production database pool configuration
- `lib/glossary/application.ex:9-19` — Supervision tree

## Open Questions

- What is the expected data volume per user? (Hundreds vs. thousands of entries)
- Is multi-user concurrent access a design goal, or is this primarily a single-user tool?
- Are there plans for full-text search on projects/topics/tags (currently trigram-only)?
- Is the Tiptap editor body content expected to be large (thousands of words per entry)?
