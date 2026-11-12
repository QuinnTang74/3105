#!/bin/bash
set -euo pipefail

# Copy a built unsigned IPA into the operator's iCloud Drive folder so it can
# be opened directly from the Files app on the phone.
IPA="${1:?usage: scripts/export_ipa.sh <path-to-ipa>}"
DEST="$HOME/Library/Mobile Documents/com~apple~CloudDocs/项目开发/3106"

[[ -f "$IPA" ]] || { echo "IPA not found: $IPA" >&2; exit 1; }
mkdir -p "$DEST"
cp -f "$IPA" "$DEST/"
echo "Copied: $DEST/$(basename "$IPA")"
shasum -a 256 "$DEST/$(basename "$IPA")"
