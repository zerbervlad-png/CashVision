#!/usr/bin/env bash
# setup-mac.sh — автоустановка зависимостей CashVision на Mac.
# Запускать ОДИН раз после установки Xcode из App Store.

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()   { echo -e "${GREEN}[setup]${NC} $*"; }
info()  { echo -e "${BLUE}[setup]${NC} $*"; }
warn()  { echo -e "${YELLOW}[setup]${NC} $*"; }
fatal() { echo -e "${RED}[setup]${NC} $*"; exit 1; }

echo ""
echo "================================================"
echo "  CashVision — автоустановка на Mac"
echo "================================================"
echo ""

# Проверка macOS
if [ "$(uname)" != "Darwin" ]; then
    fatal "Этот скрипт работает только на macOS."
fi
log "macOS $(sw_vers -productVersion)"

# 1. Проверка Xcode
log "Проверяю Xcode…"
if [ -d "/Applications/Xcode.app" ]; then
    log "Xcode найден"
else
    echo ""
    warn "Xcode не найден!"
    echo "  1. Открой App Store на Mac"
    echo "  2. Найди «Xcode» (бесплатно, ~10 ГБ)"
    echo "  3. Установи и запусти один раз"
    echo "  4. Повтори этот скрипт"
    exit 1
fi

log "Активирую Xcode…"
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null || true

log "Принимаю лицензию Xcode…"
sudo xcodebuild -license accept 2>/dev/null || true

# 2. Command Line Tools
log "Проверяю Command Line Tools…"
if ! xcode-select -p >/dev/null 2>&1; then
    xcode-select --install 2>/dev/null || true
    echo "Нажми Enter когда установка CLT завершится:"
    read _
fi
log "CLT: $(xcode-select -p)"

# 3. Homebrew
log "Проверяю Homebrew…"
if ! command -v brew >/dev/null 2>&1; then
    log "Устанавливаю Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi
if command -v brew >/dev/null 2>&1; then
    log "Homebrew: $(brew --version | head -n1)"
else
    fatal "Homebrew не установлен. Установи с https://brew.sh"
fi

# 4. Установка пакетов
log "Устанавливаю пакеты через Homebrew…"

for pkg in xcodegen git curl python@3.12; do
    if brew list "$pkg" >/dev/null 2>&1; then
        log "  ✓ $pkg установлен"
    else
        log "  ↓ Устанавливаю $pkg…"
        brew install "$pkg" || warn "Не удалось установить $pkg"
    fi
done

# Docker (опционально)
for pkg in docker colima docker-compose; do
    if brew list "$pkg" >/dev/null 2>&1; then
        log "  ✓ $pkg установлен"
    else
        log "  ↓ Устанавливаю $pkg…"
        brew install "$pkg" || warn "Не удалось установить $pkg"
    fi
done

# 5. Swift
log "Проверяю Swift…"
if ! swift --version >/dev/null 2>&1; then
    warn "Swift недоступен. Открой Xcode один раз."
else
    log "Swift: $(swift --version 2>&1 | head -n1)"
fi

# 6. Определение папки проекта
PROJECT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"

if [ -f "$SCRIPT_DIR/project.yml" ] && [ -d "$SCRIPT_DIR/CashVision" ]; then
    PROJECT_DIR="$SCRIPT_DIR"
    log "Проект найден: $PROJECT_DIR"
else
    PROJECT_DIR="$HOME/Documents/CashVision"
    if [ -d "$PROJECT_DIR" ]; then
        log "Проект найден: $PROJECT_DIR"
    else
        PROJECT_DIR="$HOME/Desktop/CashVision"
        if [ -d "$PROJECT_DIR" ]; then
            log "Проект найден: $PROJECT_DIR"
        else
            log "Клонирую репозиторий в $PROJECT_DIR…"
            git clone https://github.com/zerbervlad-png/CashVision.git "$PROJECT_DIR"
        fi
    fi
fi

cd "$PROJECT_DIR" || fatal "Не могу перейти в $PROJECT_DIR"
log "Рабочая папка: $(pwd)"

# 7. Установка Git hooks
if [ -f "install-hooks.sh" ]; then
    log "Устанавливаю Git hooks…"
    chmod +x install-hooks.sh 2>/dev/null || true
    bash install-hooks.sh 2>/dev/null || true
fi

# 8. Генерация Xcode-проекта
log "Генерирую CashVision.xcodeproj…"
if ! command -v xcodegen >/dev/null 2>&1; then
    fatal "XcodeGen не установлен. Установи: brew install xcodegen"
fi
xcodegen generate
if [ ! -f "CashVision.xcodeproj/project.pbxproj" ]; then
    fatal "Не удалось сгенерировать CashVision.xcodeproj"
fi
log "Проект сгенерирован!"

# 9. Simulator
log "Проверяю iPhone Simulator…"
SIM_ID="$(xcrun simctl list devices available 2>/dev/null | grep -E 'iPhone (15|14|SE|16)' | head -n1 | grep -oE '[A-F0-9-]{36}' || true)"

if [ -z "$SIM_ID" ]; then
    warn "iPhone Simulator не найден. Создаю…"
    RUNTIME="$(xcrun simctl list runtimes available 2>/dev/null | grep 'iOS' | tail -n1 | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+' || true)"
    if [ -z "$RUNTIME" ]; then
        warn "iOS Runtime не установлен!"
        echo "  Xcode → Settings → Platforms → установи iOS Simulator runtime"
        echo "  Затем запусти: ./scripts/dev.sh"
    else
        SIM_ID="$(xcrun simctl create 'iPhone 15' 'com.apple.CoreSimulator.SimDeviceType.iPhone-15' "$RUNTIME")"
        log "Создан Simulator: $SIM_ID"
    fi
else
    log "Simulator найден: $SIM_ID"
fi

# 10. Запуск Simulator
if [ -n "$SIM_ID" ]; then
    log "Запускаю Simulator…"
    xcrun simctl boot "$SIM_ID" 2>/dev/null || true
    open -a Simulator 2>/dev/null || true

    # 11. Сборка
    log "Собираю CashVision (Debug)…"
    mkdir -p build/DerivedData

    xcodebuild build \
        -project CashVision.xcodeproj \
        -scheme CashVision \
        -configuration Debug \
        -destination "id=$SIM_ID" \
        -derivedDataPath build/DerivedData \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -20

    APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/CashVision.app"

    if [ -d "$APP_PATH" ]; then
        log "Устанавливаю приложение…"
        xcrun simctl install "$SIM_ID" "$APP_PATH"
        log "Запускаю CashVision…"
        xcrun simctl launch "$SIM_ID" ai.cashvision.app
    else
        warn "Сборка не удалась. Открой проект в Xcode и проверь ошибки."
    fi
fi

# 12. Открытие Xcode
log "Открываю проект в Xcode…"
open CashVision.xcodeproj

echo ""
echo "================================================"
echo "  ✅ Готово!"
echo "================================================"
echo ""
echo "  Xcode открыт с проектом CashVision"
echo "  Simulator запущен с приложением"
echo ""
echo "  В Xcode нажми Cmd+R для пересборки и запуска"
echo "  Cmd+U — запустить тесты"
echo ""
echo "  Обновление кода (когда AI делает push):"
echo "    git pull origin main"
echo "    Cmd+R в Xcode"
echo ""
