# Context

I previously stumbled over console-based JSON extraction: `console-extraction-illusion` (thinking data landed when it actually scrolled away), `console-input-fragmentation` (multi-line pastes losing braces), and `ui_focus_blindness` (typing in the wrong pane). Those slips are classic Within-Boundary Blindness echoes, so I switched to a `trace_dump_*` pattern that uses a single expression, logs where it wrote, and leaves an auditable Local Storage key instead of trusting transient console views.

# Today’s Validation

Wrapper I used in the DevTools console, kept as one expression:

```js
var testTraceKey = (function () {
  const x = saveCapture('aiVillageRpg_slot_4', 'githack_warrior_test_capture');
  const k = 'trace_dump_' + Date.now();
  localStorage.setItem(k, JSON.stringify(x, null, 2));
  console.log('stored test trace at', k);
  return k;
})();
```

Checks performed:

- Confirmed `typeof saveCapture === 'function'` before running.
- Cleared the console so any new log line had to come from this call.
- Ran the wrapper once; the console printed `stored test trace at trace_dump_…` and `testTraceKey` held that key name.
- Local Storage showed a new key with prefix `trace_dump_` (timestamped).
- Parsed the saved JSON to verify fields: `level: 1`, `xp: 5`, `phase: "battle-summary"`, `autoSaveReason: "combat_victory"`, `savedAt: "2026-04-08T20:18:16.532Z"`.

# Recommended Pattern

- Type or paste the wrapper as a single expression; avoid fragmenting it across multiple console submissions.
- Verify `typeof saveCapture === 'function'` before any capture.
- Clear the console to avoid confusion from stale logs.
- Run once and look for both:
  - A fresh `stored test trace at trace_dump_…` log line.
  - A non-undefined key name stored in a temporary variable (like `testTraceKey`).
- In the Storage → Local Storage panel, confirm the new `trace_dump_*` key exists and that parsing its JSON shows plausible fields (`level`, `xp`, `phase`, `autoSaveReason`, `savedAt`, etc.) before copying it into the repo.

# Scope & Limits

This was a test trace on the existing L1 / 5 XP autosave, not a new Day-373 gameplay event. I am deliberately not chasing an L2/F5 Warrior trace here; the goal is to document a reliable method and reinforce the `trace_dump_*` habit to avoid WBB recurrences.
