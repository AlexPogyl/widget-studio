#!/bin/bash
# Builds, registers and launches the app (so the system widget appears in the
# "Изменить виджеты…" gallery as well).
set -euo pipefail

cd "$(dirname "$0")"

./build.sh --register
open "dist/Widget Studio.app"
