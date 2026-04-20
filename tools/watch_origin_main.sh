#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Watch a GitHub repo's origin/main head and print when it changes.

Defaults:
  --repo-dir: current directory
  --interval: 20 seconds
  --state: .git/watch_origin_main.state (inside repo-dir)

Examples:
  # Watch with default settings (prints on every new head)
  bash tools/watch_origin_main.sh

  # Only print Deploy commits
  bash tools/watch_origin_main.sh --deploy-only

  # Watch a specific checkout and log to a file
  bash tools/watch_origin_main.sh --repo-dir /tmp/rcs_gpt52 --log /tmp/rcs_watch.log

Options:
  --repo-dir PATH     Git checkout to watch (default: cwd)
  --interval N        Poll interval seconds (default: 20)
  --state FILE        Where to store last seen SHA (default: <repo>/.git/watch_origin_main.state)
  --log FILE          Also append output lines to a log file
  --match REGEX       Only print lines whose subject matches REGEX (case-insensitive)
  --deploy-only       Equivalent to --match '^(\S+\s+)?Deploy\b'
  --heartbeat N       Emit a heartbeat line every N seconds (default: 300)
  -h, --help          Show this help

Notes:
- Uses `git ls-remote` to avoid heavy fetches when nothing changes.
- When the SHA changes, it runs `git fetch origin main` to read the latest subject.
USAGE
}

repo_dir="$(pwd)"
interval=20
state_file=""
log_file=""
match_regex=""
heartbeat=300

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      repo_dir="$2"; shift 2;;
    --interval)
      interval="$2"; shift 2;;
    --state)
      state_file="$2"; shift 2;;
    --log)
      log_file="$2"; shift 2;;
    --match)
      match_regex="$2"; shift 2;;
    --deploy-only)
      match_regex='^(\S+\s+)?Deploy\b'; shift 1;;
    --heartbeat)
      heartbeat="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1" >&2
      usage >&2
      exit 2;;
  esac
done

if [[ -z "$state_file" ]]; then
  state_file="$repo_dir/.git/watch_origin_main.state"
fi

mkdir -p "$(dirname "$state_file")"

last=""
if [[ -f "$state_file" ]]; then
  last="$(cat "$state_file" 2>/dev/null || true)"
fi

log_line() {
  local line="$1"
  echo "$line"
  if [[ -n "$log_file" ]]; then
    printf '%s\n' "$line" >> "$log_file"
  fi
}

log_line "[$(date -Is)] watch_origin_main started (repo=$repo_dir interval=${interval}s)"

last_hb=0
while true; do
  now_epoch=$(date +%s)
  if (( now_epoch - last_hb >= heartbeat )); then
    log_line "[$(date -Is)] heartbeat"
    last_hb=$now_epoch
  fi

  # Lightweight poll
  remote_sha=$(git -C "$repo_dir" ls-remote origin -h refs/heads/main | awk '{print $1}')
  if [[ -z "$remote_sha" ]]; then
    sleep "$interval"; continue
  fi

  if [[ "$remote_sha" != "$last" ]]; then
    # Fetch only when SHA changes so we can read the subject.
    timeout 20s git -C "$repo_dir" fetch origin main --quiet || { sleep "$interval"; continue; }
    subject=$(git -C "$repo_dir" log -1 --format=%s origin/main 2>/dev/null || true)
    short=$(printf '%.7s' "$remote_sha")

    echo "$remote_sha" > "$state_file"
    last="$remote_sha"

    # If a match filter is provided, only print matching subjects.
    if [[ -n "$match_regex" ]]; then
      if echo "$subject" | grep -qiE "$match_regex"; then
        log_line "[$(date -Is)] NEW $remote_sha $subject"
      fi
    else
      log_line "[$(date -Is)] NEW $remote_sha $subject"
    fi
  fi

  sleep "$interval"
done
