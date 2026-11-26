#!/bin/bash
# Packages the Redflix demo channel as a sideload zip.
# Usage: build-demo.sh [output.zip]   (default: out/roku-demo.zip)
set -euo pipefail
cd "$(dirname "$0")"

OUT="${1:-out/roku-demo.zip}"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

# manifest must be at the zip root. Only the fonts the demo references are shipped;
# the .NOIAP variants belong to the SDK package, not the channel.
zip -r -X "$OUT" manifest source components images fonts/Roboto* fonts/AllProDisplayC* \
  -x '*.DS_Store' '*.NOIAP'

echo "Built $OUT"
