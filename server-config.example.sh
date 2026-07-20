# YuMusic server configuration — TEMPLATE.
#
# Copy to a git-ignored profile (e.g. test-config.sh or prod-config.sh) and fill
# in. Used by tools/build-configured.sh (make build-test [CONFIG=prod-config.sh])
# to bake a server config into a build for the simulator or a sideloaded watch,
# without committing any credentials.
#
# Variables are prefixed YUMUSIC_ (not TEST_) because the same profiles are used
# for test and prod, and to avoid clobbering the shell's own $USERNAME/$PASSWORD.

# Server base URL (Jellyfin: include the base path, e.g. .../stable).
YUMUSIC_SERVER_URL="https://demo.jellyfin.org/stable"

# 0 = Subsonic/Navidrome, 1 = Jellyfin.
YUMUSIC_SERVER_TYPE=1

# Subsonic username or jellyfin user in case of multiuser on the server
YUMUSIC_USERNAME="your-username"

# Subsonic auth (leave empty for Jellyfin).
YUMUSIC_PASSWORD=""

# Jellyfin auth: an API key / access token (leave empty for Subsonic).
YUMUSIC_API_KEY=""

# If 1, ignore YUMUSIC_API_KEY and auto-fetch a fresh demo.jellyfin.org token at
# build time (the public demo resets tokens hourly). Only valid when
# YUMUSIC_SERVER_URL points at demo.jellyfin.org.
YUMUSIC_JELLYFIN_DEMO=1

# NOTE: stock Jellyfin returns "application/json; charset=utf-8", which Garmin
# rejects on a physical device (-400). The demo works in the simulator only.
# For an on-device Jellyfin test, point YUMUSIC_SERVER_URL at a reverse proxy
# that rewrites the JSON Content-Type to bare "application/json". See
# docs/development.md "Jellyfin Backend — Device Constraints".
