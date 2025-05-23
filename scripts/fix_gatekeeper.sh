#!/bin/bash

# Fix Gatekeeper "damaged app" warning for Glimpsify
# This script removes the quarantine attribute that causes the warning

echo "🔧 Fixing Gatekeeper warning for Glimpsify..."

# Find Glimpsify.app in common locations
APP_PATHS=(
    "/Applications/Glimpsify.app"
    "~/Applications/Glimpsify.app"
    "~/Downloads/Glimpsify.app"
    "./Glimpsify.app"
    "./build/Release/Glimpsify.app"
)

FOUND_APP=""

for path in "${APP_PATHS[@]}"; do
    expanded_path=$(eval echo "$path")
    if [ -d "$expanded_path" ]; then
        FOUND_APP="$expanded_path"
        break
    fi
done

if [ -z "$FOUND_APP" ]; then
    echo "❌ Glimpsify.app not found in common locations."
    echo "Please specify the path to Glimpsify.app:"
    echo "Usage: $0 /path/to/Glimpsify.app"
    exit 1
fi

echo "📍 Found Glimpsify.app at: $FOUND_APP"

# Remove quarantine attribute
echo "🧹 Removing quarantine attribute..."
xattr -dr com.apple.quarantine "$FOUND_APP"

# Remove any other problematic attributes
echo "🧹 Removing other security attributes..."
xattr -cr "$FOUND_APP"

# Verify the fix
echo "✅ Checking current attributes..."
xattr -l "$FOUND_APP"

echo ""
echo "🎉 Fixed! You should now be able to open Glimpsify without the 'damaged' warning."
echo ""
echo "If you still get warnings, you can also run:"
echo "sudo spctl --master-disable"
echo "(This disables Gatekeeper entirely - not recommended for security)"
echo ""
echo "Or allow this specific app:"
echo "sudo spctl --add \"$FOUND_APP\"" 