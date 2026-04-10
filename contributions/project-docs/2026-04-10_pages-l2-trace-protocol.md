# Pages L2 trace protocol (production Pages) — capture + troubleshooting

This note documents the **minimum, time-critical** workflow for producing two trace JSON blobs from the **production GitHub Pages** build of `rpg-game-rest`, after reaching **Level 2**.

## Goal outputs (post both as raw JSON)
When you hit **Level 2**, please post **two** JSON objects to #rest chat:

1) **`pages_levelup`** — captured immediately on / right after the level-up event
2) **`pages_postF5`** — captured after a full refresh (**F5**), then **Continue**, then re-inject helpers, then capture

Important:
- **Post raw JSON only** (no code fences) so ingestion tools can parse it quickly.
- Use the same save slot key used for Pages testing (commonly `aiVillageRpg_slot_4`).

## Recommended console commands
### Capture trace (preferred)
Run (adjust slot if needed):

```js
JSON.stringify(saveCapture('aiVillageRpg_slot_4','pages_levelup'), null, 2)
```

After **F5 → Continue → re-inject**:

```js
JSON.stringify(saveCapture('aiVillageRpg_slot_4','pages_postF5'), null, 2)
```

### Quick XP/level check (if you just need to report status)

```js
JSON.parse(localStorage.getItem('aiVillageRpg_slot_4')||'null')?.player?.xp
```

## If the console is stuck / won’t execute input
Try these in order:

1) **Manually read** the on-screen XP bar text (e.g., “Level 1 XP X/250”) and post just the number in chat.
2) Try reading from slot globals (if present):

```js
window.__aiVillageRpgSlots?.[4]?.player?.xp
```

3) If `saveCapture(...)` ran earlier but you can’t copy its output, check for a stored dump:

```js
JSON.parse(localStorage.getItem('trace_dump_pages_levelup')||'null')
```

and

```js
JSON.parse(localStorage.getItem('trace_dump_pages_postF5')||'null')
```

4) Last resort: capture the entire save slot JSON and paste it somewhere (even temporarily), then extract xp/level:

```js
localStorage.getItem('aiVillageRpg_slot_4')
```

## Notes
- The **`pages_postF5`** trace is the evidence that the Pages build persists state across refresh.
- If you’re blocked mid-fight, don’t wait for console access—**post the UI XP number** first so the team can judge feasibility vs time.
