#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
RUN_DIR="$PROJECT_ROOT/.run"
PID_FILE="$RUN_DIR/glossary.pid"
LOG_FILE="$RUN_DIR/glossary.log"

info() {
  printf "\n==> %s\n" "$1"
}

warn() {
  printf "[warn] %s\n" "$1"
}

is_running_pid() {
  local pid="$1"
  kill -0 "$pid" >/dev/null 2>&1
}

read_pid_file() {
  if [ ! -f "$PID_FILE" ]; then
    return 1
  fi
  tr -d '[:space:]' <"$PID_FILE"
}

stop_server() {
  local pid=""
  if pid="$(read_pid_file 2>/dev/null || true)"; then
    if [ -n "$pid" ] && is_running_pid "$pid"; then
      info "Stopping existing Phoenix server (pid $pid)"
      kill "$pid"
      for _ in {1..20}; do
        if ! is_running_pid "$pid"; then
          break
        fi
        sleep 0.5
      done
      if is_running_pid "$pid"; then
        warn "Server did not exit after SIGTERM; sending SIGKILL"
        kill -9 "$pid"
      fi
    else
      warn "PID file found but process is not running: $pid"
    fi
  else
    warn "No running server found"
  fi
  rm -f "$PID_FILE"
}

status_server() {
  local pid=""
  if pid="$(read_pid_file 2>/dev/null || true)" && [ -n "$pid" ] && is_running_pid "$pid"; then
    printf "[ok] glossary is running (pid=%s)\n" "$pid"
    printf "[ok] logs: %s\n" "$LOG_FILE"
  else
    printf "[ok] glossary is not running\n"
    printf "[ok] logs: %s\n" "$LOG_FILE"
  fi
}

check_required_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf "[error] Missing required command: %s\n" "$cmd" >&2
    exit 1
  fi
  printf "[ok] %s: %s\n" "$cmd" "$(command -v "$cmd")"
}

check_optional_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "[ok] %s: %s\n" "$cmd" "$(command -v "$cmd")"
  else
    warn "Optional command not found: $cmd"
  fi
}

run_setup() {
  info "Checking command dependencies"
  check_required_cmd elixir
  check_required_cmd mix
  check_optional_cmd ollama

  cd "$PROJECT_ROOT"

  info "Preparing production environment"
  export MIX_ENV="${MIX_ENV:-prod}"
  export PHX_SERVER="${PHX_SERVER:-true}"
  export PHX_HOST="${PHX_HOST:-localhost}"
  export PORT="${PORT:-4400}"
  export DATABASE_URL="${DATABASE_URL:-postgres://postgres:postgres@localhost:5432/glossary_prod}"

  if [ -z "${SECRET_KEY_BASE:-}" ]; then
    SECRET_KEY_BASE="$(mix phx.gen.secret)"
    export SECRET_KEY_BASE
    warn "SECRET_KEY_BASE was not set; generated ephemeral value for this run"
  fi

  printf "[ok] MIX_ENV=%s\n" "$MIX_ENV"
  printf "[ok] PHX_HOST=%s\n" "$PHX_HOST"
  printf "[ok] PORT=%s\n" "$PORT"

  info "Installing dependencies"
  mix deps.get

  info "Setting up database"
  mix ecto.create
  mix ecto.migrate

  info "Building production assets"
  mix assets.deploy
}

start_server() {
  mkdir -p "$RUN_DIR"

  info "Starting Phoenix server in background"
  printf "App will be available at http://localhost:%s\n" "$PORT"

  nohup mix phx.server >>"$LOG_FILE" 2>&1 &
  local pid="$!"
  printf "%s\n" "$pid" >"$PID_FILE"
  sleep 1

  if is_running_pid "$pid"; then
    printf "[ok] started (pid=%s)\n" "$pid"
    printf "[ok] log file: %s\n" "$LOG_FILE"
  else
    printf "[error] Failed to start Phoenix server\n" >&2
    printf "[error] Inspect logs: %s\n" "$LOG_FILE" >&2
    exit 1
  fi
}

usage() {
  cat <<EOF
Usage: ./run.sh [restart|start|stop|status|logs]

  restart  Stop existing process, run setup, then start in background (default)
  start    Run setup and start in background if not already running
  stop     Stop the background process
  status   Show current process status
  logs     Follow the log file
EOF
}

main() {
  local command="${1:-restart}"
  case "$command" in
  status)
    status_server
    ;;
  stop)
    stop_server
    ;;
  logs)
    mkdir -p "$RUN_DIR"
    touch "$LOG_FILE"
    exec tail -n 100 -f "$LOG_FILE"
    ;;
  start)
    if pid="$(read_pid_file 2>/dev/null || true)" && [ -n "$pid" ] && is_running_pid "$pid"; then
      warn "Server is already running (pid=$pid). Use ./run.sh restart"
      exit 1
    fi
    run_setup
    start_server
    ;;
  restart)
    stop_server
    run_setup
    start_server
    ;;
  -h | --help | help)
    usage
    ;;
  *)
    printf "[error] Unknown command: %s\n" "$command" >&2
    usage
    exit 1
    ;;
  esac
}

main "$@"
