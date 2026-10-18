#!/usr/bin/env bash
# Build the PixEz web bundle locally (without Docker).
#
# Requirements: Flutter (stable, Dart >= 3.11.5).
set -euo pipefail

cd "$(dirname "$0")/.."

flutter config --no-analytics >/dev/null 2>&1 || true
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run sqflite_common_ffi_web:setup

flutter build web \
  --release \
  --no-web-resources-cdn \
  --no-wasm-dry-run \
  --no-tree-shake-icons

echo
echo "Build output: $(pwd)/build/web"
echo "Serve it behind a proxy, see deploy/nginx.conf, or run: docker compose up -d"
