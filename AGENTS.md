# Repository Guidelines

This repository is the **Glossary** Phoenix (Elixir) web application. Follow these guidelines for consistent, reliable contributions.

## Project Overview
- **App Name**: Glossary
- **Framework**: Phoenix 1.8+ with LiveView
- **Database**: PostgreSQL via Ecto
- **Frontend**: Phoenix LiveView, TailwindCSS, DaisyUI, Heroicons
- **Build Tools**: esbuild (JS), Tailwind (CSS)
- **Server**: Bandit (HTTP/2 capable)
- **Local URL**: http://localhost:4000

## Project Structure & Module Organization
- **Core application code** (`lib/`):
  - `lib/glossary/` – domain, contexts, business logic, and Ecto schemas
    - `application.ex` – OTP application supervisor
    - `repo.ex` – Ecto repository
    - `mailer.ex` – email delivery via Swoosh
  - `lib/glossary_web/` – web layer (LiveView, components, controllers, HTML)
    - `endpoint.ex` – HTTP endpoint configuration
    - `router.ex` – route definitions
    - `components/` – reusable LiveView components
    - `live/macros/` – custom macros for LiveView patterns
    - `controllers/` – traditional Phoenix controllers (if any)
    - `gettext.ex` – internationalization
    - `telemetry.ex` – metrics and monitoring
- **Frontend assets** (`assets/`):
  - `assets/css/app.css` – main stylesheet (imports Tailwind)
  - `assets/js/app.js` – JS entry point, LiveView hooks
  - `assets/vendor/` – third-party JS (DaisyUI, heroicons, topbar)
  - `assets/tsconfig.json` – TypeScript configuration
- **Tests** (`test/`):
  - Mirror `lib/` structure
  - Use `DataCase` for business logic, `ConnCase`/`LiveCase` for web tests
- **Database** (`priv/repo/`):
  - `migrations/` – schema migrations
  - `seeds.exs` – seed data
- **Static assets** (`priv/static/`):
  - Compiled assets and public files (favicon, robots.txt)

**Conventions**:
- One module per file
- Use `Glossary.Context` and `Glossary.Context.Schema` patterns
- Contexts expose public APIs; keep implementation details private

## Getting Started

### Initial Setup
```bash
# Clone and navigate to the repo
cd glossary

# Install dependencies, create DB, run migrations, seed data, and build assets
mix setup

# Start the Phoenix server
mix phx.server
# Or start with an interactive shell
iex -S mix phx.server

# Visit http://localhost:4000
```

### Common Mix Tasks
| Command | Purpose |
|---------|---------|
| `mix setup` | Full setup: deps, DB, migrations, seeds, assets |
| `mix deps.get` | Install/update dependencies |
| `mix ecto.setup` | Create DB, run migrations, seed data |
| `mix ecto.reset` | Drop and recreate DB (destructive!) |
| `mix ecto.migrate` | Run pending migrations |
| `mix ecto.rollback` | Rollback last migration |
| `mix phx.server` | Start development server |
| `iex -S mix phx.server` | Start server with interactive Elixir shell |
| `mix test` | Run full test suite |
| `mix test test/path/to/file_test.exs` | Run specific test file |
| `mix test --only focus:true` | Run only focused tests (@tag :focus) |
| `mix format` | Format all Elixir code |
| `mix compile --warnings-as-errors` | Strict compilation check |
| `mix deps.unlock --unused` | Remove unused dependencies |
| `mix precommit` | Run pre-commit checks (compile, format, test) |

### Asset Pipeline
- **Tailwind CSS**: Utility-first CSS framework
  - `mix tailwind glossary` – compile CSS
  - `mix tailwind.install` – install Tailwind binary
- **esbuild**: JavaScript bundler
  - `mix esbuild glossary` – compile JS
  - `mix esbuild.install` – install esbuild binary
- **Asset commands**:
  - `mix assets.setup` – install Tailwind and esbuild binaries
  - `mix assets.build` – build all assets for dev
  - `mix assets.deploy` – build and minify for production

### Pre-commit Hooks
This project uses `pre-commit` for automated checks:
- **Setup** (one-time): `pip install pre-commit && pre-commit install`
- **Hooks run automatically** on `git commit`
- **Manual run**: `pre-commit run --all-files`

Configured hooks:
- YAML validation, trailing whitespace, EOF fixes
- Merge conflict detection
- `mix precommit` (compile, format, test)

## Coding Style & Naming Conventions
- **Formatter**: Elixir formatter with Phoenix/Ecto plugins
  - 2-space indentation (enforced by formatter)
  - Run `mix format` before committing
  - Configured in `.formatter.exs`
- **Module naming**:
  - Business logic: `Glossary.Context.Schema`
  - Web layer: `GlossaryWeb.ComponentLive` or `GlossaryWeb.PageController`
  - LiveViews end with `Live` (e.g., `GlossaryWeb.GlossaryLive`)
  - Components in `GlossaryWeb.Components.*`
- **Function naming**:
  - Use `snake_case` for functions and variables
  - Predicate functions end with `?` (e.g., `active?/1`)
  - Bang functions for raising errors: `fetch!/1`
- **Context patterns**:
  - Contexts expose clear public APIs
  - Keep schemas/queries private when possible
  - Example: `Glossary.Accounts.get_user(id)` not `Repo.get(User, id)`

## Phoenix LiveView Guidelines
- **Component organization**:
  - Reusable components: `lib/glossary_web/components/`
  - Page LiveViews: `lib/glossary_web/live/`
  - Core UI components: `core_components.ex`
- **LiveView lifecycle**:
  - `mount/3` – initialize socket state
  - `handle_params/3` – handle URL parameters
  - `handle_event/3` – handle client events
  - `handle_info/2` – handle async messages
- **Best practices**:
  - Keep business logic in contexts, not LiveViews
  - Use function components for static/simple UI
  - Use stateful components for complex interactions
  - Minimize socket assigns; only store what's needed
  - Use `Phoenix.Component` for reusable UI elements

## Macros & Code Generation

This project uses custom macros to reduce boilerplate and ensure consistent patterns across LiveViews.

### KeybindMacros Module
Located at `lib/glossary_web/live/macros/keybind_macros.ex`, this module provides macros for common LiveView event handling patterns:

- **`pubsub_broadcast/3`** – Broadcasts messages to PubSub topics
- **`pubsub_broadcast_on_event/4`** – Generates complete `handle_event/3` functions with PubSub broadcasting
- **`keybind_listeners/0`** – Generates keyboard event handlers with leader key support (Cmd/Ctrl + K for search)

### Usage Examples
```elixir
# Generate event handlers with PubSub broadcasting
pubsub_broadcast_on_event("open_search_modal", :show_search_modal, true, "search_modal")

# Generate keyboard listeners with leader key support
keybind_listeners()
```

### Macro Guidelines
- Keep macros focused on reducing repetitive patterns
- Document macro behavior and parameters clearly
- Test macro-generated code thoroughly
- Use macros for LiveView event handling, not business logic

## PubSub Communication

This application uses Phoenix PubSub for real-time communication between LiveView processes.

### Configuration
- **PubSub Server**: `Glossary.PubSub` (configured in `application.ex`)
- **Topics**: Use descriptive topic names (e.g., `"search_modal"`, `"notifications"`)

### Common Patterns

#### Broadcasting Messages
```elixir
# Direct broadcast
Phoenix.PubSub.broadcast(Glossary.PubSub, "topic_name", {:event, value})

# Using macros (recommended)
pubsub_broadcast("topic_name", :assign_key, value)
```

#### Subscribing to Topics
```elixir
# In mount/3 when connected
if connected?(socket) do
  Phoenix.PubSub.subscribe(Glossary.PubSub, "topic_name")
end

# Handle messages in handle_info/2
def handle_info({:event_name, value}, socket) do
  {:noreply, assign(socket, :key, value)}
end
```

### Current Topics
- **`"search_modal"`** – Controls search modal visibility across the application
  - Messages: `{:show_search_modal, boolean}`

### Best Practices
- Use descriptive topic names
- Keep message formats consistent within topics
- Subscribe only when necessary (in `mount/3` with `connected?/1` check)
- Use macros for common broadcasting patterns
- Test PubSub communication in LiveView tests

## Search Modal Implementation

The search modal is a key feature implemented using LiveView, PubSub, and JavaScript hooks.

### Architecture
- **Main Component**: `GlossaryWeb.SearchLive` – Handles modal state and rendering
- **Parent Integration**: Rendered via `live_render/3` in `HomeLive`
- **Communication**: PubSub topic `"search_modal"` for state synchronization
- **JavaScript Hook**: `SearchModal` hook for focus management

### Features
- **Keyboard Shortcuts**: Cmd/Ctrl + K to open, Escape to close (when leader key is down)
- **Click-to-Open**: Click search bar to open modal
- **Auto-focus**: JavaScript hook automatically focuses search input when opened
- **Click-away**: Click outside modal to close
- **Attribute Badges**: Visual indicators for search modifiers (`@tag`, `#subject`, `&project`, `!`)

### Components Used
- **`attribute_badge/1`** – Renders search modifier badges
- **`icon/1`** – Heroicons for UI elements
- **DaisyUI Modal** – Base modal styling and behavior

### Testing
The search modal includes comprehensive tests covering:
- PubSub message handling
- Keyboard shortcut integration
- JavaScript hook attachment
- Modal state management
- Integration with parent LiveView

### Usage in Tests
```elixir
# Open modal via PubSub
Phoenix.PubSub.broadcast(Glossary.PubSub, "search_modal", {:show_search_modal, true})

# Test keyboard shortcuts
view |> element("div[phx-window-keydown=\"key_down\"]") |> render_keydown(%{"key" => "Meta"})
view |> element("div[phx-window-keydown=\"key_down\"]") |> render_keydown(%{"key" => "k"})
```

## Testing Guidelines
- **Framework**: ExUnit with Phoenix test helpers
- **Test types**:
  - `DataCase` – database/context tests (business logic)
  - `ConnCase` – controller tests (traditional requests)
  - `LiveCase` – LiveView tests (interactive UI)
- **File organization**:
  - Tests mirror `lib/` structure
  - Name files `*_test.exs`
  - Place in corresponding `test/` subdirectories
- **Writing tests**:
  - Keep tests isolated and deterministic
  - Use factories/fixtures for test data
  - Clean up database state automatically (Ecto sandbox)
- **Running tests**:
  - `mix test` – full suite
  - `mix test test/specific_test.exs` – single file
  - `mix test test/specific_test.exs:42` – single test at line 42
  - Add `@tag :focus` and run `mix test --only focus:true`
  - Use `@moduletag :capture_log` to suppress logs in tests

## Database & Ecto
- **Repo**: `Glossary.Repo`
- **Migrations**:
  - Generate: `mix ecto.gen.migration create_things`
  - Run: `mix ecto.migrate`
  - Rollback: `mix ecto.rollback` or `mix ecto.rollback --step 2`
- **Seeds**: Edit `priv/repo/seeds.exs`, run with `mix run priv/repo/seeds.exs`
- **Schema conventions**:
  - Use `schema "tablename"` for database tables
  - Use `embedded_schema` for virtual structs
  - Define changesets for validation/casting
  - Keep schema modules under their context

## Deployment & Production
- **Environment configs**:
  - `config/config.exs` – shared config
  - `config/dev.exs` – development
  - `config/test.exs` – test environment
  - `config/prod.exs` – production (compile-time)
  - `config/runtime.exs` – runtime config (reads ENV vars)
- **Production build**:
  ```bash
  mix assets.deploy  # Build and minify assets
  mix phx.digest     # Generate asset digests (included in assets.deploy)
  MIX_ENV=prod mix release
  ```
- **Production checklist**:
  - Set `SECRET_KEY_BASE` (generate with `mix phx.gen.secret`)
  - Configure `DATABASE_URL` or database credentials
  - Set `PHX_HOST` for URL generation
  - Configure mailer settings (SMTP, etc.)
  - Enable SSL/TLS in production
  - Set up monitoring (Phoenix LiveDashboard, telemetry)

## Git & Commit Guidelines
- **Commit messages**:
  - Use imperative mood: "Add feature" not "Added feature"
  - Keep subject line under 50 chars
  - Add detail in body if needed
  - Examples: "Add user authentication", "Fix typo in README"
- **Commit hygiene**:
  - Group related changes in single commits
  - Keep commits atomic and focused
  - Run `mix precommit` before committing
- **Pull Requests**:
  - Include: summary, rationale, screenshots (for UI), linked issues
  - Keep diffs small and reviewable
  - Ensure CI passes: format, tests, compilation
  - Request reviews from appropriate team members

## Security & Configuration
- **Secrets management**:
  - Never commit secrets, API keys, passwords
  - Use environment variables for sensitive config
  - Local dev: use `.env` file (add to `.gitignore`)
  - Production: use secure secret management (K8s secrets, AWS Secrets Manager, etc.)
- **Configuration pattern**:
  - Compile-time config: `config/*.exs`
  - Runtime config: `config/runtime.exs` (reads `System.get_env/1`)
- **Dependencies**:
  - **HTTP client**: Use `Req` (already included)
  - **Avoid**: HTTPoison, HTTPotion, or other HTTP clients
  - Keep dependencies updated; review security advisories

## Troubleshooting
- **Port already in use**: Change port in `config/dev.exs` or kill process on port 4000
- **Database connection errors**: Ensure PostgreSQL is running; check credentials in `config/dev.exs`
- **Asset compilation issues**: Run `mix assets.setup` then `mix assets.build`
- **Dependencies issues**: Try `mix deps.clean --all && mix deps.get`
- **Compilation errors**: Run `mix clean && mix compile`
- **Test database issues**: `MIX_ENV=test mix ecto.reset`

## Additional Resources
- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView Docs](https://hexdocs.pm/phoenix_live_view/)
- [Ecto Documentation](https://hexdocs.pm/ecto/)
- [Elixir Forum](https://elixirforum.com/)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
