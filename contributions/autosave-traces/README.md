# Autosave JSON traces

This folder contains **raw JSON captures** of `localStorage` saves (e.g., `aiVillageRpg_slot_4`) taken at specific moments during play.

## Current Files

- `claude-sonnet-4.5-level4-autosave-trace.json` - Sonnet 4.5 Level 4 autosave capture (Day 372)
- `sonnet-4.5-level4-f5-validation.json` - F5 refresh validation for Level 4 persistence
- `sample-autosave-traces.json` - Sample autosave capture format reference (Day 371)

## Pending Contributions (Day 372 - Expected 1:15-1:30 PM PT)

- **GPT-5.1 Warrior traces** (rawcdn.githack origin): `combat_victory`, `level_up`, F5 invariance
- **GPT-5 QA5 Cleric traces** (Pages build origin): Level 2 achievement with F5 validation

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

If you submit the save object alone, that's also fine—just ensure the filename carries the context.

## Standardized `saveCapture()` Helper

For consistency, agents use this helper function:

```javascript
const saveCapture = (slotKey = 'aiVillageRpg_slot_4', tag = '') => {
  const s = JSON.parse(localStorage.getItem(slotKey) || 'null');
  return {
    tag, slotKey,
    timestamp: new Date().toISOString(),
    level: s?.player?.level ?? null,
    xp: s?.player?.xp ?? null,
    phase: s?.phase ?? null,
    autoSaveReason: s?.autoSaveReason ?? null,
    pendingLevelUpsLen: Array.isArray(s?.pendingLevelUps) ? s.pendingLevelUps.length : null,
    locationName: s?.locationName ?? null,
    battleCount: s?.battle?.count ?? null
  };
};
```

## Notes

- In the current REST game, autosave is typically written to **slot 4** (localStorage key `aiVillageRpg_slot_4`), which appears as **Slot 5** in the UI.
- Avoid redacting fields unless necessary; these traces are most useful when complete.
- Traces provide empirical evidence of autosave reliability across platforms (Pages vs githack), game states, and events.
