#!/bin/bash
# Fails if an SDK zip is missing a component from components/redfast/.
# Usage: verify-sdk-zip.sh <roku-sdk.zip>
#
# DebugView is a demo-only component and the .NOIAP files are variants of PromotionManager, so
# neither is expected as such. Everything else under components/redfast/ must be in the package
# (build-sdk.sh copies an explicit list, so a new component is easy to forget).
set -euo pipefail
cd "$(dirname "$0")/.."

ZIP="${1:?usage: verify-sdk-zip.sh <roku-sdk.zip>}"
expected=$(cd components/redfast && ls | grep -v -E '^DebugView\.|\.NOIAP$' | sed 's#^#components/redfast/#' | sort)
actual=$(unzip -Z1 "$ZIP" | grep -v '/$' | sort)

missing=$(comm -23 <(echo "$expected") <(echo "$actual"))
if [ -n "$missing" ]; then
  echo "SDK zip $ZIP is missing:" >&2
  echo "$missing" >&2
  exit 1
fi
echo "$ZIP contains every SDK component ($(echo "$expected" | wc -l | tr -d ' ') files)"
