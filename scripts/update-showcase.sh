#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-showcase.sh [all|sonnet|sonnet-1301|sonnet-l7|gpt5-l2|opus-9206|opus-9305|opus-9404|opus-9503|opus-9602|opus-9701|opus-9800|opus-9910|opus-10000|opus-10100|opus-10108|opus-10207|opus-10300|opus-10306|opus-10400|opus-10405|opus-10500|opus-10600|opus-10700|opus-10800|opus-10900|opus-11000|opus-11100|opus-11200|opus-11300|opus-11400|opus-11500|opus-11600|opus-11700|opus-11800|opus-11900|opus-12000|opus-12100|opus-12200|opus-12300|opus-12400|opus-12500|opus-12600|opus-12682|opus-12780|opus-12880|opus-12980|opus-13080|opus-13180|opus-13280|opus-13380|opus-13480|opus-13580]

Updates index.html milestones using sed with line numbers discovered via grep -n.
Creates a timestamped backup before editing and shows a diff afterward.
  all         Run Sonnet L7 + opus-10306 updates (default)
  sonnet      Set Sonnet milestone line to: 'Level 6 ACHIEVED! 1003/1350 XP. HP 59/69, 9-day perfect streak (Days 365-374), 115 enemies defeated, zero crashes, autosave validated.'
  sonnet-1301 Set Sonnet milestone line to: 'Level 6 Assassin: 1301/1350 XP (96.4% to L7!). HP 59/69, 9-day perfect streak (Days 365-374), 76 journal entries, zero crashes, autosave validated.'
  sonnet-l7   Set Sonnet milestone line to: 'Level 7 Assassin ACHIEVED! 1350/1350 XP (100% to L8!). HP 59/69, 9-day perfect streak (Days 365-374), 76+ journal entries, zero crashes, autosave validated.'
  gpt5-l2     Set GPT-5 line to: 'Level 2 Cleric ACHIEVED! 150/150 XP (100% to L3!). Autosave traces collected and F5 validation completed.'
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
  opus-10300  Update Opus to 10,300 damage (87th milestone 10,300 achieved!)
  opus-10306  Update Opus to 10,306 damage (87th milestone 10,300 achieved!)
  opus-10400  Update Opus to 10,400 damage (88th milestone 10,400 achieved!)
  opus-10405  Update Opus to 10,405 damage (88th milestone 10,400 achieved!)
  opus-10500  Update Opus to 10,500 damage (89th milestone 10,500 achieved!)
  opus-10600  Update Opus to 10,600 damage (90th milestone 10,600 achieved!)
  opus-10700  Update Opus to 10,700 damage (91st milestone 10,700 achieved!)
  opus-10800  Update Opus to 10,800 damage (92nd milestone 10,800 achieved!)
  opus-10900  Update Opus to 10,900 damage (93rd milestone 10,900 achieved!)
  opus-11000  Update Opus to 11,000 damage (94th milestone 11,000 achieved!)
  opus-11100  Update Opus to 11,100 damage (95th milestone 11,100 achieved!)
  opus-11200  Update Opus to 11,200 damage (96th milestone 11,200 achieved!)
  opus-11300  Update Opus to 11,300 damage (97th milestone 11,300 achieved!)
  opus-11400  Update Opus to 11,400 damage (98th milestone 11,400 achieved!)
  opus-11500  Update Opus to 11,500 damage (99th milestone 11,500 achieved!)
  opus-11600  Update Opus to 11,600 damage (100th milestone 11,600 achieved!)
  opus-11700  Update Opus to 11,700 damage (101st milestone 11,700 achieved!)
  opus-11800  Update Opus to 11,800 damage (102nd milestone 11,800 achieved!)
  opus-11900  Update Opus to 11,900 damage (103rd milestone 11,900 achieved!)
  opus-12000  Update Opus to 12,000 damage (104th milestone 12,000 achieved!)
  opus-12100  Update Opus to 12,100 damage (105th milestone 12,100 achieved!)
  opus-12200  Update Opus to 12,200 damage (106th milestone 12,200 achieved!)
  opus-12300  Update Opus to 12,300 damage (107th milestone 12,300 achieved!)
  opus-12400  Update Opus to 12,400 damage (108th milestone 12,400 achieved!)
  opus-12500  Update Opus to 12,500 damage (109th milestone 12,500 achieved!)
  opus-12600  Update Opus to 12,600 damage (110th milestone 12,600 achieved!)
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
  replace_line_containing "Level 6 ACHIEVED!" "                <div class=\"feature-desc\">Level 6 ACHIEVED! 1003/1350 XP. HP 59/69, 9-day perfect streak (Days 365-374), 115 enemies defeated, zero crashes, autosave validated.</div>" "Sonnet active session line"
}

update_sonnet_1301() {
  echo "Updating Sonnet milestone to Level 6 Assassin..."
  replace_line_containing "Level 6 Assassin" "                <div class=\"feature-desc\">Level 6 Assassin: 1301/1350 XP (96.4% to L7!). HP 59/69, 9-day perfect streak (Days 365-374), 76 journal entries, zero crashes, autosave validated.</div>" "Sonnet active session line"
}

update_sonnet_l7() {
  echo "Updating Sonnet milestone to Level 7 Assassin..."
  replace_line_containing "Level 6 Assassin" "                <div class=\"feature-desc\">Level 7 Assassin ACHIEVED! 1350/1350 XP (100% to L8!). HP 59/69, 9-day perfect streak (Days 365-374), 76+ journal entries, zero crashes, autosave validated.</div>" "Sonnet active session line"
}

update_gpt5_l2() {
  echo "Updating GPT-5 milestone to Level 2 Cleric..."
  replace_line_containing "QA5 Cleric Level 2 grinding on Pages build, autosave trace collection and F5 validation pending." "                <div class=\"feature-desc\">Level 2 Cleric ACHIEVED! 150/150 XP (100% to L3!). Autosave traces collected and F5 validation completed.</div>" "GPT-5 active session line"
}

update_opus_to() {
  local damage="$1"
  local milestone_num="$2"
  local milestone_label="$3"
  local today_gain="$4"
  local total_gain="$5"
  local milestone_list_text="$6"
  local summary_line

  summary_line="                <div class=\"feature-desc\">Opus 4.5: 219 → ${damage} damage over Days 367-374 (${milestone_num} milestones, +${total_gain} gain, zero crashes).</div>"

  # Detailed line removed from template - only summary line is updated
  replace_line_containing "Opus 4.5: 219 →" "$summary_line" "Opus summary card"
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

update_opus_10300() {
  echo "Updating Opus milestone to 10,300 damage..."
  update_opus_to "10,300" "87" "10,300" "192" "10,081" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!)."
}

update_opus_10400() {
  echo "Updating Opus milestone to 10,400 damage..."
  update_opus_to "10,400" "88" "10,400" "292" "10,181" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!)."
}

update_opus_10306() {
  echo "Updating Opus milestone to 10,306 damage..."
  update_opus_to "10,306" "87" "10,300" "2,805" "10,087" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!)."
}

update_opus_10405() {
  echo "Updating Opus milestone to 10,405 damage..."
  update_opus_to "10,405" "88" "10,400" "2,904" "10,186" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!)."
}

update_opus_10500() {
  echo "Updating Opus milestone to 10,500 damage..."
  update_opus_to "10,500" "89" "10,500" "2,999" "10,281" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!)."
}

update_opus_10600() {
  echo "Updating Opus milestone to 10,600 damage..."
  update_opus_to "10,600" "90" "10,600" "3,099" "10,381" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!)."
}

update_opus_10700() {
  echo "Updating Opus milestone to 10,700 damage..."
  update_opus_to "10,700" "91" "10,700" "3,199" "10,481" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!)."
}

update_opus_10800() {
  echo "Updating Opus milestone to 10,800 damage..."
  update_opus_to "10,800" "92" "10,800" "3,299" "10,581" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!)."
}

update_opus_10900() {
  echo "Updating Opus milestone to 10,900 damage..."
  update_opus_to "10,900" "93" "10,900" "3,399" "10,681" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!)."
}

update_opus_11000() {
  echo "Updating Opus milestone to 11,000 damage..."
  update_opus_to "11,000" "94" "11,000" "3,499" "10,781" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!)."
}

update_opus_11100() {
  echo "Updating Opus milestone to 11,100 damage..."
  update_opus_to "11,100" "95" "11,100" "3,599" "10,881" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!)."
}

update_opus_11200() {
  echo "Updating Opus milestone to 11,200 damage..."
  update_opus_to "11,200" "96" "11,200" "3,699" "10,981" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!)."
}

update_opus_11300() {
  echo "Updating Opus milestone to 11,300 damage..."
  update_opus_to "11,300" "97" "11,300" "3,799" "11,081" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!)."
}

update_opus_11400() {
  echo "Updating Opus milestone to 11,400 damage..."
  update_opus_to "11,400" "98" "11,400" "3,899" "11,181" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!)."
}

update_opus_11500() {
  echo "Updating Opus milestone to 11,500 damage..."
  update_opus_to "11,500" "99" "11,500" "3,999" "11,281" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!)."
}

update_opus_11600() {
  echo "Updating Opus milestone to 11,600 damage..."
  update_opus_to "11,600" "100" "11,600" "4,099" "11,381" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!)."
}

update_opus_11700() {
  echo "Updating Opus milestone to 11,700 damage..."
  update_opus_to "11,700" "101" "11700" "4,199" "11,481" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!)."
}

update_opus_11800() {
  echo "Updating Opus milestone to 11,800 damage..."
  update_opus_to "11,800" "102" "11800" "4,299" "11,581" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!)."
}

update_opus_11900() {
  echo "Updating Opus milestone to 11,900 damage..."
  update_opus_to "11,900" "103" "11900" "4,399" "11,681" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!)."
}

update_opus_12000() {
  echo "Updating Opus milestone to 12,000 damage..."
  update_opus_to "12,000" "104" "12000" "4,499" "11,781" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!)."
}

update_opus_12100() {
  echo "Updating Opus milestone to 12,100 damage..."
  update_opus_to "12,100" "105" "12100" "4,599" "11,881" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!)."
}

update_opus_12200() {
  echo "Updating Opus milestone to 12,200 damage..."
  update_opus_to "12,200" "106" "12200" "4,699" "11,981" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!)."
}

update_opus_12300() {
  echo "Updating Opus milestone to 12,300 damage..."
  update_opus_to "12,300" "107" "12300" "4,799" "12,081" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!)."
}

update_opus_12400() {
  echo "Updating Opus milestone to 12,400 damage..."
  update_opus_to "12,400" "108" "12400" "4,899" "12,181" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!)."
}

update_opus_12500() {
  echo "Updating Opus milestone to 12,500 damage..."
  update_opus_to "12,500" "109" "12500" "4,999" "12,281" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!)."
}

update_opus_12600() {
  echo "Updating Opus milestone to 12,600 damage..."
  update_opus_to "12,600" "110" "12600" "5,099" "12,381" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!)."
}

update_opus_12682() {
  echo "Updating Opus milestone to 12,682 damage..."
  update_opus_to "12,682" "111" "12682" "2,574" "12,463" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!)."
}

update_opus_12780() {
  echo "Updating Opus milestone to 12,781 damage..."
  update_opus_to "12,781" "112" "12780" "2,673" "12,562" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!)."
}

update_opus_12880() {
  echo "Updating Opus milestone to 12,880 damage..."
  update_opus_to "12,880" "113" "12880" "2,772" "12,661" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!)."
}

update_opus_12980() {
  echo "Updating Opus milestone to 12,980 damage..."
  update_opus_to "12,980" "114" "12980" "2,872" "12,761" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!)."
}

update_opus_13080() {
  echo "Updating Opus milestone to 13,080 damage..."
  update_opus_to "13,080" "115" "13080" "2,972" "12,861" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!). → 13,080 (115th milestone!)."
}

update_opus_13180() {
  echo "Updating Opus milestone to 13,180 damage..."
  update_opus_to "13,180" "116" "13180" "3,072" "12,961" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!). → 13,080 (115th milestone!). → 13,180 (116th milestone!)."
}

update_opus_13280() {
  echo "Updating Opus milestone to 13,280 damage..."
  update_opus_to "13,280" "117" "13280" "3,172" "13,061" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!). → 13,080 (115th milestone!). → 13,180 (116th milestone!). → 13,280 (117th milestone!)."
}

update_opus_13380() {
  echo "Updating Opus milestone to 13,380 damage..."
  update_opus_to "13,380" "118" "13380" "3,272" "13,161" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!). → 13,080 (115th milestone!). → 13,180 (116th milestone!). → 13,280 (117th milestone!). → 13,380 (118th milestone!)."
}

update_opus_13480() {
  echo "Updating Opus milestone to 13,480 damage..."
  update_opus_to "13,480" "119" "13480" "3,372" "13,261" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!). → 13,080 (115th milestone!). → 13,180 (116th milestone!). → 13,280 (117th milestone!). → 13,380 (118th milestone!). → 13,480 (119th milestone!)."
}

update_opus_13580() {
  echo "Updating Opus milestone to 13,580 damage..."
  update_opus_to "13,580" "120" "13580" "3,472" "13,361" "8,300 → 8,400 → 8,500 → 8,600 → 8,700 → 8,800 → 8,900 → 9,000 → 9,100 → 9,200 → 9,300 → 9,400 → 9,500 (79th milestone!) → 9,600 (80th milestone!) → 9,700 (81st milestone!) → 9,800 (82nd milestone!) → 9,910 (83rd milestone!) → 10,000 (84th milestone!) → 10,100 (85th milestone!) → 10,200 (86th milestone!) → 10,300 (87th milestone!) → 10,400 (88th milestone!) → 10,500 (89th milestone!) → 10,600 (90th milestone!) → 10,700 (91st milestone!) → 10,800 (92nd milestone!) → 10,900 (93rd milestone!) → 11,000 (94th milestone!) → 11,100 (95th milestone!) → 11,200 (96th milestone!) → 11,300 (97th milestone!) → 11,400 (98th milestone!) → 11,500 (99th milestone!) → 11,600 (100th milestone!) → 11,700 (101st milestone!) → 11,800 (102nd milestone!) → 11,900 (103rd milestone!) → 12,000 (104th milestone!) → 12,100 (105th milestone!) → 12,200 (106th milestone!) → 12,300 (107th milestone!) → 12,400 (108th milestone!) → 12,500 (109th milestone!) → 12,600 (110th milestone!). → 12,682 (111th milestone!). → 12,781 (112th milestone!). → 12,880 (113th milestone!). → 12,980 (114th milestone!). → 13,080 (115th milestone!). → 13,180 (116th milestone!). → 13,280 (117th milestone!). → 13,380 (118th milestone!). → 13,480 (119th milestone!). → 13,580 (120th milestone!)."
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
    all|sonnet|sonnet-1301|sonnet-l7|gpt5-l2|opus-9206|opus-9305|opus-9404|opus-9503|opus-9602|opus-9701|opus-9800|opus-9910|opus-10000|opus-10100|opus-10108|opus-10207|opus-10300|opus-10306|opus-10400|opus-10405|opus-10500|opus-10600|opus-10700|opus-10800|opus-10900|opus-11000|opus-11100|opus-11200|opus-11300|opus-11400|opus-11500|opus-11600|opus-11700|opus-11800|opus-11900|opus-12000|opus-12100|opus-12200|opus-12300|opus-12400|opus-12500|opus-12600|opus-12682|opus-12780) ;;
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
    gpt5-l2) update_gpt5_l2 ;;
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
    opus-10300) update_opus_10300 ;;
    opus-10306) update_opus_10306 ;;
    opus-10400) update_opus_10400 ;;
    opus-10405) update_opus_10405 ;;
    opus-10500) update_opus_10500 ;;
    opus-10600) update_opus_10600 ;;
    opus-10700) update_opus_10700 ;;
    opus-10800) update_opus_10800 ;;
    opus-10900) update_opus_10900 ;;
    opus-11000) update_opus_11000 ;;
    opus-11100) update_opus_11100 ;;
    opus-11200) update_opus_11200 ;;
    opus-11300) update_opus_11300 ;;
    opus-11400) update_opus_11400 ;;
    opus-11500) update_opus_11500 ;;
    opus-11600) update_opus_11600 ;;
    opus-11700) update_opus_11700 ;;
    opus-11800) update_opus_11800 ;;
    opus-11900) update_opus_11900 ;;
    opus-12000) update_opus_12000 ;;
    opus-12100) update_opus_12100 ;;
    opus-12200) update_opus_12200 ;;
    opus-12300) update_opus_12300 ;;
    opus-12400) update_opus_12400 ;;
    opus-12500) update_opus_12500 ;;
    opus-12600) update_opus_12600 ;;
    opus-12682) update_opus_12682 ;;
    opus-12780) update_opus_12780 ;;
    opus-12880) update_opus_12880 ;;
    opus-12980) update_opus_12980 ;;
    opus-13080) update_opus_13080 ;;
    opus-13180) update_opus_13180 ;;
    opus-13280) update_opus_13280 ;;
    opus-13380) update_opus_13380 ;;
    opus-13480) update_opus_13480 ;;
    opus-13580) update_opus_13580 ;;
    all)
      update_sonnet_l7
      update_opus_10306
      ;;
  esac

  show_diff
  echo "Done."
}

main "$@"
