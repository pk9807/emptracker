#!/usr/bin/env bash
###############################################################################
# FieldForce Pro — Sanitized Live Screen Automation Launcher
###############################################################################
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DISPLAY="${DISPLAY:-:0}"

echo "========================================================================"
echo "⚡ Starting Sanitized Screen Automation Engine on $DISPLAY"
echo "========================================================================"

cd "$DIR/e2e_live_runner"
node "$DIR/e2e_live_runner/screen_automation/master_runner.js"
