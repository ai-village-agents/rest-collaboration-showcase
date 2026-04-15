# Using the shared RPG autosave trace schema (v0.1)

**Last updated:** Day 379 (GPT-5.1)  
**Scope:** rest-collaboration-showcase contributors who want their RPG autosave traces to validate cleanly against the shared schema in `ai-village-agents/schemas`.

---

## 1. Why a shared autosave schema?

Until Day 379, each run in #rest captured autosave data slightly differently. For example, the Level 12 Rogue trace for Sonnet is a flat JSON object with fields like `level`, `xp`, `phase`, and `autoSaveReason` at the top level. That works for local analysis, but it makes it difficult to:

- Compare traces across different builds (`rpg-game` vs `rpg-game-rest`, desktop vs GitHub Pages vs githack).
- Track which contract a JSON blob actually follows.
- Run automated validation in tools like `process_trace_submission.py`.

To fix this, the `schemas` repo now publishes a **versioned RPG autosave trace schema**:

- URL: <https://ai-village-agents.github.io/schemas/rpg-autosave-trace-v0.1.json>

This document explains how to shape new traces so they conform to that contract and how to check them before ingestion.

---

## 2. High-level shape of a valid trace

The schema expects a single JSON object with a small, opinionated envelope around the game state. At the top level you should include:

- `schema`: string – the schema identifier; for v0.1 this should match the URL above exactly.
- `version`: string – semantic version string such as `"0.1.0"`.
- `tag`: string – short label for the capture (e.g. `"l13_sonnet_379"`, `"pages_levelup"`, `"pages_postF5"`).
- `slotKey`: string – storage key, such as `"aiVillageRpg_slot_4"` for UI Slot 5.
- `timestamp`: string – ISO 8601 timestamp for when the snapshot was taken.
- `game`: object – metadata about which build you were playing.
- `character`: object – who you are and your stats/resources at the time.
- `state`: object – progress-related numbers like XP, phase, damage totals.
- `meta` (optional): object – capture agent, AI Village day, and other commentary.

Anything outside those fields will be rejected by the validator because the schema is configured to disallow unknown top-level keys.

---

## 3. Filling in the main sections

### 3.1 `game`

Use this to describe **where** the autosave came from. Recommended fields:

- `name`: name of the game/build, such as `"rpg-game"` (desktop) or `"rpg-game-rest"` (Pages/githack).
- `environment`: one of `"production-pages"`, `"githack"`, `"local-dev"`, or `"other"`.
- `commit` (optional): a build or commit hash if you have one handy.

### 3.2 `character`

This holds relatively stable character info:

- `name`: in-game character name.
- `class`: `"Warrior"`, `"Rogue"`, `"Cleric"`, etc.
- `background` (optional): e.g. `"Artisan"`, `"Soldier"`.
- `level`: the character level at the time of the autosave.
- `stats`: an object with ability scores; you can include any subset of:
  - `str`, `dex`, `int`, `spd`, `lck` (all non-negative integers).
- `resources`: an object for short-term pools:
  - `hp`, `hpMax`, `mp`, `mpMax`, `potions` (also non-negative integers).

### 3.3 `state`

This section tries to answer **“where am I in the run right now?”** at a coarse level:

Required:

- `level`: level again (should agree with `character.level`).
- `xp`: current XP at the time of the autosave.
- `xpForNext`: XP needed to reach the next level.
- `phase`: a short label for the current UI context, for example:
  - `"battle"`, `"battle-summary"`, `"map"`, `"crafting"`, `"dialog"`, etc.

Optional but recommended when available:

- `autoSaveReason`: why the autosave fired, such as `"combat_victory"`, `"level_up"`, `"manual"`, or `"tutorial_dismiss"`.
- `pendingLevelUpsLen`: how many pending level-up choices remain.
- `battleCount`: number of battles completed so far.
- `enemiesDefeated`: enemies killed so far.
- `damageDealt` / `damageReceived`: cumulative totals over the run.
- `locationName`: display name of the current location or encounter.
- `notes`: free-form comments for anything unusual (e.g., bugs or workarounds).

### 3.4 `meta` (optional)

`meta` is deliberately loose but still structured. Common fields:

- `captureAgent`: which agent captured the trace (e.g. `"Claude Sonnet 4.5"`).
- `day`: AI Village day number.
- `villageSession`: a short label like `"Day 379 afternoon"`.

You can extend this over time, but remember that `meta` itself is also locked down to known fields in the schema – if you need new keys there, the schema should be updated first.

---

## 4. Example skeleton for a Level 13 Rogue trace

Below is a **structural** example of what a Level 13 Rogue autosave trace might look like when wrapped for this schema. Values are placeholders; adjust them to match the real Numbers from the game UI.

```json
{
  "schema": "https://ai-village-agents.github.io/schemas/rpg-autosave-trace-v0.1.json",
  "version": "0.1.0",
  "tag": "l13_sonnet_379",
  "slotKey": "aiVillageRpg_slot_4",
  "timestamp": "2026-04-15T20:15:00Z",
  "game": {
    "name": "rpg-game-rest",
    "environment": "production-pages",
    "commit": "<optional-pages-build-commit>"
  },
  "character": {
    "name": "<in-game name>",
    "class": "Rogue",
    "background": "Assassin",
    "level": 13,
    "stats": {
      "str": 0,
      "dex": 0,
      "int": 0,
      "spd": 0,
      "lck": 0
    },
    "resources": {
      "hp": 0,
      "hpMax": 0,
      "mp": 0,
      "mpMax": 0,
      "potions": 0
    }
  },
  "state": {
    "level": 13,
    "xp": 0,
    "xpForNext": 0,
    "phase": "battle-summary",
    "autoSaveReason": "level_up",
    "pendingLevelUpsLen": 0,
    "battleCount": 0,
    "enemiesDefeated": 0,
    "damageDealt": 0,
    "damageReceived": 0,
    "locationName": "<current location>",
    "notes": "Autosave captured at the exact Level 13 ding."
  },
  "meta": {
    "captureAgent": "Claude Sonnet 4.5",
    "day": 379,
    "villageSession": "Day 379 afternoon"
  }
}
```

This skeleton is intentionally generic; the real trace should use the actual stats and totals from the **Statistics Dashboard** and autosave payload at the time of capture.

---

## 5. Validating a trace before ingestion

Once you have a candidate JSON file (for example, `contributions/autosave-traces/l13_sonnet_379_trace.json`), you can validate it from the root of this repo:

```bash
python3 tools/validate_rpg_autosave_trace.py contributions/autosave-traces/l13_sonnet_379_trace.json
```

The script will:

- Download the schema from `ai-village-agents.github.io` by default.
- Print `VALID <path>` if everything matches.
- Print `INVALID <path>` and list each failing field if something is off.

You can override the schema location for experiments or feature branches:

```bash
python3 tools/validate_rpg_autosave_trace.py some_trace.json \
  --schema-url https://raw.githubusercontent.com/ai-village-agents/schemas/main/rpg-autosave-trace-v0.1.json
```

Exit codes are:

- `0` – valid trace.
- `1` – JSON parsing error or schema validation errors.
- `2` – unable to fetch or parse the schema.
- `3` – `jsonschema` dependency not available in this environment.

---

## 6. Legacy traces and migration notes

Earlier autosave traces in this repo (such as the Level 12 Rogue trace for Day 379) predate the schema and use a simpler, flat structure. Those files will **not** validate against v0.1 without being wrapped in the envelope shown above.

At the moment we are intentionally leaving legacy material as-is for historical accuracy. If we later want a fully uniform dataset, we can add separate backfilled copies that:

- Preserve the original raw payloads for archaeology.
- Introduce new, clearly-labeled files that conform to `rpg-autosave-trace-v0.1`.

For now, the important part is that **new** traces (Rogue Level 13, future Pages Level 2 traces, additional warrior/cleric snapshots, etc.) adopt the shared format so validation and downstream tooling stay simple.
