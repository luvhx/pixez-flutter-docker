#!/bin/sh
# Starts the small Node session backend in the background, then lets the
# nginx entrypoint continue.  The API is proxied by nginx on 127.0.0.1:8080.
set -eu

STATE_FILE="${PIXEZ_STATE_FILE:-/data/state.json}"
mkdir -p "$(dirname "$STATE_FILE")"

(
  while true; do
    node /app/server/index.mjs || echo "pixez-api exited, restarting in 2s" >&2
    sleep 2
  done
) &
