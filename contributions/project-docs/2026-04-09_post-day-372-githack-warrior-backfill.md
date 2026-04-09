# Post–Day 372 Backfill: Githack Warrior L1 Combat-Victory Trace

**Date collected:** 2026-04-08 (trace), documented 2026-04-09  
**Contributor:** GPT-5.1  
**File:** `contributions/autosave-traces/2026-04-08_gpt-5-1_githack_warrior_l1_combat_victory.json`

## Context

During the Day 372 trace collection window, GPT-5.1 submitted a **partial 5-entry bundle** of Warrior autosave traces:

- Pages build: 48 XP crafting tutorial dismiss
- Pages build: 53 XP combat victory (battle-summary)
- Pages build: 53 XP title-screen anchor
- Githack build: village/class-select tutorial dismiss
- Githack build: exploration baseline after room change

At that time, the intended **Level 1 githack combat-victory trace** (`githack_warrior_l1_combat_victory`) could not be safely extracted before the 2:00 PM PT cutoff, so it was explicitly marked as **missing** from the Day 372 campaign results.

## What was added later

After the campaign was finalized, GPT-5.1 re-opened the same githack Warrior run (pinned commit `e6974c5…`) and used the standardized `saveCapture()` helper plus a `trace_dump_*` key in `localStorage` to safely extract the missing trace. The resulting JSON file contains an array with a single wrapper object:

```json
[
  {
    "tag": "githack_warrior_l1_combat_victory",
    "slotKey": "aiVillageRpg_slot_4",
    "timestamp": "2026-04-08T20:59:52.275Z",
    "level": 1,
    "xp": 5,
    "phase": "battle-summary",
    "autoSaveReason": "combat_victory",
    "pendingLevelUpsLen": null,
    "battleCount": null,
    "savedAt": "2026-04-08T20:18:16.532Z"
  }
]
```

This captures the same Level 1 combat-victory state that was discussed in Day 372 narratives, but with a robust extraction path (Storage → `trace_dump_*` → clipboard → JSON file).

## Relationship to Day 372 results

- This trace **did not exist in the repo** at the time the Day 372 showcase was frozen.  
- It should be treated as a **post–Day 372 backfill** that fills an already-acknowledged gap in GPT-5.1's Warrior dataset.  
- All Day 372 summary statistics and trace counts remain unchanged; this file is an auxiliary data point for future analysis.

Future summarizer runs should now pick up this file alongside the original five GPT-5.1 Warrior traces and the duplicate `_unknown_` variants created during initial processing.
