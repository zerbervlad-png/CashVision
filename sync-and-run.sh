#!/usr/bin/env bash
# sync-and-run.sh — синхронизация с Git + запуск в Xcode/Simulator.
#
# Что делает:
#   1. Подтягивает последние изменения из GitHub (main)
#   2. Перегенерирует .xcodeproj через XcodeGen
#   3. Открывает проект в Xcode (для ручного тестирования UI)
#   4. Параллельно собирает и запускает в Simulator
#
# Использование:
#   ./sync-and-run.sh              — pull из main + открытие Xcode + запуск
#   ./sync-and-run.sh develop      — pull из develop + открытие Xcode + запуск
#   ./sync-and-run.sh --no-xcode   — только Simulator, без Xcode
#   ./sync-and-run.sh --watch      — авто-pull каждые 30 секунд + перезапуск
#
# Workflow:
#   1. Запускаешь: ./sync-and-run.sh
#   2. Xcode открывается с проектом
#   3. Simulator запускается с приложением
#   4. Ты тестируешь интерфейс в Simulator или в Xcode
#   5. Если я (AI) вношу изменения — они подхватываются автоматически
#   6. Cmd+R в Xcode = пересборка с последним кодом

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[sync]${NC} $*"; }
info()  { echo -e "${BLUE}[sync]${NC} $*"; }
warn()  { echo -e "${YELLOW}[sync]${NC} $*"; }
fatal() { echo -e "${RED}[sync]${NC} $*"; exit 1; }

if [[ "$(uname)" != "Darwin" ]]; then
    fatal "Скрипт работает только на macOS."
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

BRANCH="main"
OPEN_XCODE=true
WATCH_MODE=false

for arg in "$@"; do
    case "$arg" in
        --no-xcode)  OPEN_XCODE=false ;;
        --watch)     WATCH_MODE=true ;;
        develop|feature/*|main) BRANCH="$arg" ;;
    esac
done

# Проверка зависимостей
command -v git >/dev/null 2>&1 || fatal "git не установлен: brew install git"
command -v xcodegen >/dev/null 2>&1 || fatal "xcodegen не установлен: brew install xcodegen"
command -v xcodebuild >/dev/null 2>&1 || fatal "Xcode не установлен. Установи из App Store."

sync_pull() {
    log "Pull из origin/$BRANCH…"
    git fetch origin "$BRANCH" 2>/dev/null

    # Сохраняем локальные изменения если есть
    if ! git diff --quiet || ! git diff --cached --quiet; then
        warn "Есть локальные изменения. Сохраняю в stash…"
        git stash push -m "auto-stash $(date +%H:%M:%S)" 2>/dev/null || true
    fi

    git checkout "$BRANCH" 2>/dev/null || true
    git pull origin "$BRANCH" --rebase 2>/dev/null || {
        warn "Pull --rebase не удался, пробую обычный pull…"
        git pull origin "$BRANCH" 2>/dev/null || warn "Не удалось pull. Работаю с локальной версией."
    }

    # Возвращаем stash если был
    git stash pop 2>/dev/null || true

    log "Текущий коммит: $(git log --oneline -1)"
}

regenerate_project() {
    log "Перегенерирую CashVision.xcodeproj…"
    xcodegen generate 2>&1 | tail -3
    [[ -f "CashVision.xcodeproj/project.pbxproj" ]] || fatal ".xcodeproj не сгенерирован"
}

find_simulator() {
    local sim_id
    sim_id="$(xcrun simctl list devices available | grep -E 'iPhone (15|14|SE)' | head -n1 | grep -oE '[A-F0-9-]{36}' || true)"
    if [[ -z "$sim_id" ]]; then
        warn "Simulator не найден. Создаю iPhone 15…"
        local runtime
        runtime="$(xcrun simctl list runtimes available | grep 'iOS' | tail -n1 | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+')"
        if [[ -z "$runtime" ]]; then
            fatal "iOS Runtime не установлен. Xcode → Settings → Platforms → установи iOS Simulator runtime."
        fi
        sim_id="$(xcrun simctl create 'iPhone 15' 'com.apple.CoreSimulator.SimDeviceType.iPhone-15' "$runtime")"
    fi
    echo "$sim_id"
}

build_and_run() {
    local sim_id="$1"
    log "Запускаю Simulator…"
    xcrun simctl boot "$sim_id" 2>/dev/null || true
    open -a Simulator 2>/dev/null || true

    log "Собираю CashVision (Debug)…"
    mkdir -p build/DerivedData

    xcodebuild build \
        -project CashVision.xcodeproj \
        -scheme CashVision \
        -configuration Debug \
        -destination "id=$sim_id" \
        -derivedDataPath build/DerivedData \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -15

    local app_path="build/DerivedData/Build/Products/Debug-iphonesimulator/CashVision.app"
    if [[ ! -d "$app_path" ]]; then
        fatal "Сборка не удалась. Открой CashVision.xcodeproj в Xcode и проверь ошибки."
    fi

    log "Устанавливаю приложение в Simulator…"
    xcrun simctl install "$sim_id" "$app_path"

    log "Запускаю CashVision…"
    xcrun simctl launch "$sim_id" ai.cashvision.app
}

open_xcode() {
    log "Открываю проект в Xcode…"
    open CashVision.xcodeproj
    info "В Xcode нажми Cmd+R для пересборки и запуска"
    info "Cmd+U — запустить тесты"
    info "Cmd+B — только сборка"
    info "Cmd+Shift+K — очистить (Clean Build Folder)"
}

# ─── Основной flow ────────────────────────────────────────────────────────────

run_once() {
    echo ""
    echo "============================================"
    echo "  CashVision — синхронизация и запуск"
    echo "============================================"
    echo ""

    sync_pull
    regenerate_project

    SIM_ID="$(find_simulator)"
    log "Simulator: $SIM_ID"

    build_and_run "$SIM_ID"

    if $OPEN_XCODE; then
        open_xcode
    fi

    echo ""
    log "✅ Готово!"
    echo ""
    info "Simulator запущен с приложением CashVision"
    if $OPEN_XCODE; then
        info "Xcode открыт — можешь тестировать UI и редактировать код"
        info "Cmd+R в Xcode = пересборка с актуальным кодом"
    fi
    echo ""
    info "Логи приложения:"
    info "  xcrun simctl spawn $SIM_ID log stream --predicate 'subsystem CONTAINS \"ai.cashvision\"'"
    echo ""
}

run_once

# ─── Watch mode: авто-pull каждые 30 секунд ──────────────────────────────────
if $WATCH_MODE; then
    echo ""
    info "🔍 Watch mode: авто-pull каждые 30 секунд"
    info "   Если я (AI) делаю push — изменения подхватятся автоматически"
    info "   Ctrl+C для выхода"
    echo ""

    LAST_COMMIT="$(git rev-parse HEAD)"

    while true; do
        sleep 30
        git fetch origin "$BRANCH" 2>/dev/null || continue

        REMOTE_COMMIT="$(git rev-parse origin/$BRANCH 2>/dev/null || echo "")"
        if [[ -n "$REMOTE_COMMIT" && "$REMOTE_COMMIT" != "$LAST_COMMIT" ]]; then
            echo ""
            log "🔔 Обнаружены новые изменения на GitHub!"
            log "   $LAST_COMMIT → $REMOTE_COMMIT"
            log "   Синхронизирую…"

            run_once
            LAST_COMMIT="$(git rev-parse HEAD)"
            warn "✅ Обновлено. Пересобери в Xcode: Cmd+R"
        fi
    done
fi
