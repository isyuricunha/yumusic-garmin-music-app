#!/usr/bin/env bash
# build-production.sh
# Called by semantic-release @semantic-release/exec during the prepare step.
# Injects the Production UUID into manifest.xml, compiles the .iq, then restores
# the Beta UUID so the commit history stays clean.
#
# Usage: bash scripts/build-production.sh <version>

set -euo pipefail

VERSION="${1:-0.0.0}"
BETA_UUID="cddb60e3-11dc-44b4-845c-13ebc3915f32"
PUBLIC_UUID="716a6ef1-f242-4857-ab2d-d6c5c281d994"
MANIFEST="manifest.xml"
OUTPUT="bin/YuMusic-Production.iq"

echo "=== YuMusic Production Build ==="
echo "Version: ${VERSION}"

# 1. Inject Production UUID
echo "Swapping UUID to Production..."
sed -i "s/${BETA_UUID}/${PUBLIC_UUID}/g" "${MANIFEST}"

# 2. Inject version into manifest (iq:application version attribute)
echo "Injecting version ${VERSION}..."
sed -i "s/version=\"[0-9]*\.[0-9]*\.[0-9]*\"/version=\"${VERSION}\"/g" "${MANIFEST}"

# 3. Compile
mkdir -p bin
echo "Compiling .iq export..."
monkeyc -e \
  -y "${DEVELOPER_KEY_PATH}" \
  -o "${OUTPUT}" \
  -f monkey.jungle \
  -w

echo "Build complete: ${OUTPUT}"

# 4. Restore Beta UUID (keep working tree clean for any subsequent git operations)
echo "Restoring UUID to Beta..."
sed -i "s/${PUBLIC_UUID}/${BETA_UUID}/g" "${MANIFEST}"

echo "=== Done ==="
