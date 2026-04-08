#!/bin/bash
# Infrastructure Status Checker for #rest Collaboration Showcase
# Run this periodically to update infrastructure status

echo "=== #rest Infrastructure Status Check ==="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo ""

# 1. Handshake Workflow
echo "1. Handshake Workflow:"
HANDSHAKE_JSON=$(curl -s https://raw.githubusercontent.com/ai-village-agents/ai-village-agent-bridge/main/data/handshakes.json 2>/dev/null)
if [ $? -eq 0 ]; then
    HANDSHAKE_COUNT=$(echo "$HANDSHAKE_JSON" | jq '.events | length' 2>/dev/null || echo "ERROR")
    echo "   Events: $HANDSHAKE_COUNT"
    LATEST_EVENT=$(echo "$HANDSHAKE_JSON" | jq '.events[-1] | "\(.ts_utc) by \(.author)"' 2>/dev/null || echo "ERROR")
    echo "   Latest: $LATEST_EVENT"
else
    echo "   ❌ Could not fetch handshake data"
fi

# 2. BIRCH Monitor
echo ""
echo "2. BIRCH Monitor:"
if ps -p 4017814 >/dev/null 2>&1; then
    START_TIME=$(stat -c %Y /proc/4017814 2>/dev/null || echo 0)
    if [ $START_TIME -gt 0 ]; then
        CURRENT_TIME=$(date +%s)
        UPTIME_SEC=$((CURRENT_TIME - START_TIME))
        UPTIME_DAYS=$((UPTIME_SEC / 86400))
        UPTIME_HOURS=$(( (UPTIME_SEC % 86400) / 3600 ))
        UPTIME_MIN=$(( (UPTIME_SEC % 3600) / 60 ))
        echo "   ✅ Active (PID 4017814)"
        echo "   Uptime: ${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MIN}m"
    else
        echo "   ⚠️ Process running but can't get uptime"
    fi
else
    echo "   ❌ Not running"
fi

# 3. GitHub Pages (rpg-game-rest)
echo ""
echo "3. GitHub Pages (rpg-game-rest):"
# Check jsDelivr workaround for PR #87
PR87_CHECK=$(curl -s https://cdn.jsdelivr.net/gh/ai-village-agents/rpg-game-rest@e6974c531e3201d4c961a08b72fe93122b5848aa/src/render.js 2>/dev/null | grep -c "btnCloseAchievements" || echo "0")
if [ "$PR87_CHECK" -gt 0 ]; then
    echo "   ✅ jsDelivr workaround active (PR #87 deployed)"
else
    echo "   ❌ jsDelivr workaround broken"
fi

# Check actual Pages deployment
PAGES_RESPONSE=$(curl -s -I https://ai-village-agents.github.io/rpg-game-rest/ 2>/dev/null | head -1)
if echo "$PAGES_RESPONSE" | grep -q "200"; then
    echo "   ⚠️ Pages live but may be on old commit (Issue #88)"
elif echo "$PAGES_RESPONSE" | grep -q "404\|500"; then
    echo "   ❌ Pages not accessible: $(echo "$PAGES_RESPONSE" | grep -o "[0-9][0-9][0-9]")"
else
    echo "   ⚠️ Pages status unknown"
fi

# 4. Showcase Deployment
echo ""
echo "4. Showcase Deployment:"
SHOWCASE_RESPONSE=$(curl -s -I https://ai-village-agents.github.io/rest-collaboration-showcase/ 2>/dev/null | head -1)
if echo "$SHOWCASE_RESPONSE" | grep -q "200"; then
    LAST_MODIFIED=$(curl -s -I https://ai-village-agents.github.io/rest-collaboration-showcase/ 2>/dev/null | grep -i "last-modified" | cut -d' ' -f2- | tr -d '\r' || echo "UNKNOWN")
    echo "   ✅ Live (Last-Modified: $LAST_MODIFIED)"
else
    echo "   ❌ Not accessible: $(echo "$SHOWCASE_RESPONSE" | grep -o "[0-9][0-9][0-9]")"
fi

# 5. Organization Metadata
echo ""
echo "5. Organization Metadata:"
ORG_META_DATA=$(curl -s https://api.github.com/repos/ai-village-agents/organization-metadata/commits/main 2>/dev/null)
if [ $? -eq 0 ]; then
    ORG_META_COMMIT=$(echo "$ORG_META_DATA" | jq -r '.sha' 2>/dev/null | cut -c1-8 || echo "ERROR")
    ORG_META_DATE=$(echo "$ORG_META_DATA" | jq -r '.commit.committer.date' 2>/dev/null || echo "ERROR")
    echo "   Latest commit: $ORG_META_COMMIT"
    echo "   Updated: $ORG_META_DATE"
else
    echo "   ❌ Could not fetch metadata"
fi

echo ""
echo "=== End Status Check ==="
