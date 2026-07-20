#!/usr/bin/env bash
# Build a YuMusic .prg with a server configuration baked into
# resources/settings/properties.xml — WITHOUT ever committing credentials.
#
# The server config is read from a git-ignored profile file (default:
# test-config.sh, copy it from server-config.example.sh). properties.xml is
# backed up before the build and ALWAYS restored afterwards (even on error), so
# the working tree stays clean and no token is ever left in a committed file.
#
# Usage:
#   tools/build-configured.sh [DEVICE] [OUT_PRG]
#   CONFIG=prod-config.sh tools/build-configured.sh fr165m /tmp/x.prg
#
# Why bake at all: a sideloaded app is not recognised by Garmin Connect, so its
# settings cannot be entered there. Baked properties.xml defaults are applied on
# the watch on first install. In the simulator, defaults only load when the
# property does not already exist — run "File > Reset App Data" once if a stale
# value shadows them.
set -euo pipefail

cd "$(dirname "$0")/.."   # -> yumusic/

CONFIG="${CONFIG:-test-config.sh}"
if [ ! -f "$CONFIG" ]; then
  echo "error: $CONFIG not found. Copy server-config.example.sh to $CONFIG and fill it in." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG"

DEVICE="${1:-fr165m}"
OUT="${2:-/tmp/yumusic.prg}"
PROPS="resources/settings/properties.xml"
KEY="$(pwd)/developer_key"
SDK="${SDK:-$(ls -d "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/"*/ 2>/dev/null | sort | tail -1)}"
MONKEYC="$SDK/bin/monkeyc"

# Optionally fetch a fresh demo.jellyfin.org access token (it resets hourly).
if [ "${YUMUSIC_JELLYFIN_DEMO:-0}" = "1" ]; then
  echo "Fetching a fresh demo.jellyfin.org token..."
  YUMUSIC_API_KEY="$(curl -s -m 20 -X POST "${YUMUSIC_SERVER_URL}/Users/AuthenticateByName" \
    -H 'Content-Type: application/json' \
    -H 'X-Emby-Authorization: MediaBrowser Client="yumusic", Device="dev", DeviceId="dev", Version="1.0"' \
    -d '{"Username":"demo","Pw":""}' \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["AccessToken"])')"
  echo "  token: ${YUMUSIC_API_KEY:0:8}..."
fi

# Back up and guarantee restoration of the pristine properties.xml.
cp "$PROPS" "$PROPS.bak"
trap 'mv -f "$PROPS.bak" "$PROPS"' EXIT

# Inject the config values into the property defaults (values passed via env so
# URLs/keys with special characters are never string-interpolated into code).
YUMUSIC_SERVER_URL="${YUMUSIC_SERVER_URL:-}" \
YUMUSIC_USERNAME="${YUMUSIC_USERNAME:-}" \
YUMUSIC_PASSWORD="${YUMUSIC_PASSWORD:-}" \
YUMUSIC_SERVER_TYPE="${YUMUSIC_SERVER_TYPE:-0}" \
YUMUSIC_API_KEY="${YUMUSIC_API_KEY:-}" \
python3 - "$PROPS" <<'PY'
import os, re, sys
path = sys.argv[1]
vals = {
    "serverUrl":  os.environ.get("YUMUSIC_SERVER_URL", ""),
    "username":   os.environ.get("YUMUSIC_USERNAME", ""),
    "password":   os.environ.get("YUMUSIC_PASSWORD", ""),
    "serverType": os.environ.get("YUMUSIC_SERVER_TYPE", "0"),
    "apiKey":     os.environ.get("YUMUSIC_API_KEY", ""),
}
s = open(path).read()
for key, val in vals.items():
    # Replace the text between the opening/closing tags of this property id.
    s = re.sub(r'(<property id="%s"[^>]*>)[^<]*(</property>)' % re.escape(key),
               lambda m, v=val: m.group(1) + v + m.group(2), s)
open(path, "w").write(s)
PY

echo "Building $DEVICE -> $OUT  (serverType=${YUMUSIC_SERVER_TYPE:-0}, url=${YUMUSIC_SERVER_URL:-none})"
"$MONKEYC" -f monkey.jungle -d "$DEVICE" -o "$OUT" -y "$KEY"
echo "Built $OUT — properties.xml restored to its committed state."
