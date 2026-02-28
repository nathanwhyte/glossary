# PubSub Cross-Tab Sync Implementation Plan

## Overview

Add Phoenix.PubSub broadcasting so mutations in one browser tab are reflected live in all other open tabs. Entry title/subtitle changes broadcast on a 5-second server-side debounce; project/topic/tag relation changes on an entry broadcast immediately.

## Current State Analysis

- `Phoenix.PubSub` is started as `Glossary.PubSub` in `lib/glossary/application.ex:14` but has zero subscribers or broadcasts anywhere in the app.
- All five collection-rendering LiveViews (`Dashboard`, `EntryLive.Index`, `ProjectLive.Index`, `TopicLive.Index`, `TagLive.Index`) have no `handle_info` and no PubSub subscription.
- `EntryLive.Edit` handles `handle_info` only for `{:search_modal_action, ...}` (intra-process message from the embedded `SearchModal` component).
- Context mutation functions (`create_*`, `update_*`, `delete_*`) already have `tap` blocks for cache invalidation — the ideal place to co-locate broadcasts.
- The Tiptap editors debounce at 1000ms client-side, then call `save_field/2` in `EntryLive.Edit` which calls `Entries.upsert_entry`. A 5-second server-side debounce means other tabs see title/subtitle changes at most 5s stale.

## Desired End State

- Create/delete of entries, projects, topics, tags is immediately reflected in all open Index pages and the Dashboard.
- Editing an entry's title or subtitle in one tab updates the `EntryLive.Index` table row in other tabs within ~5 seconds of the last keystroke.
- Adding or removing a project/topic/tag relation on an entry immediately updates `EntryLive.Index` rows in other tabs (badge changes).
- Status changes on an entry immediately update the `EntryLive.Index` row in other tabs.

## What We're NOT Doing

- No PubSub in Show pages (`ProjectLive.Show`, `TopicLive.Show`, `TagLive.Show`) — they already reload on `SearchModal` actions and are single-purpose views.
- No broadcasting of `add_entry`/`remove_entry` on project/topic/tag (join table changes) — these don't affect Index list views.
- No distributed PubSub adapter — `Phoenix.PubSub.PG2` (local node) is sufficient.
- No PubSub in `EntryLive.Edit` subscriptions — the editing tab is the source of truth.

## Implementation Approach

**Topics** (per-user, string keys):
```
"user_entries:{user_id}"   — entry create / update / delete
"user_projects:{user_id}"  — project create / update / delete
"user_topics:{user_id}"    — topic create / update / delete
"user_tags:{user_id}"      — tag create / update / delete
```

**Message shapes**:
```elixir
{:entry_created, entry_id}
{:entry_updated, entry_id}
{:entry_deleted, entry_id}
{:project_created, project_id}
{:project_updated, project_id}
{:project_deleted, project_id}
# ...same shape for topics and tags
```

**Broadcast sites**:
| Event | Where | Notes |
|---|---|---|
| entry created/deleted | `Entries` context `tap` block | Same place as cache invalidation |
| entry updated (title/subtitle) | `EntryLive.Edit` `save_field/2` | `Process.send_after` with 5s debounce |
| entry updated (status) | `EntryLive.Edit` `set_status` event | Immediate |
| entry updated (relation toggle) | `EntryLive.Edit` `toggle_*` events | Immediate |
| project/topic/tag create/update/delete | Respective context `tap` blocks | Co-located with cache invalidation |

**Subscriber responses**:
| LiveView | Topic | Message | Response |
|---|---|---|---|
| `Dashboard` | `user_entries` | any | Invalidate `{user_id, :recent_entries, 7}` cache key + reload stream |
| `EntryLive.Index` | `user_entries` | `created`/`updated` | `get_entry_all!(scope, id)` → `stream_insert` |
| `EntryLive.Index` | `user_entries` | `deleted` | `stream_delete` with `%Entry{id: id}` |
| `ProjectLive.Index` | `user_projects` | `created`/`updated` | `get_project!(scope, id)` → `stream_insert` |
| `ProjectLive.Index` | `user_projects` | `deleted` | `stream_delete` with `%Project{id: id}` |
| `TopicLive.Index` | `user_topics` | same pattern | same pattern |
| `TagLive.Index` | `user_tags` | same pattern | same pattern |

---

## Phase 1: Context Broadcasts + Index/Dashboard Subscribe & Handle

### Overview
Add `Phoenix.PubSub.broadcast` calls to context mutation functions, subscribe Index pages and Dashboard on mount, and add `handle_info` to react to broadcasts.

### Changes Required:

#### 1.1 Broadcast helpers — `lib/glossary/entries.ex`

**File**: `lib/glossary/entries.ex`
**Changes**: Add broadcasts to `create_entry/2` and `delete_entry/3` tap blocks. No broadcast in `update_entry/3` — that is handled by `EntryLive.Edit` in Phase 2.

```elixir
def create_entry(%Scope{} = current_scope, attrs) do
  user_id = scope_user_id!(current_scope)

  %Entry{user_id: user_id}
  |> Entry.changeset(attrs)
  |> Repo.insert()
  |> tap(fn
    {:ok, entry} ->
      Cache.invalidate({user_id, :recent_entries, 7})
      Phoenix.PubSub.broadcast(Glossary.PubSub, "user_entries:#{user_id}", {:entry_created, entry.id})
    _ -> :ok
  end)
end

def delete_entry(%Scope{} = current_scope, %Entry{} = entry) do
  user_id = scope_user_id!(current_scope)

  entry
  |> ensure_entry_owned!(current_scope)
  |> Repo.delete()
  |> tap(fn
    {:ok, deleted} ->
      Cache.invalidate({user_id, :recent_entries, 7})
      Phoenix.PubSub.broadcast(Glossary.PubSub, "user_entries:#{user_id}", {:entry_deleted, deleted.id})
    _ -> :ok
  end)
end
```

#### 1.2 Broadcast helpers — `lib/glossary/projects.ex`

**File**: `lib/glossary/projects.ex`
**Changes**: Add broadcasts to `create_project/2`, `update_project/3`, `delete_project/3` tap blocks alongside existing cache invalidation.

```elixir
# In create_project/2 tap:
{:ok, project} ->
  Cache.invalidate({user_id, :projects})
  Phoenix.PubSub.broadcast(Glossary.PubSub, "user_projects:#{user_id}", {:project_created, project.id})

# In update_project/3 tap:
{:ok, project} ->
  Cache.invalidate({user_id, :projects})
  Phoenix.PubSub.broadcast(Glossary.PubSub, "user_projects:#{user_id}", {:project_updated, project.id})

# In delete_project/3 tap:
{:ok, project} ->
  Cache.invalidate({user_id, :projects})
  Phoenix.PubSub.broadcast(Glossary.PubSub, "user_projects:#{user_id}", {:project_deleted, project.id})
```

#### 1.3 Broadcast helpers — `lib/glossary/topics.ex`

**File**: `lib/glossary/topics.ex`
**Changes**: Same pattern as projects — add broadcasts in `create_topic/2`, `update_topic/3`, `delete_topic/3`. Topic: `"user_topics:#{user_id}"`. Message atoms: `:topic_created`, `:topic_updated`, `:topic_deleted`.

#### 1.4 Broadcast helpers — `lib/glossary/tags.ex`

**File**: `lib/glossary/tags.ex`
**Changes**: Same pattern. Topic: `"user_tags:#{user_id}"`. Message atoms: `:tag_created`, `:tag_updated`, `:tag_deleted`.

#### 1.5 Dashboard — subscribe + handle_info

**File**: `lib/glossary_web/live/dashboard.ex`
**Changes**: Subscribe on mount; on any entry event, invalidate cache and reset stream.

```elixir
def mount(_params, _session, socket) do
  user_id = socket.assigns.current_scope.user.id
  if connected?(socket), do: Phoenix.PubSub.subscribe(Glossary.PubSub, "user_entries:#{user_id}")

  {:ok,
   socket
   |> assign(:current_user_id, user_id)
   |> stream(:recent_entries, Entries.recent_entries(socket.assigns.current_scope))}
end

@impl true
def handle_info({event, _id}, socket)
    when event in [:entry_created, :entry_updated, :entry_deleted] do
  Glossary.Cache.invalidate({socket.assigns.current_user_id, :recent_entries, 7})

  {:noreply,
   stream(socket, :recent_entries, Entries.recent_entries(socket.assigns.current_scope),
     reset: true
   )}
end
```

#### 1.6 EntryLive.Index — subscribe + handle_info

**File**: `lib/glossary_web/live/entry_live/index.ex`
**Changes**: Subscribe on mount; handle created/updated with `stream_insert`, deleted with `stream_delete`.

```elixir
def mount(_params, _session, socket) do
  user_id = socket.assigns.current_scope.user.id
  if connected?(socket), do: Phoenix.PubSub.subscribe(Glossary.PubSub, "user_entries:#{user_id}")

  {:ok,
   socket
   |> assign(:page_title, "All Entries")
   |> stream(:entries, Entries.list_entries(socket.assigns.current_scope))}
end

@impl true
def handle_info({event, entry_id}, socket)
    when event in [:entry_created, :entry_updated] do
  entry = Entries.get_entry_all!(socket.assigns.current_scope, entry_id)
  {:noreply, stream_insert(socket, :entries, entry, at: if(event == :entry_created, do: 0, else: -1))}
end

@impl true
def handle_info({:entry_deleted, entry_id}, socket) do
  {:noreply, stream_delete(socket, :entries, %Entries.Entry{id: entry_id})}
end
```

Note: `stream_insert` with `at: -1` updates an existing item in place without moving it. `at: 0` prepends new entries to the top of the list, matching the `order_by: desc: :inserted_at` sort.

#### 1.7 ProjectLive.Index — subscribe + handle_info

**File**: `lib/glossary_web/live/project_live/index.ex`
**Changes**: Same pattern; topic `"user_projects:#{user_id}"`; uses `Projects.get_project!` to fetch on created/updated.

```elixir
def mount(_params, _session, socket) do
  user_id = socket.assigns.current_scope.user.id
  if connected?(socket), do: Phoenix.PubSub.subscribe(Glossary.PubSub, "user_projects:#{user_id}")

  {:ok,
   socket
   |> assign(:page_title, "All Projects")
   |> stream(:projects, Projects.list_projects(socket.assigns.current_scope))}
end

@impl true
def handle_info({event, project_id}, socket)
    when event in [:project_created, :project_updated] do
  project = Projects.get_project!(socket.assigns.current_scope, project_id)
  {:noreply, stream_insert(socket, :projects, project, at: if(event == :project_created, do: 0, else: -1))}
end

@impl true
def handle_info({:project_deleted, project_id}, socket) do
  {:noreply, stream_delete(socket, :projects, %Projects.Project{id: project_id})}
end
```

#### 1.8 TopicLive.Index — subscribe + handle_info

**File**: `lib/glossary_web/live/topic_live/index.ex`
**Changes**: Same pattern; topic `"user_topics:#{user_id}"`; uses `Topics.get_topic!`.

#### 1.9 TagLive.Index — subscribe + handle_info

**File**: `lib/glossary_web/live/tag_live/index.ex`
**Changes**: Same pattern; topic `"user_tags:#{user_id}"`; uses `Tags.get_tag!`. Note: `Tags.get_tag!` preloads `[:entries, :projects]` which is heavier than needed for the Index row, but is the only available function — acceptable for now.

### Success Criteria:

#### Automated Verification:
- [x] `mix precommit` passes (compile clean, 158 tests pass, credo clean)

#### Manual Verification:
- [ ] Open two browser tabs to `/projects`. Create a project in Tab 1 — it appears in Tab 2 without refresh.
- [ ] Update a project name in Tab 1 — the name updates in Tab 2's list.
- [ ] Delete a project in Tab 1 — it disappears from Tab 2.
- [ ] Repeat for `/topics` and `/tags`.
- [ ] Open `/` (Dashboard) in Tab 2, create an entry in Tab 1 — Dashboard stream updates.
- [ ] Delete an entry in Tab 1's `/entries` list — it disappears from Tab 2's list immediately.

---

## Phase 2: Debounced Entry Update Broadcast from EntryLive.Edit

### Overview
Add server-side debounced broadcasting from `EntryLive.Edit` for title/subtitle saves, and immediate broadcasting for status and relation changes. No subscription in `EntryLive.Edit` — it is the source of truth.

### Changes Required:

#### 2.1 Debounced broadcast in `save_field/2`

**File**: `lib/glossary_web/live/entry_live/edit.ex`
**Changes**: Add a `:broadcast_timer` assign (initialized to `nil` in `assign_picker_defaults/1`). In `save_field/2`, cancel any existing timer and schedule a new 5-second delayed broadcast.

New assign in `assign_picker_defaults/1`:
```elixir
|> assign(:broadcast_timer, nil)
```

Updated `save_field/2`:
```elixir
defp save_field(socket, attrs) do
  entry = socket.assigns.entry

  case Entries.upsert_entry(socket.assigns.current_scope, entry, attrs) do
    {:ok, entry} ->
      if socket.assigns.broadcast_timer, do: Process.cancel_timer(socket.assigns.broadcast_timer)
      timer = Process.send_after(self(), {:broadcast_entry_updated, entry.id}, 5_000)
      socket
      |> assign(:entry, entry)
      |> assign(:broadcast_timer, timer)

    {:error, _changeset} ->
      socket
  end
end
```

Add `handle_info` clause for the delayed broadcast:
```elixir
@impl true
def handle_info({:broadcast_entry_updated, entry_id}, socket) do
  user_id = socket.assigns.current_scope.user.id
  Phoenix.PubSub.broadcast(Glossary.PubSub, "user_entries:#{user_id}", {:entry_updated, entry_id})
  {:noreply, assign(socket, :broadcast_timer, nil)}
end
```

#### 2.2 Immediate broadcast after status change

**File**: `lib/glossary_web/live/entry_live/edit.ex`
**Changes**: In the `"set_status"` event handler, broadcast immediately on success.

```elixir
def handle_event("set_status", %{"status" => status}, socket) do
  user_id = socket.assigns.current_scope.user.id

  case Entries.update_entry(socket.assigns.current_scope, socket.assigns.entry, %{status: status}) do
    {:ok, entry} ->
      Phoenix.PubSub.broadcast(Glossary.PubSub, "user_entries:#{user_id}", {:entry_updated, entry.id})
      {:noreply, assign(socket, :entry, entry)}

    {:error, _} ->
      {:noreply, socket}
  end
end
```

#### 2.3 Immediate broadcast after relation toggles

**File**: `lib/glossary_web/live/entry_live/edit.ex`
**Changes**: In `toggle_project`, `toggle_topic`, and `toggle_tag` event handlers, broadcast immediately after the association change.

```elixir
# At the end of each toggle_* handler, after assigning the updated entry:
user_id = socket.assigns.current_scope.user.id
Phoenix.PubSub.broadcast(Glossary.PubSub, "user_entries:#{user_id}", {:entry_updated, entry.id})
```

### Success Criteria:

#### Automated Verification:
- [x] `mix precommit` passes

#### Manual Verification:
- [ ] Open `/entries` in Tab 2. Edit an entry's title in Tab 1. After ~5 seconds of no typing, the entry row in Tab 2 updates with the new title.
- [ ] While typing continuously, the Tab 2 update is deferred until typing stops for 5 seconds.
- [ ] Toggle a project on an entry in Tab 1. The entry's project badge updates immediately in Tab 2's `/entries` list.
- [ ] Change an entry's status in Tab 1. The entry row updates immediately in Tab 2.
- [ ] Open Dashboard in Tab 2. Toggle a relation in Tab 1. Dashboard recent_entries stream updates.

---

## Testing Strategy

### Manual Testing Steps:
1. Start dev server: `mix phx.server`
2. Open two tabs to the same page
3. Perform each mutation type in Tab 1, verify Tab 2 updates without refresh
4. Verify no double-updates when the originating tab performs the action (stream handles duplicates gracefully)
5. Verify that typing continuously in the Tiptap editor does NOT trigger rapid Tab 2 updates — only after 5s pause

## Key Implementation Notes

- `connected?(socket)` guard in `mount` ensures subscriptions only happen for WebSocket connections, not the initial HTTP render (prevents dead render from subscribing).
- `stream_insert` with `at: -1` for updates leaves items at their current DOM position; `at: 0` for creates prepends to top.
- `stream_delete` with a bare struct (`%Entry{id: id}`) works because LiveView stream only needs the `id` to compute the DOM ID for removal.
- The Dashboard reloads `recent_entries` via the context function, which hits the cache after the first load — the cache is invalidated by the broadcast handler before calling `recent_entries`, so the reload always fetches fresh data.
- `EntryLive.Edit` does NOT subscribe. If it did, it would receive its own broadcasts and potentially overwrite in-progress edits.
- `Process.cancel_timer` is safe to call even if the timer has already fired (returns `false` instead of the remaining time).

## References

- Related research: `thoughts/shared/research/2026-02-21-scalability-analysis.md` (Bottleneck #9)
- PubSub docs: `Phoenix.PubSub.subscribe/2`, `Phoenix.PubSub.broadcast/3`
- Existing handle_info pattern: `lib/glossary_web/live/project_live/show.ex:99`
