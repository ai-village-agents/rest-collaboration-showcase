#!/usr/bin/env bash
# Summarize RPG autosave traces in contributions/autosave-traces

set -euo pipefail

TRACE_DIR="contributions/autosave-traces"

if [ ! -d "$TRACE_DIR" ]; then
  echo "Trace directory not found: $TRACE_DIR" >&2
  exit 1
fi

files=("$TRACE_DIR"/*.json)
if [ ! -e "${files[0]}" ]; then
  echo "No JSON trace files found in $TRACE_DIR" >&2
  exit 0
fi

echo "Autosave trace summary for $TRACE_DIR";
printf 'Total JSON files: %s\n\n' "${#files[@]}";

python3 - "$TRACE_DIR" << 'PY'
import json, sys, pathlib

trace_dir = pathlib.Path(sys.argv[1])
files = sorted(trace_dir.glob('*.json'))

rows = []
for path in files:
    try:
        with path.open('r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception as e:
        rows.append((path.name, 'ERROR', '-', '-', f'load error: {e.__class__.__name__}'))
        continue

    if not isinstance(data, dict):
        rows.append((path.name, 'ERROR', '-', '-', f'root type {type(data).__name__}'))
        continue

    tag = data.get('tag', 'UNKNOWN')
    has_schema = 'schema' in data

    game_obj = data.get('game') if isinstance(data.get('game'), dict) else {}
    char_obj = data.get('character') if isinstance(data.get('character'), dict) else {}
    state_obj = data.get('state') if isinstance(data.get('state'), dict) else {}

    game_name = game_obj.get('name') or data.get('gameName') or '-'
    env = game_obj.get('environment') or '-'
    level = char_obj.get('level') or data.get('level') or state_obj.get('level') or '-'

    schema_flag = 'v0.1' if has_schema else 'legacy'
    rows.append((path.name, tag, schema_flag, str(level), f"{game_name} / {env}"))

# Print table header
print(f"{'FILE':<55} {'TAG':<24} {'SCHEMA':<8} {'LVL':<4} CONTEXT")
print('-' * 100)
for name, tag, schema_flag, level, ctx in rows:
    if len(tag) > 23:
        tag_disp = tag[:20] + '...'
    else:
        tag_disp = tag
    print(f"{name:<55} {tag_disp:<24} {schema_flag:<8} {level:<4} {ctx}")
PY
