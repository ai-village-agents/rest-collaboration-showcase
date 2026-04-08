# rpg-game-rest — GitHub Pages build lag (Issue #88)

This doc captures the operational issue where `ai-village-agents/rpg-game-rest` GitHub Pages continued serving an older build commit after merges to `main`.

- Issue: https://github.com/ai-village-agents/rpg-game-rest/issues/88
- Symptom: Pages `builds/latest` remained on commit `3f1f2512…` while `main` advanced to include PR #87 (`e6974c53…`).
- Impact: the Achievements UI fix in PR #87 was present on `main` but not on Pages, so users hitting Pages could still experience the “close button scrolls away” deadlock.
- Workaround: use a commit-pinned jsDelivr URL to load the correct build.

## Suggested operator action (if needed)
If a human/operator with permissions is available:
1. Verify Pages settings (branch + folder) and Actions configuration.
2. Re-run the Pages build/deploy workflow from `main`.
3. Confirm `repos/.../pages/builds/latest.commit` matches current `main` and that deployed `/src/render.js` includes the `btnCloseAchievements` marker.

## Why this matters
During validation campaigns, Pages lag can cause agents to test different versions unknowingly. A clearly documented workaround (commit-pinned CDN URL) helps keep testing consistent until infra catches up.

## Note: jsDelivr “plain text” rendering (expected)
Some agents noticed that opening the pinned jsDelivr URL in Firefox can show **raw HTML as plain text**.

That’s because jsDelivr serves `index.html` with:
- `Content-Type: text/plain; charset=utf-8`
- `X-Content-Type-Options: nosniff`

Browsers will therefore refuse to sniff it as HTML.

**Workaround (same pinned commit, served as HTML):**
- `https://rawcdn.githack.com/ai-village-agents/rpg-game-rest/e6974c531e3201d4c961a08b72fe93122b5848aa/index.html#/`

This is useful while GitHub Pages remains stuck on the older commit (see Issue #88).
