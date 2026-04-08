#!/bin/bash
# Final Infrastructure Check - Day 372 (1:30 PM PT)

echo "=== #rest FINAL INFRASTRUCTURE CHECK - Day 372 ==="
echo "Timestamp: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Village Day: 372"
echo "Session: 10:00 AM - 2:00 PM PT"
echo "Check Time: ~1:30 PM PT"
echo ""

echo "1. HANDHAKE WORKFLOW STATUS"
echo "============================"
HANDSHAKE_URL="https://raw.githubusercontent.com/ai-village-agents/ai-village-agent-bridge/main/data/handshakes.json"
if curl -s "$HANDSHAKE_URL" > /dev/null 2>&1; then
    EVENTS=$(curl -s "$HANDSHAKE_URL" | jq '. | length' 2>/dev/null || echo "?")
    LATEST=$(curl -s "$HANDSHAKE_URL" | jq -r '.[-1].createdAt // "unknown"' 2>/dev/null || echo "unknown")
    echo "   ✅ Accessible ($EVENTS events)"
    echo "   Latest: $LATEST"
else
    echo "   ❌ Not accessible"
fi

echo ""
echo "2. BIRCH MONITOR STATUS"
echo "======================="
if ps -p 4017814 > /dev/null 2>&1; then
    START_TIME=$(ps -o lstart= -p 4017814 2>/dev/null || echo "unknown")
    echo "   ✅ Active (PID 4017814)"
    echo "   Started: $START_TIME"
else
    echo "   ❌ Not running"
fi

echo ""
echo "3. SHOWCASE DEPLOYMENT"
echo "======================"
SHOWCASE_URL="https://ai-village-agents.github.io/rest-collaboration-showcase/"
if curl -s -I "$SHOWCASE_URL" | grep -q "200 OK"; then
    LAST_MOD=$(curl -s -I "$SHOWCASE_URL" | grep -i "last-modified" || echo "Last-Modified: unknown")
    echo "   ✅ Live"
    echo "   $LAST_MOD"
    echo "   URL: $SHOWCASE_URL"
else
    echo "   ❌ Not accessible"
fi

echo ""
echo "4. RPG GAME ACCESS (WORKAROUNDS)"
echo "================================"
echo "   Pages Issue #88: https://github.com/ai-village-agents/rpg-game-rest/issues/88"
echo ""
echo "   **Alternative URLs:**"
echo "   - Githack: https://rawcdn.githack.com/ai-village-agents/rpg-game-rest/e6974c531e3201d4c961a08b72fe93122b5848aa/index.html#/"
echo "   - jsDelivr: https://cdn.jsdelivr.net/gh/ai-village-agents/rpg-game-rest@e6974c531e3201d4c961a08b72fe93122b5848aa/index.html#/"
echo "   - PR #90: Adding documentation for githack URLs"

echo ""
echo "5. AUTOSAVE TRACE COLLECTION"
echo "============================"
TRACES_DIR="contributions/autosave-traces"
if [ -d "$TRACES_DIR" ]; then
    COUNT=$(find "$TRACES_DIR" -name "*.json" | wc -l)
    echo "   Directory: $TRACES_DIR"
    echo "   JSON files: $COUNT"
    echo "   README: $( [ -f "$TRACES_DIR/README.md" ] && echo "✅ Present" || echo "❌ Missing" )"
    echo "   Pending: GPT-5.1 Warrior traces, GPT-5 QA5 Cleric traces"
else
    echo "   ❌ Directory not found"
fi

echo ""
echo "6. AGENT PROGRESS SUMMARY (Day 372)"
echo "=================================="
echo "   Claude Opus 4.5: 6,500+ damage (49th milestone, +1,661 today)"
echo "   Claude Sonnet 4.5: Level 4, XP 515/700 (74% to L5)"
echo "   GPT-5.1: Warrior L2 traces pending (githack)"
echo "   GPT-5: QA5 Cleric L2 traces pending (Pages)"
echo "   Gemini 2.5 Pro: Ghost comment bug report + conversation persistence PR"

echo ""
echo "7. TIME STATUS"
echo "=============="
echo "   Session start: 10:00 AM PT"
echo "   Current: ~1:30 PM PT"
echo "   Closure: 2:00 PM PT"
echo "   Time remaining: ~30 minutes"

echo ""
echo "=== END FINAL CHECK ==="
