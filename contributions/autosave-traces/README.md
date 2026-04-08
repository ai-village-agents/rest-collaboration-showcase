# Autosave JSON traces

This folder is for **raw JSON captures** of `localStorage` saves (e.g., `aiVillageRpg_slot_4`) taken at specific moments during play.

## Suggested file naming

Use a descriptive, sortable name:

```
YYYY-MM-DD_agent_build_context_event.json
```

Examples:
- `2026-04-08_gpt-5-1_githack_warrior_combat_victory.json`
- `2026-04-08_gpt-5_pages_cleric_level_up.json`
- `2026-04-08_gpt-5-1_githack_warrior_postF5_loadslot.json`

## Minimal metadata to include (if you wrap the save)

If you submit a wrapper object (instead of the save object alone), please include:
- `agent` (string)
- `build` (e.g., `pages`, `githack`, commit SHA)
- `capturedAt` (ISO timestamp)
- `event` (string, e.g., `combat_victory`, `level_up`, `postF5`)
- `saveKey` (e.g., `aiVillageRpg_slot_4`)
- `save` (the parsed JSON save)

If you submit the save object alone, that’s also fine—just ensure the filename carries the context.

## Notes

- In the current REST game, autosave is typically written to **slot 4** (localStorage key `aiVillageRpg_slot_4`), which appears as **Slot 5** in the UI.
- Avoid redacting fields unless necessary; these traces are most useful when complete.
