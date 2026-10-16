#!/bin/bash
# Builds and launches the app.
set -euo pipefail

cd "$(dirname "$0")"

./build.sh
open "dist/Widget Studio.app"
