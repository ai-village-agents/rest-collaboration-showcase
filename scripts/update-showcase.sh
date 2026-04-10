#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-showcase.sh [all|sonnet|sonnet-1301|sonnet-l7|opus-9206|opus-9305|opus-9404|opus-9503|opus-9602|opus-9701|opus-9800|opus-9910|opus-10000|opus-10100|opus-10108|opus-10207]

Updates index.html milestones using sed with line numbers discovered via grep -n.
Creates a timestamped backup before editing and shows a diff afterward.
  all         Run Sonnet + opus-10108 updates (default)
  sonnet      Set Sonnet milestone line to: 'Level 6 ACHIEVED! 1003/1350 XP. HP 59/69, 9-day perfect streak (Days 365-373), 115 enemies defeated, zero crashes, autosave validated.'
  sonnet-1301 Set Sonnet milestone line to: 'Level 6 Assassin: 1301/1350 XP (96.4% to L7!). HP 59/69, 9-day perfect streak (Days 365-373), 76 journal entries, zero crashes, autosave validated.'
  sonnet-l7   Set Sonnet milestone line to: 'Level 7 Assassin ACHIEVED! 1350/1350 XP (100% to L8!). HP 59/69, 9-day perfect streak (Days 365-373), 76+ journal entries, zero crashes, autosave validated.'
  opus-9206   Update Opus to 9,206 damage (76th milestone 9,200 achieved!)
  opus-9305   Update Opus to 9,305 damage (77th milestone 9,300 achieved!)
  opus-9404   Update Opus to 9,404 damage (78th milestone 9,400 achieved!)
  opus-9503   Update Opus to 9,503 damage (79th milestone 9,500 achieved!)
  opus-9602   Update Opus to 9,602 damage (80th milestone 9,600 achieved!)
  opus-9701   Update Opus to 9,701 damage (81st milestone 9,700 achieved!)
  opus-9800   Update Opus to 9,800 damage (82nd milestone 9,800 achieved!)
  opus-9910   Update Opus to 9,910 damage (83rd milestone 9,910 achieved!)
  opus-10000  Update Opus to 10,000 damage (84th milestone 10,000 achieved!)
  opus-10100  Update Opus to 10,100 damage (85th milestone 10,100 achieved!)
  opus-10108  Update Opus to 10,108 damage (85th milestone 10,100 achieved!)
  opus-10207  Update Opus to 10,207 damage (86th milestone 10,200 achieved!)
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

update_sonnet_1301() {
  echo "Updating Sonnet milestone to Level 6 Assassin..."
  replace_line_containing "Level 6 Assassin" "                <div class=\"feature-desc\">Level 6 Assassin: 1301/1350 XP (96.4% to L7!). HP 59/69, 9-day perfect streak (Days 365-373), 76 journal entries, zero crashes, autosave validated.</div>" "Sonnet active session line"
}

update_sonnet_l7() {
  echo "Updating Sonnet milestone to Level 7 Assassin..."
  replace_line_containing "Level 6 Assassin" "                <div class=\"feature-desc\">Level 7 Assassin ACHIEVED! 1350/1350 XP (100% to L8!). HP 59/69, 9-day perfect streak (Days 365-373), 76+ journal entries, zero crashes, autosave validated.</div>" "Sonnet active session line"
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

update_opus_9701() {
  echo "Updating Opus milestone to 9,701 damage..."
  update_opus_to "9,701" "81" "9,700" "2,200" "9,482" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!)."
}

update_opus_9800() {
  echo "Updating Opus milestone to 9,800 damage..."
  update_opus_to "9,800" "82" "9,800" "2,299" "9,581" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!)."
}

update_opus_9910() {
  echo "Updating Opus milestone to 9,910 damage..."
  update_opus_to "9,910" "83" "9,910" "2,409" "9,691" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!)."
}

update_opus_10000() {
  echo "Updating Opus milestone to 10,000 damage..."
  update_opus_to "10,000" "84" "10,000" "2,499" "9,781" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!)."
}

update_opus_10100() {
  echo "Updating Opus milestone to 10,100 damage..."
  update_opus_to "10,100" "85" "10,100" "2,599" "9,881" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!)."
}

update_opus_10108() {
  echo "Updating Opus milestone to 10,108 damage..."
  update_opus_to "10,108" "85" "10,100" "2,607" "9,889" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!)."
}

update_opus_10207() {
  echo "Updating Opus milestone to 10,207 damage..."
  update_opus_to "10,207" "86" "10,200" "99" "9,988" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!)."
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
    all|sonnet|sonnet-1301|sonnet-l7|opus-9206|opus-9305|opus-9404|opus-9503|opus-9602|opus-9701|opus-9800|opus-9910|opus-10000|opus-10100|opus-10108|opus-10207) ;;
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
    sonnet-1301) update_sonnet_1301 ;;
    sonnet-l7) update_sonnet_l7 ;;
    opus-9206) update_opus_9206 ;;
    opus-9305) update_opus_9305 ;;
    opus-9404) update_opus_9404 ;;
    opus-9503) update_opus_9503 ;;
    opus-9602) update_opus_9602 ;;
    opus-9701) update_opus_9701 ;;
    opus-9800) update_opus_9800 ;;
    opus-9910) update_opus_9910 ;;
    opus-10000) update_opus_10000 ;;
    opus-10100) update_opus_10100 ;;
    opus-10108) update_opus_10108 ;;
    opus-10207) update_opus_10207 ;;
    all)
      update_sonnet_l6
      update_opus_10108
      ;;
  esac

  show_diff
  echo "Done."
}

main "$@"
