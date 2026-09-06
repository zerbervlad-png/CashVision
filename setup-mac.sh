#!/usr/bin/env bash
# setup-mac.sh — автоустановка всех зависимостей CashVision на Mac.
# Запускать ОДИН раз после установки Xcode из App Store.
#
# Что делает:
#   1. Проверяет Xcode (должен быть установлен из App Store)
#   2. Устанавливает Command Line Tools
#   3. Устанавливает Homebrew
#   4. Через brew ставит: xcodegen, docker, git
#   5. Принимает лицензию Xcode
#   6. Создаёт iPhone Simulator если нет
#   7. Клонирует репозиторий (если запущен вне проекта)
#   8. Генерирует .xcodeproj
#   9. Собирает и запускает приложение
#
# Использование:
#   chmod +x setup-mac.sh
#   ./setup-mac.sh
#
# Или одной командой через curl:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/zerbervlad-png/CashVision/main/setup-mac.sh)"

set -euo pipefail

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
echo "  CashVision — автоустановка зависимостей на Mac"
echo "================================================"
echo ""

# ─── Проверка macOS ───────────────────────────────────────────────────────────
if [[ "$(uname)" != "Darwin" ]]; then
    fatal "Этот скрипт работает только на macOS."
fi
MACOS_VER="$(sw_vers -productVersion)"
log "macOS $MACOS_VER"

# ─── 1. Проверка Xcode ────────────────────────────────────────────────────────
log "Проверяю Xcode…"

if [[ -d "/Applications/Xcode.app" ]]; then
    XCODE_VER="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' /Applications/Xcode.app/Contents/Info.plist 2>/dev/null || echo '?')"
    log "Xcode $XCODE_VER найден в /Applications/Xcode.app"
else
    echo ""
    warn "Xcode не найден в /Applications/Xcode.app"
    echo ""
    echo "  1. Открой App Store на Mac"
    echo "  2. Найди «Xcode» (бесплатно, ~10 ГБ)"
    echo "  3. Установи и запусти один раз (примет лицензию)"
    echo "  4. После завершения запусти этот скрипт снова:"
    echo ""
    echo "     ./setup-mac.sh"
    echo ""
    read -p "Нажми Enter когда Xcode будет установлен, или Q для выхода: " ans
    [[ "$ans" =~ ^[Qq]$ ]] && exit 1
    if [[ ! -d "/Applications/Xcode.app" ]]; then
        fatal "Xcode всё ещё не найден. Установи его из App Store и повтори."
    fi
fi

# Активируем Xcode
log "Активирую Xcode…"
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null || {
    warn "Не удалось автоматически выбрать Xcode. Выполни вручную:"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
}

# Принимаем лицензию Xcode
log "Принимаю лицензию Xcode…"
sudo xcodebuild -license accept 2>/dev/null || warn "Не удалось принять лицензию автоматически. Выполни: sudo xcodebuild -license accept"

# ─── 2. Command Line Tools ────────────────────────────────────────────────────
log "Проверяю Command Line Tools…"
if ! xcode-select -p >/dev/null 2>&1; then
    log "Устанавливаю Command Line Tools (всплывёт окно — нажми «Установить»)…"
    xcode-select --install 2>/dev/null || true
    read -p "Нажми Enter когда установка CLT завершится: " _
fi
log "CLT: $(xcode-select -p)"

# ─── 3. Homebrew ──────────────────────────────────────────────────────────────
log "Проверяю Homebrew…"
if ! command -v brew >/dev/null 2>&1; then
    log "Устанавливаю Homebrew (может занять пару минут)…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        warn "Не удалось установить Homebrew. Установи вручную с https://brew.sh"
    }
    # Добавляем в PATH для Apple Silicon и Intel
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi
if command -v brew >/dev/null 2>&1; then
    log "Homebrew: $(brew --version | head -n1)"
else
    fatal "Homebrew не установлен. Установи с https://brew.sh и запусти скрипт снова."
fi

# ─── 4. Установка пакетов через brew ──────────────────────────────────────────
log "Устанавливаю пакеты через Homebrew…"

brew_install() {
    local pkg="$1"
    if brew list "$pkg" >/dev/null 2>&1; then
        log "  ✓ $pkg уже установлен"
    else
        log "  ↓ Устанавливаю $pkg…"
        brew install "$pkg" || warn "Не удалось установить $pkg"
    fi
}

brew_install xcodegen
brew_install git
brew_install curl
brew_install python@3.12
brew_install docker
brew_install docker-compose
brew_install colima  # лёгкий Docker runtime для macOS

# ─── 5. Swift проверка ────────────────────────────────────────────────────────
log "Проверяю Swift…"
if ! swift --version >/dev/null 2>&1; then
    fatal "Swift недоступен. Открой Xcode один раз, чтобы он доустановил компоненты."
fi
SWIFT_VER="$(swift --version 2>&1 | head -n1)"
log "Swift: $SWIFT_VER"

# ─── 6. Docker ───────────────────────────────────────────────────────────────
log "Проверяю Docker…"
if ! command -v docker >/dev/null 2>&1; then
    warn "Docker не установлен. Установи Docker Desktop с https://docker.com"
else
    if ! docker info >/dev/null 2>&1; then
        log "Запускаю Colima (Docker runtime)…"
        colima start 2>/dev/null || warn "Не удалось запустить Colima. Запусти Docker Desktop вручную."
    fi
    if docker info >/dev/null 2>&1; then
        log "Docker: $(docker --version)"
    else
        warn "Docker установлен, но не запущен. Запусти Docker Desktop или colima start."
    fi
fi

# ─── 7. Клонирование репозитория (если запущен вне проекта) ───────────────────
PROJECT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/project.yml" ]] && [[ -d "$SCRIPT_DIR/CashVision" ]]; then
    PROJECT_DIR="$SCRIPT_DIR"
    log "Скрипт запущен из корня проекта: $PROJECT_DIR"
else
    log "Скрипт запущен вне проекта. Клонирую репозиторий…"
    PROJECT_DIR="$HOME/Desktop/CashVision"
    if [[ -d "$PROJECT_DIR" ]]; then
        warn "Папка $PROJECT_DIR уже существует."
        read -p "Обновить существующую копию? (y/N): " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            cd "$PROJECT_DIR"
            git pull origin main 2>/dev/null || warn "Не удалось обновить. Использую существующую копию."
        fi
    else
        git clone https://github.com/zerbervlad-png/CashVision.git "$PROJECT_DIR"
    fi
fi

cd "$PROJECT_DIR"
log "Рабочая директория: $PROJECT_DIR"

# ─── 8. Генерация Xcode-проекта ───────────────────────────────────────────────
log "Генерирую CashVision.xcodeproj через XcodeGen…"
if ! command -v xcodegen >/dev/null 2>&1; then
    fatal "XcodeGen не установлен. Установи: brew install xcodegen"
fi

xcodegen generate 2>&1 | tail -5

if [[ ! -f "CashVision.xcodeproj/project.pbxproj" ]]; then
    fatal "Не удалось сгенерировать CashVision.xcodeproj"
fi
log "Проект сгенерирован: CashVision.xcodeproj"

# ─── 9. Создание Simulator если нет ───────────────────────────────────────────
log "Проверяю iPhone Simulator…"
SIM_ID="$(xcrun simctl list devices available | grep -E 'iPhone (15|14|SE)' | head -n1 | grep -oE '[A-F0-9-]{36}' || true)"

if [[ -z "$SIM_ID" ]]; then
    warn "iPhone Simulator не найден. Создаю новый…"
    # Получаем доступные runtime
    RUNTIME="$(xcrun simctl list runtimes available | grep 'iOS' | tail -n1 | grep -oE 'com.apple.CoreSimulator.SimRuntime.iOS-[0-9-]+')"
    if [[ -z "$RUNTIME" ]]; then
        warn "iOS Runtime не установлен. Открой Xcode → Settings → Platforms и установи iOS Simulator runtime."
        warn "Пропускаю сборку. После установки runtime запусти: ./scripts/dev.sh"
        exit 0
    fi
    SIM_ID="$(xcrun simctl create 'iPhone 15' 'com.apple.CoreSimulator.SimDeviceType.iPhone-15' "$RUNTIME")"
    log "Создан Simulator: $SIM_ID"
else
    log "Найден Simulator: $SIM_ID"
fi

# Загружаем Simulator
xcrun simctl boot "$SIM_ID" 2>/dev/null || true
open -a Simulator 2>/dev/null || true
log "Simulator запущен"

# ─── 10. Сборка приложения ────────────────────────────────────────────────────
log "Собираю CashVision (Debug)…"
mkdir -p build/DerivedData

xcodebuild build \
    -project CashVision.xcodeproj \
    -scheme CashVision \
    -configuration Debug \
    -destination "id=$SIM_ID" \
    -derivedDataPath build/DerivedData \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tail -25

APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/CashVision.app"

if [[ ! -d "$APP_PATH" ]]; then
    echo ""
    fatal "Сборка не удалась. Открой проект в Xcode и проверь ошибки:"
    echo "  open CashVision.xcodeproj"
    exit 1
fi

# ─── 11. Установка и запуск ───────────────────────────────────────────────────
log "Устанавливаю приложение в Simulator…"
xcrun simctl install "$SIM_ID" "$APP_PATH"

log "Запускаю CashVision…"
xcrun simctl launch "$SIM_ID" ai.cashvision.app

# ─── 12. Backend (опционально) ───────────────────────────────────────────────
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo ""
    info "Хочешь запустить backend тоже? (нужен Docker)"
    read -p "Запустить backend через docker compose? (y/N): " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        log "Запускаю backend…"
        cd backend
        cp -n .env.example .env 2>/dev/null || true
        docker compose up -d --build 2>&1 | tail -10
        cd ..
        log "Backend: http://localhost:8000/health"
        log "API docs: http://localhost:8000/api/v1/docs"
    fi
fi

# ─── Готово ──────────────────────────────────────────────────────────────────
echo ""
echo "================================================"
echo "  ✅ CashVision установлен и запущен!"
echo "================================================"
echo ""
echo "  Приложение запущено в Simulator"
echo "  Логи: xcrun simctl spawn $SIM_ID log stream --predicate 'subsystem CONTAINS \"ai.cashvision\"'"
echo ""
echo "  Полезные команды:"
echo "    ./scripts/dev.sh      — пересобрать и запустить"
echo "    ./scripts/test.sh     — запустить тесты"
echo "    ./scripts/build.sh     — только сборка"
echo "    ./scripts/clean.sh     — очистить артефакты"
echo "    open CashVision.xcodeproj — открыть в Xcode"
echo ""
echo "  Backend (если запущен): http://localhost:8000"
echo "  Документация: ./MAC_SETUP.md"
echo ""
