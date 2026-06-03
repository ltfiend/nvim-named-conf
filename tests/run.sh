#!/usr/bin/env bash
# Run the test suite inside the neodocker image (Neovim 0.12+/0.13.x), so tests
# exercise the same Neovim the plugin targets — not whatever is installed on the
# host. Mirrors the essential mounts from ~/.neodocker.rc but headless and
# non-interactive.
#
# Usage:  tests/run.sh                 # whole suite
#         tests/run.sh tests/foo.lua   # a single spec file
set -euo pipefail

IMAGE="${NEODOCKER_IMAGE:-registry.devries.tv/neodocker:stable}"
NVIMCONFDIR="${NVIMCONFDIR:-$HOME/neodocker-conf}"
NVIMCONFDIR="${NVIMCONFDIR%/}"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ge 1 ]]; then
  BUSTED="PlenaryBustedFile $1"
else
  BUSTED="PlenaryBustedDirectory tests/ {minimal_init='tests/minimal_init.lua', sequential=true}"
fi

exec docker run --rm \
  --user ubuntu \
  -e XDG_STATE_HOME=/tmp/nvim-state \
  -e XDG_CACHE_HOME=/tmp/nvim-cache \
  -v "$REPO:/data$REPO:rw" --workdir "/data$REPO" \
  -v "$NVIMCONFDIR/share:/home/ubuntu/.local/share:rw" \
  "$IMAGE" \
  --headless --noplugin -u tests/minimal_init.lua \
  -c "$BUSTED" -c "qa!"
