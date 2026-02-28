#!/bin/bash
# Grant Accessibility permission for LangSwitcher debug builds
# Run with: sudo bash scripts/grant-accessibility.sh
#
# This is needed because Xcode debug builds use ad-hoc signing,
# and macOS TCC (Transparency, Consent, and Control) may not
# properly recognize the app after each rebuild.

set -e

BUNDLE_ID="com.langswitcher.app"
APP_PATH="/Users/user/Library/Developer/Xcode/DerivedData/LangSwitcher-bvflroofntkuwqdehotvgnowagfq/Build/Products/Debug/LangSwitcher.app"

echo "=== LangSwitcher Accessibility Permission Setup ==="
echo ""

# Step 1: Reset existing permissions for our bundle ID
echo "1. Resetting existing accessibility permissions for ${BUNDLE_ID}..."
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true

# Step 2: Try to insert directly into TCC database
TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"

if [ ! -f "$TCC_DB" ]; then
    echo "ERROR: TCC database not found at $TCC_DB"
    echo "This script must be run with sudo."
    exit 1
fi

echo "2. Inserting accessibility permission into TCC database..."

# auth_value=2 means "allowed", auth_reason=3 means "user set"
sqlite3 "$TCC_DB" "
INSERT OR REPLACE INTO access (
    service, client, client_type, auth_value, auth_reason, auth_version,
    indirect_object_identifier_type, indirect_object_identifier, flags, last_modified
) VALUES (
    'kTCCServiceAccessibility',
    '${BUNDLE_ID}',
    0,
    2,
    3,
    1,
    0,
    'UNUSED',
    0,
    CAST(strftime('%s','now') AS INTEGER)
);
"

echo "3. Verifying..."
RESULT=$(sqlite3 "$TCC_DB" "SELECT auth_value FROM access WHERE service='kTCCServiceAccessibility' AND client='${BUNDLE_ID}';")

if [ "$RESULT" = "2" ]; then
    echo ""
    echo "✅ SUCCESS: Accessibility permission granted for ${BUNDLE_ID}"
    echo ""
    echo "Now restart LangSwitcher (stop and re-run from Xcode)."
else
    echo ""
    echo "❌ FAILED: Could not verify permission was set."
    echo ""
    echo "Manual steps:"
    echo "  1. Open System Settings → Privacy & Security → Accessibility"
    echo "  2. Click '+' and navigate to:"
    echo "     ${APP_PATH}"
    echo "  3. Or drag-and-drop the .app file into the list"
    echo "  4. Restart LangSwitcher"
fi

echo ""
echo "=== Alternative: Add via System Settings ==="
echo "If the script didn't work, manually add this file:"
echo "  ${APP_PATH}"
echo "to System Settings → Privacy & Security → Accessibility"
