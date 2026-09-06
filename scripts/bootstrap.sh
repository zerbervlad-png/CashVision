#!/usr/bin/env bash
# bootstrap.sh — первичная настройка проекта на Mac.
# Проверяет Xcode, Swift, зависимости; устанавливает XcodeGen при необходимости.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[bootstrap]${NC} $*"; }
warn()  { echo -e "${YELLOW}[bootstrap]${NC} $*"; }
fatal(){ echo -e "${RED}[bootstrap]${NC} $*"; exit 1; }

log "CashVision bootstrap — $PROJECT_DIR"

if [[ "$(uname)" != "Darwin" ]]; then
    fatal "Скрипт запускается только на macOS. На Windows используйте скрипты для разработки исходного кода."
fi

if ! command -v xcode-select >/dev/null 2>&1; then
    fatal "Xcode Command Line Tools не установлены. Установите Xcode из App Store и выполните: xcode-select --install"
fi

XCODE_PATH="$(xcode-select -p)"
log "Xcode path: $XCODE_PATH"

if ! xcodebuild -version >/dev/null 2>&1; then
    fatal "xcodebuild недоступен. Откройте Xcode и примите лицензию: sudo xcodebuild -license"
fi

XCODE_VERSION="$(xcodebuild -version | head -n1 | awk '{print $2}')"
log "Xcode version: $XCODE_VERSION"

SWIFT_VERSION="$(swift --version 2>&1 | head -n1)"
log "Swift: $SWIFT_VERSION"

if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew не установлен. Установите: https://brew.sh"
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    log "Устанавливаю XcodeGen через Homebrew…"
    brew install xcodegen
fi

log "Генерирую CashVision.xcodeproj…"
xcodegen generate

if [[ ! -f CashVision.xcodeproj/project.pbxproj ]]; then
    fatal "Не удалось сгенерировать .xcodeproj"
fi

log "Проверяю сборку Debug для Simulator…"
xcodebuild \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -configuration Debug \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath build/DerivedData \
    build 2>&1 | tail -40

log "Bootstrap завершён. Теперь выполните: ./scripts/dev.sh"
