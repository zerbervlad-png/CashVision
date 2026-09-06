#!/usr/bin/env bash
# archive.sh — сборка архива приложения для TestFlight/App Store.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[archive]${NC} $*"; }

if [[ ! -f CashVision.xcodeproj/project.pbxproj ]]; then
    ./scripts/bootstrap.sh >/dev/null
fi

mkdir -p build/Archives

log "Архивирую CashVision (нужен реальный подписант)"
xcodebuild archive \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -configuration Release \
    -archivePath "build/Archives/CashVision.xcarchive" \
    -destination "generic/platform=iOS" \
    2>&1 | tail -30
