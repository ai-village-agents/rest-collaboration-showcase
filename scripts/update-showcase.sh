#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-showcase.sh [all|sonnet|opus-9206|opus-9305|opus-9404|opus-9503|opus-9602]

Updates index.html milestones using sed with line numbers discovered via grep -n.
Creates a timestamped backup before editing and shows a diff afterward.
  all         Run Sonnet + opus-9602 updates (default)
  sonnet      Set Sonnet milestone line to: 'Level 6 ACHIEVED! 1003/1350 XP. HP 59/69, 9-day perfect streak (Days 365-373), 115 enemies defeated, zero crashes, autosave validated.'
  opus-9206   Update Opus to 9,206 damage (76th milestone 9,200 achieved!)
  opus-9305   Update Opus to 9,305 damage (77th milestone 9,300 achieved!)
  opus-9404   Update Opus to 9,404 damage (78th milestone 9,400 achieved!)
  opus-9503   Update Opus to 9,503 damage (79th milestone 9,500 achieved!)
  opus-9602   Update Opus to 9,602 damage (80th milestone 9,600 achieved!)
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

replace_line_containing() {
  local needle="$1"
  local replacement="$2"
  local label="$3"
  local line escaped_new

  line="$(find_line "$needle")"
  escaped_new="$(printf '%s' "$replacement" | sed 's/[\\&]/\\&/g')"

  sed -i "${line}c\\${escaped_new}" "$INDEX_HTML"
  echo "sed -i \"${line}c\\\\${escaped_new}\" \"$INDEX_HTML\"  # ${label}"
}

update_sonnet_l6() {
  echo "Updating Sonnet milestone to Level 6..."
  replace_line_containing "Level 6 ACHIEVED!" "                <div class=\"feature-desc\">Level 6 ACHIEVED! 1003/1350 XP. HP 59/69, 9-day perfect streak (Days 365-373), 115 enemies defeated, zero crashes, autosave validated.</div>" "Sonnet active session line"
}

update_opus_to() {
  local damage="$1"
  local milestone_num="$2"
  local milestone_label="$3"
  local today_gain="$4"
  local total_gain="$5"
  local milestone_list_text="$6"
  local summary_line detailed_line

  summary_line="                <div class=\"feature-desc\">Opus 4.5: 219 → ${damage} damage over Days 367-373 (${milestone_num} milestones, +${total_gain} gain, zero crashes).</div>"
  detailed_line="                <div class=\"feature-desc\">Damage run: <strong>${damage} damage (${milestone_num}th milestone ${milestone_label} achieved!)</strong> (+${today_gain} today, +${total_gain} total gain), HP 37/55, Poison 2, Potions 10. Milestones hit: ${milestone_list_text} 7-day streak: 219 → ${damage} (+${total_gain}), ${milestone_num} milestones, 700+ enemies, ZERO crashes.</div>"

  replace_line_containing "Opus 4.5: 219 →" "$summary_line" "Opus summary card"
  replace_line_containing "Damage run: <strong>" "$detailed_line" "Opus detailed run"
}

update_opus_9206() {
  echo "Updating Opus milestone to 9,206 damage..."
  update_opus_to "9,206" "76" "9,200" "1,705" "8,987" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 (76th milestone!)."
}

update_opus_9305() {
  echo "Updating Opus milestone to 9,305 damage..."
  update_opus_to "9,305" "77" "9,300" "1,804" "9,086" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 (77th milestone!)."
}

update_opus_9404() {
  echo "Updating Opus milestone to 9,404 damage..."
  update_opus_to "9,404" "78" "9,400" "1,903" "9,185" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 (78th milestone!)."
}

update_opus_9503() {
  echo "Updating Opus milestone to 9,503 damage..."
  update_opus_to "9,503" "79" "9,500" "2,002" "9,284" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!)."
}

update_opus_9602() {
  echo "Updating Opus milestone to 9,602 damage..."
  update_opus_to "9,602" "80" "9,600" "2,101" "9,383" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!)."
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
    all|sonnet|opus-9206|opus-9305|opus-9404|opus-9503|opus-9602) ;;
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
    opus-9206) update_opus_9206 ;;
    opus-9305) update_opus_9305 ;;
    opus-9404) update_opus_9404 ;;
    opus-9503) update_opus_9503 ;;
    opus-9602) update_opus_9602 ;;
    all)
      update_sonnet_l6
      update_opus_9602
      ;;
  esac

  show_diff
  echo "Done."
}

main "$@"
