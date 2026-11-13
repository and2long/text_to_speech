#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
MODE="${1:-run}"
APP_NAME="text_to_speech"
APP_BUNDLE="$ROOT_DIR/build/macos/Build/Products/Debug/$APP_NAME.app"
case "$MODE" in
  run|--verify|--debug|--logs|--telemetry) ;;
  *) echo "usage: $0 [--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;;
esac
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
flutter pub get
dart run tool/bundle_kokoro.dart
flutter build macos --debug
case "$MODE" in
  run) /usr/bin/open -n "$APP_BUNDLE" ;;
  --verify)
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --debug) lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME" ;;
  --logs|--telemetry)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
esac
