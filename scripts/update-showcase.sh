#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-showcase.sh [all|sonnet|opus]

Updates index.html milestones using sed with line numbers discovered via grep -n.
Creates a timestamped backup before editing and shows a diff afterward.
  all     Run both updates (default)
  sonnet  Update Sonnet to Level 6 achieved
  opus    Update Opus to 8,909 damage milestone
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INDEX_HTML="${REPO_ROOT}/index.html"
BACKUP_PATH=""

require_index() {
  if [[ ! -f "$INDEX_HTML" ]]; then
    echo "index.html not found at $INDEX_HTML" >&2
    exit 1
  fi
}

make_backup() {
  if [[ -n "$BACKUP_PATH" ]]; then
    return
  fi
  BACKUP_PATH="${INDEX_HTML}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$INDEX_HTML" "$BACKUP_PATH"
  echo "Backup created: $BACKUP_PATH"
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\/&]/\\&/g'
}

find_line() {
  local needle="$1"
  local line
  line="$(grep -nF "$needle" "$INDEX_HTML" | cut -d: -f1 | head -n1 || true)"
  if [[ -z "$line" ]]; then
    echo "Expected text not found: $needle" >&2
    return 1
  fi
  printf '%s\n' "$line"
}

replace_on_line() {
  local needle="$1"
  local replacement="$2"
  local label="$3"
  local line escaped_old escaped_new

  line="$(find_line "$needle")"
  escaped_old="$(escape_sed "$needle")"
  escaped_new="$(escape_sed "$replacement")"

  sed -i "${line}s/${escaped_old}/${escaped_new}/" "$INDEX_HTML"
  echo "sed -i \"${line}s/${escaped_old}/${escaped_new}/\" \"$INDEX_HTML\"  # ${label}"
}

update_sonnet_l6() {
  echo "Updating Sonnet milestone to Level 6..."
  replace_on_line "Level 5 ACHIEVED!" "Level 6 ACHIEVED!" "Sonnet level label"
  replace_on_line "902/1000 XP (90% to L6)" "1000/1000 XP" "Sonnet XP progress"
}

update_opus_8900() {
  echo "Updating Opus milestone to 8,909 damage..."
  replace_on_line "8,800 damage (72nd milestone!)" "8,909 damage (73rd milestone 8,900 achieved!)" "Opus damage headline"
  replace_on_line "+1,299 today" "+1,408 today" "Opus daily gain"
  replace_on_line "+8,581 total gain" "+8,690 total gain" "Opus total gain"
  replace_on_line "7-day streak: 219 → 8,800 (+8,581)" "7-day streak: 219 → 8,909 (+8,690)" "Opus 7-day streak"
  replace_on_line "72 milestones, 700+ enemies" "73 milestones, 700+ enemies" "Opus milestone count (run summary)"
  replace_on_line "Opus 4.5: 219 → 8,800 damage over Days 367-373 (72 milestones, +8,581 gain, zero crashes)." \
                  "Opus 4.5: 219 → 8,909 damage over Days 367-373 (73 milestones, +8,690 gain, zero crashes)." \
                  "Opus summary card"
}

show_diff() {
  if [[ -z "$BACKUP_PATH" ]]; then
    echo "No backup present; skipping diff." >&2
    return
  fi
  echo
  echo "Diff vs backup (${BACKUP_PATH}):"
  diff -u "$BACKUP_PATH" "$INDEX_HTML" || true
}

main() {
  local target="${1:-all}"
  case "$target" in
    -h|--help) usage; exit 0 ;;
    all|sonnet|opus) ;;
    *)
      echo "Unknown target: $target" >&2
      usage
      exit 1
      ;;
  esac

  require_index
  make_backup

  case "$target" in
    sonnet) update_sonnet_l6 ;;
    opus) update_opus_8900 ;;
    all)
      update_sonnet_l6
      update_opus_8900
      ;;
  esac

  show_diff
  echo "Done."
}

main "$@"
