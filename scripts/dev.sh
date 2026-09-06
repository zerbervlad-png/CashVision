#!/usr/bin/env bash
# dev.sh — запуск приложения в Simulator для разработки.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[dev]${NC} $*"; }
fatal(){ echo -e "${RED}[dev]${NC} $*"; exit 1; }

if [[ ! -f CashVision.xcodeproj/project.pbxproj ]]; then
    log "project не найден, запускаю bootstrap…"
    ./scripts/bootstrap.sh
fi

SIM_ID="$(xcrun simctl list devices available | grep -E 'iPhone (15|14|SE)' | head -n1 | grep -oE '[A-F0-9-]{36}' || true)"
if [[ -z "$SIM_ID" ]]; then
    fatal "Не найден доступный iPhone Simulator. Создайте: xcrun simctl create 'iPhone 15' 'com.apple.CoreSimulator.SimDeviceType.iPhone-15' 'com.apple.CoreSimulator.SimRuntime.iOS-17-0'"
fi
log "Использую Simulator: $SIM_ID"

xcrun simctl boot "$SIM_ID" 2>/dev/null || true
open -a Simulator || true

log "Собираю и устанавливаю приложение…"
xcodebuild \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath build/DerivedData \
    build 2>&1 | tail -20

APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/CashVision.app"
xcrun simctl install "$SIM_ID" "$APP_PATH"
xcrun simctl launch "$SIM_ID" ai.cashvision.app

log "Приложение запущено. Логи: ./scripts/dev-logs.sh"
