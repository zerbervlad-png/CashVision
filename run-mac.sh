#!/usr/bin/env bash
# run-mac.sh — единая точка входа для запуска CashVision на Mac.
# Проверяет окружение, собирает и запускает приложение в Simulator.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[run-mac]${NC} $*"; }
warn()  { echo -e "${YELLOW}[run-mac]${NC} $*"; }
fatal() { echo -e "${RED}[run-mac]${NC} $*"; exit 1; }

ERRORS=()

if [[ "$(uname)" != "Darwin" ]]; then
    fatal "Скрипт run-mac.sh работает только на macOS. На Windows редактируйте исходники, на Mac запускайте этот скрипт."
fi

log "1/9 Проверка macOS…"
MACOS_VER="$(sw_vers -productVersion)"
log "   macOS $MACOS_VER"

log "2/9 Проверка Xcode…"
if ! xcode-select -p >/dev/null 2>&1; then
    ERRORS+=("Xcode не установлен. Установите из App Store и запустите: xcode-select --install")
fi
XCODE_VER="$(xcodebuild -version 2>/dev/null | head -n1 || echo 'не найден')"
log "   $XCODE_VER"

log "3/9 Проверка наличия проекта…"
if [[ ! -f project.yml ]]; then
    ERRORS+=("project.yml не найден в корне репозитория")
fi
if [[ ! -d CashVision ]]; then
    ERRORS+=("Папка CashVision не найдена")
fi

log "4/9 Проверка Swift…"
if ! swift --version >/dev/null 2>&1; then
    ERRORS+=("Swift не найден в PATH")
fi
SWIFT_VER="$(swift --version 2>&1 | head -n1)"
log "   $SWIFT_VER"

log "5/9 Проверка зависимостей (brew, xcodegen)…"
if ! command -v brew >/dev/null 2>&1; then
    ERRORS+=("Homebrew не установлен. Установите: https://brew.sh")
fi
if ! command -v xcodegen >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        log "   Устанавливаю xcodegen…"
        brew install xcodegen
    else
        ERRORS+=("xcodegen не установлен, Homebrew отсутствует — невозможно установить автоматически")
    fi
fi

log "6/9 Проверка Simulator…"
if ! xcrun simctl list >/dev/null 2>&1; then
    ERRORS+=("simctl недоступен. Откройте Xcode → Settings → Components и установите iOS Simulator runtime")
fi

if (( ${#ERRORS[@]} > 0 )); then
    echo
    fatal "Найдены ошибки окружения:"
    for e in "${ERRORS[@]}"; do echo "   • $e"; done
    echo
    echo "Исправьте проблемы и повторите ./run-mac.sh"
    exit 1
fi

log "7/9 Генерация проекта…"
if [[ ! -f CashVision.xcodeproj/project.pbxproj ]]; then
    xcodegen generate
fi

log "8/9 Сборка приложения…"
SIM_ID="$(xcrun simctl list devices available | grep -E 'iPhone (15|14|SE)' | head -n1 | grep -oE '[A-F0-9-]{36}' || true)"
if [[ -z "$SIM_ID" ]]; then
    warn "iPhone Simulator не найден. Создаю новый…"
    SIM_ID="$(xcrun simctl create 'iPhone 15' 'com.apple.CoreSimulator.SimDeviceType.iPhone-15' 'com.apple.CoreSimulator.SimRuntime.iOS-17-0')"
fi
log "   Simulator: $SIM_ID"

xcodebuild \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath build/DerivedData \
    build 2>&1 | tail -25

log "9/9 Запуск приложения…"
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
open -a Simulator || true

APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/CashVision.app"
xcrun simctl install "$SIM_ID" "$APP_PATH"
xcrun simctl launch "$SIM_ID" ai.cashvision.app

log "Готово! CashVision запущен в Simulator."
log "Логи: xcrun simctl spawn $SIM_ID log stream --predicate 'subsystem CONTAINS \"ai.cashvision\"'"
