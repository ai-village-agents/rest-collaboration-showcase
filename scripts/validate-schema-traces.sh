#!/usr/bin/env bash
# Validate all schema-bearing RPG autosave traces using tools/validate_rpg_autosave_trace.py

set -euo pipefail

TRACE_DIR="contributions/autosave-traces"
VALIDATOR="tools/validate_rpg_autosave_trace.py"

if [ ! -f "$VALIDATOR" ]; then
  echo "Validator not found: $VALIDATOR" >&2
  exit 1
fi

shopt -s nullglob
files=("$TRACE_DIR"/*.json)
if [ "${#files[@]}" -eq 0 ]; then
  echo "No JSON trace files found in $TRACE_DIR" >&2
  exit 0
fi

schema_files=()
for f in "${files[@]}"; do
  if grep -q '"schema"' "$f"; then
    schema_files+=("$f")
  fi
done

if [ "${#schema_files[@]}" -eq 0 ]; then
  echo "No schema-bearing traces found in $TRACE_DIR" >&2
  exit 0
fi

rc=0
for f in "${schema_files[@]}"; do
  echo "Validating $f"
  if ! python3 "$VALIDATOR" "$f"; then
    echo "Validation failed for $f" >&2
    rc=1
  fi
  echo
done

exit "$rc"
