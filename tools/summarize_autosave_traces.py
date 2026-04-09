#!/usr/bin/env python3
"""Summarize autosave trace JSON files under contributions/autosave-traces/.

Purpose
- Quickly review autosave traces dropped by multiple agents.
- Handles both single objects and arrays of trace objects (first element used).
- Produces either Markdown (table) or JSON output and can write to a file or stdout.

Expected field mapping
- contributor -> agent
- tag -> event
- slotKey -> saveKey
- build defaults to "unknown" when absent.
- savedAt is preferred; timestamp is the fallback.

Usage
  python3 tools/summarize_autosave_traces.py \
    --dir contributions/autosave-traces \
    --format md \
    --output contributions/autosave-traces/summary.md
"""

from __future__ import annotations

import argparse
import json
import os
import re
from dataclasses import dataclass
from datetime import datetime
from glob import glob
from typing import Any, Dict, List, Optional, Tuple


@dataclass
class Row:
    filename: str
    agent: Optional[str]
    build: Optional[str]
    event: Optional[str]
    save_key: Optional[str]
    level: Optional[int]
    xp: Optional[int]
    phase: Optional[str]
    auto_save_reason: Optional[str]
    pending_levelups: Optional[int]
    saved_at: Optional[str]

    def to_dict(self) -> Dict[str, Any]:
        return {
            "file": self.filename,
            "agent": self.agent,
            "build": self.build,
            "event": self.event,
            "saveKey": self.save_key,
            "level": self.level,
            "xp": self.xp,
            "phase": self.phase,
            "autoSaveReason": self.auto_save_reason,
            "pendingLevelUps": self.pending_levelups,
            "savedAt": self.saved_at,
        }


def _first_record(data: Any) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Return (metadata, trace_record) where metadata can live on the wrapper object.

    Supported layouts:
    - Direct trace object
    - Array of trace objects (first element used)
    - Wrapper with `traces` array (first element used)
    """
    if isinstance(data, list):
        record = data[0] if data else {}
        return {}, record if isinstance(record, dict) else {}

    if isinstance(data, dict):
        if isinstance(data.get("traces"), list):
            record = data["traces"][0] if data["traces"] else {}
            return data, record if isinstance(record, dict) else {}
        if isinstance(data.get("save"), dict):
            # Legacy wrapper used by some scripts.
            return data, data["save"]  # type: ignore[return-value]
        return data, data

    return {}, {}


def _as_int(value: Any) -> Optional[int]:
    if value is None or isinstance(value, bool):
        return None
    try:
        return int(value)
    except Exception:
        return None


def _as_str(value: Any) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    try:
        return str(value)
    except Exception:
        return None


def _pending_len(record: Dict[str, Any]) -> Optional[int]:
    if "pendingLevelUpsLen" in record:
        candidate = _as_int(record.get("pendingLevelUpsLen"))
        if candidate is not None:
            return candidate
    pending = record.get("pendingLevelUps")
    if isinstance(pending, list):
        return len(pending)
    return None


def _choose_str(*options: Any) -> Optional[str]:
    for val in options:
        candidate = _as_str(val)
        if candidate:
            return candidate
    return None


def parse_filename_fallback(filename: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """Extract agent/build/event from filename when JSON fields are missing.

    Patterns:
    - Optional YYYY-MM-DD_ prefix
    - Agent token before the first build token; underscores inside agent map to dots
    - Build token is one of {"pages", "githack", "unknown"}
    - Remaining suffix is the event (underscores preserved)
    """
    stem = os.path.splitext(os.path.basename(filename))[0]
    parts = stem.split("_")

    if parts and re.match(r"^\d{4}-\d{2}-\d{2}$", parts[0]):
        parts = parts[1:]

    if not parts:
        return None, None, None

    build_tokens = {"pages", "githack", "unknown"}
    build_idx: Optional[int] = None
    for idx, token in enumerate(parts):
        if token in build_tokens:
            build_idx = idx
            break

    if build_idx is None:
        return None, None, None

    agent_parts = parts[:build_idx]
    agent = "_".join(agent_parts).replace("_", ".") if agent_parts else None

    build = parts[build_idx]
    event_parts = parts[build_idx + 1 :]
    event = "_".join(event_parts) if event_parts else None

    return agent, build, event


def parse_trace(path: str) -> Row:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    metadata, record = _first_record(data)
    if not isinstance(record, dict):
        record = {}

    fallback_agent, fallback_build, fallback_event = parse_filename_fallback(
        os.path.basename(path)
    )

    agent = _choose_str(
        record.get("agent"),
        metadata.get("agent"),
        record.get("contributor"),
        metadata.get("contributor"),
    )
    if agent is None:
        agent = fallback_agent

    build = _choose_str(record.get("build"), metadata.get("build"))
    if (build is None or build == "unknown") and fallback_build:
        build = fallback_build
    if build is None:
        build = "unknown"

    event = _choose_str(
        record.get("event"),
        record.get("tag"),
        metadata.get("event"),
        metadata.get("tag"),
    )
    if event is None:
        event = fallback_event

    save_key = _choose_str(
        record.get("saveKey"),
        record.get("slotKey"),
        metadata.get("saveKey"),
        metadata.get("slotKey"),
    )

    return Row(
        filename=os.path.basename(path),
        agent=agent,
        build=build,
        event=event,
        save_key=save_key,
        level=_as_int(record.get("level")),
        xp=_as_int(record.get("xp")),
        phase=_choose_str(record.get("phase"), metadata.get("phase")),
        auto_save_reason=_choose_str(
            record.get("autoSaveReason"), metadata.get("autoSaveReason")
        ),
        pending_levelups=_pending_len(record),
        saved_at=_choose_str(
            record.get("savedAt"),
            record.get("timestamp"),
            metadata.get("savedAt"),
            metadata.get("timestamp"),
        ),
    )


def _generated_at() -> str:
    return f"{datetime.utcnow().isoformat(timespec='seconds')}Z"


def as_md(rows: List[Row]) -> str:
    lines = []
    lines.append(f"Generated: {_generated_at()}")
    lines.append("")
    lines.append("| file | agent | build | event | saveKey | lvl | xp | phase | autoSaveReason | pendingLevelUps | savedAt |")
    lines.append("|---|---|---|---|---|---:|---:|---|---|---:|---|")
    for r in rows:
        lines.append(
            "| {file} | {agent} | {build} | {event} | {save_key} | {lvl} | {xp} | {phase} | {reason} | {pend} | {saved_at} |".format(
                file=r.filename,
                agent=r.agent or "",
                build=r.build or "unknown",
                event=r.event or "",
                save_key=r.save_key or "",
                lvl="" if r.level is None else r.level,
                xp="" if r.xp is None else r.xp,
                phase=r.phase or "",
                reason=r.auto_save_reason or "",
                pend="" if r.pending_levelups is None else r.pending_levelups,
                saved_at=r.saved_at or "",
            )
        )
    return "\n".join(lines) + "\n"


def as_json(rows: List[Row]) -> str:
    payload = {
        "generated_at": _generated_at(),
        "rows": [r.to_dict() for r in rows],
    }
    return json.dumps(payload, indent=2)


def _run_self_test() -> bool:
    try:
        agent, build, event = parse_filename_fallback(
            "2026-04-08_gpt-5-1_githack_warrior_l1_combat_victory.json"
        )
        assert agent == "gpt-5-1"
        assert build == "githack"
        assert event == "warrior_l1_combat_victory"

        agent, build, event = parse_filename_fallback(
            "2026-04-08_claude-sonnet-4_5_unknown_sonnet_level5_achievement.json"
        )
        assert agent == "claude-sonnet-4.5"
        assert build == "unknown"
        assert event == "sonnet_level5_achievement"

        assert parse_filename_fallback("agent_only_trace.json") == (None, None, None)
    except AssertionError:
        return False
    return True


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Summarize autosave trace JSON files into Markdown or JSON."
    )
    ap.add_argument(
        "--dir",
        default="contributions/autosave-traces",
        help="Directory containing .json traces",
    )
    ap.add_argument(
        "--format",
        default="md",
        choices=["md", "json"],
        help="Output format",
    )
    ap.add_argument(
        "--output",
        help="Optional output file; defaults to stdout when omitted",
    )
    ap.add_argument(
        "--self-test",
        action="store_true",
        help="Run a small self-test of filename fallback parsing and exit",
    )
    args = ap.parse_args()

    if args.self_test:
        return 0 if _run_self_test() else 1

    paths = sorted(glob(os.path.join(args.dir, "*.json")))
    rows = []
    for p in paths:
        try:
            rows.append(parse_trace(p))
        except Exception as e:
            rows.append(
                Row(
                    filename=os.path.basename(p),
                    agent=None,
                    build="unknown",
                    event=None,
                    save_key=None,
                    level=None,
                    xp=None,
                    phase=None,
                    auto_save_reason=f"ERROR: {type(e).__name__}: {e}",
                    pending_levelups=None,
                    saved_at=None,
                )
            )

    rendered = as_json(rows) if args.format == "json" else as_md(rows)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(rendered)
    else:
        print(rendered, end="")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
