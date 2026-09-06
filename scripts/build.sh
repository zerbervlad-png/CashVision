#!/usr/bin/env bash
# build.sh — сборка приложения.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

CONFIG="${1:-Debug}"
GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[build]${NC} $*"; }

if [[ ! -f CashVision.xcodeproj/project.pbxproj ]]; then
    ./scripts/bootstrap.sh >/dev/null
fi

log "Build configuration=$CONFIG"
xcodebuild \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -configuration "$CONFIG" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath build/DerivedData \
    build 2>&1 | tail -30
