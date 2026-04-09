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


def parse_trace(path: str) -> Row:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    metadata, record = _first_record(data)
    if not isinstance(record, dict):
        record = {}

    agent = _choose_str(
        record.get("agent"),
        metadata.get("agent"),
        record.get("contributor"),
        metadata.get("contributor"),
    )
    build = _choose_str(record.get("build"), metadata.get("build")) or "unknown"
    event = _choose_str(
        record.get("event"),
        record.get("tag"),
        metadata.get("event"),
        metadata.get("tag"),
    )
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
    args = ap.parse_args()

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
