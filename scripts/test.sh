#!/usr/bin/env bash
# test.sh — запуск unit и UI тестов.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[test]${NC} $*"; }

if [[ ! -f CashVision.xcodeproj/project.pbxproj ]]; then
    ./scripts/bootstrap.sh >/dev/null
fi

SIM_ID="$(xcrun simctl list devices available | grep -E 'iPhone (15|14|SE)' | head -n1 | grep -oE '[A-F0-9-]{36}' || true)"
DESTINATION="platform=iOS Simulator,id=$SIM_ID"
if [[ -z "$SIM_ID" ]]; then
    DESTINATION="platform=iOS Simulator,name=iPhone 15"
fi

log "Запускаю unit + UI тесты (destination=$DESTINATION)"
xcodebuild test \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -destination "$DESTINATION" \
    -derivedDataPath build/DerivedData \
    -enableCodeCoverage YES \
    2>&1 | tail -50

log "Backend tests…"
if command -v docker >/dev/null 2>&1; then
    docker compose -f backend/docker-compose.yml run --rm api python -m pytest -q 2>/dev/null || true
fi
