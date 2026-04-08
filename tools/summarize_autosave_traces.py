#!/usr/bin/env python3
"""Summarize autosave trace JSON files under contributions/autosave-traces/.

Purpose
- When multiple agents drop raw JSON traces, this script produces a quick, human-readable
  summary (Markdown) so maintainers can sanity-check that traces are present and coherent.

Usage
  python3 tools/summarize_autosave_traces.py \
    --dir contributions/autosave-traces \
    --format md

Notes
- Accepts either:
  (a) the save object itself (with keys like player/phase/autoSaveReason/savedAt), or
  (b) a wrapper object with a top-level `save` field containing the save.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import dataclass
from datetime import datetime
from glob import glob
from typing import Any, Dict, Optional, Tuple


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


def _dig_save(obj: Dict[str, Any]) -> Tuple[Dict[str, Any], Dict[str, Any]]:
    """Return (wrapper, save). If no wrapper, wrapper=={} and save==obj."""
    if isinstance(obj, dict) and isinstance(obj.get("save"), dict):
        return obj, obj["save"]
    return {}, obj


def _get_int(x: Any) -> Optional[int]:
    try:
        if x is None:
            return None
        if isinstance(x, bool):
            return None
        return int(x)
    except Exception:
        return None


def _isoish(x: Any) -> Optional[str]:
    if not x:
        return None
    if isinstance(x, str):
        return x
    return None


def _row_from_save_like(filename: str, wrapper: dict, save_like: dict) -> Row:
    player = save_like.get("player") if isinstance(save_like, dict) else None
    if not isinstance(player, dict):
        player = {}

    pending = save_like.get("pendingLevelUps")
    pending_len = None
    if isinstance(pending, list):
        pending_len = len(pending)

    # Some trace formats store level/xp at top-level
    lvl = _get_int(player.get("level"))
    xp = _get_int(player.get("xp"))
    if lvl is None:
        lvl = _get_int(save_like.get("level"))
    if xp is None:
        xp = _get_int(save_like.get("xp"))

    phase = save_like.get("phase") if isinstance(save_like.get("phase"), str) else None
    reason = (
        save_like.get("autoSaveReason")
        if isinstance(save_like.get("autoSaveReason"), str)
        else None
    )
    saved_at = _isoish(save_like.get("savedAt"))

    # Alternate field names used in some trace records
    event = wrapper.get("event") if wrapper else None
    save_key = wrapper.get("saveKey") if wrapper else None
    if not save_key and isinstance(save_like.get("slotKey"), str):
        save_key = save_like.get("slotKey")

    # Timestamp field used in list-of-records traces
    if not saved_at and isinstance(save_like.get("timestamp"), str):
        saved_at = save_like.get("timestamp")

    return Row(
        filename=filename,
        agent=(wrapper.get("agent") if wrapper else None),
        build=(wrapper.get("build") if wrapper else None),
        event=event,
        save_key=save_key,
        level=lvl,
        xp=xp,
        phase=phase,
        auto_save_reason=reason,
        pending_levelups=(
            pending_len
            if pending_len is not None
            else (_get_int(save_like.get("pendingLevelUpsLen")))
        ),
        saved_at=saved_at,
    )


def parse_traces(path: str) -> list[Row]:
    with open(path, "r", encoding="utf-8") as f:
        obj = json.load(f)

    filename = os.path.basename(path)

    # Case 1: wrapper with `save`
    if isinstance(obj, dict) and isinstance(obj.get("save"), dict):
        wrapper, save = obj, obj["save"]
        return [_row_from_save_like(filename, wrapper, save)]

    # Case 2: Sonnet-style wrapper with `traces: [...]`
    if isinstance(obj, dict) and isinstance(obj.get("traces"), list):
        wrapper = {"agent": obj.get("agent")}
        rows: list[Row] = []
        for rec in obj["traces"]:
            if isinstance(rec, dict):
                # include tag as event if present
                w = dict(wrapper)
                if isinstance(rec.get("tag"), str):
                    w["event"] = rec.get("tag")
                rows.append(_row_from_save_like(filename, w, rec))
        return rows or [_row_from_save_like(filename, wrapper, {})]

    # Case 3: list-of-records format
    if isinstance(obj, list):
        rows: list[Row] = []
        for rec in obj:
            if isinstance(rec, dict):
                w = {}
                if isinstance(rec.get("contributor"), str):
                    w["agent"] = rec.get("contributor")
                if isinstance(rec.get("tag"), str):
                    w["event"] = rec.get("tag")
                rows.append(_row_from_save_like(filename, w, rec))
        return rows

    # Case 4: raw save object
    if isinstance(obj, dict):
        return [_row_from_save_like(filename, {}, obj)]

    return [_row_from_save_like(filename, {}, {})]


def as_md(rows: list[Row]) -> str:
(rows: list[Row]) -> str:
    lines = []
    lines.append(f"Generated: {datetime.utcnow().isoformat(timespec='seconds')}Z")
    lines.append("")
    lines.append("| file | agent | build | event | saveKey | lvl | xp | phase | autoSaveReason | pendingLevelUps | savedAt |")
    lines.append("|---|---|---|---|---|---:|---:|---|---|---:|---|")
    for r in rows:
        lines.append(
            "| {file} | {agent} | {build} | {event} | {save_key} | {lvl} | {xp} | {phase} | {reason} | {pend} | {saved_at} |".format(
                file=r.filename,
                agent=r.agent or "",
                build=r.build or "",
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


def main() -> int:
    ap = argparse.ArgumentParser()
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
    args = ap.parse_args()

    paths = sorted(glob(os.path.join(args.dir, "*.json")))
    rows = []
    for p in paths:
        try:
            rows.extend(parse_traces(p))
        except Exception as e:
            rows.append(
                Row(
                    filename=os.path.basename(p),
                    agent=None,
                    build=None,
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

    if args.format == "json":
        print(json.dumps([r.__dict__ for r in rows], indent=2))
    else:
        print(as_md(rows))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
