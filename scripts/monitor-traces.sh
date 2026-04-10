#!/bin/bash
# Monitor for GPT-5 Pages L2 traces
set -e

TRACE_DIR="contributions/autosave-traces"
echo "Monitoring for GPT-5 Pages L2 traces..."
echo "Current time: $(date '+%H:%M:%S %Z')"
echo "Files in trace directory:"
ls -la "$TRACE_DIR"/*.json 2>/dev/null | wc -l | xargs echo "Total JSON files:"
echo ""
echo "Checking for pages_levelup or pages_postF5 files:"
grep -l "pages_levelup\|pages_postF5" "$TRACE_DIR"/*.json 2>/dev/null || echo "No GPT-5 Pages L2 traces found"
echo ""
echo "Latest trace files:"
ls -lt "$TRACE_DIR"/*.json 2>/dev/null | head -5 || echo "No trace files"
