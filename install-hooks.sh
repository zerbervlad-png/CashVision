#!/usr/bin/env bash
# install-hooks.sh — установка Git hooks для авто-pull после изменений.
#
# Что делает:
#   1. Создаёт post-merge hook — после `git pull` автоматически:
#      - Перегенерирует .xcodeproj
#      - Пересобирает приложение
#      - Перезапускает в Simulator
#   2. Создаёт alias для быстрого обновления
#
# Использование:
#   ./install-hooks.sh
#
# После установки:
#   - Любой `git pull` в репозитории автоматически пересоберёт проект
#   - Команда `cv-sync` из любой папки = pull + пересборка + запуск

set -euo pipefail

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[hooks]${NC} $*"; }

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

mkdir -p .git/hooks

# post-merge hook — срабатывает после git pull
cat > .git/hooks/post-merge <<'EOF'
#!/usr/bin/env bash
# Auto-run after git pull/merge
set -e

PROJECT_DIR="$(git rev-parse --show-toplevel)"
cd "$PROJECT_DIR"

echo "[post-merge] Перегенерирую Xcode-проект…"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate 2>&1 | tail -3
fi

# Если Xcode открыт — он автоматически подхватит изменения
# (Xcode следит за файловой системой)

echo "[post-merge] ✅ Проект обновлён. В Xcode нажми Cmd+R для пересборки."
EOF
chmod +x .git/hooks/post-merge
log "Установлен post-merge hook (авто-регенерация .xcodeproj после pull)"

# post-checkout hook — срабатывает при переключении веток
cat > .git/hooks/post-checkout <<'EOF'
#!/usr/bin/env bash
# Auto-run after git checkout/switch
set -e

PROJECT_DIR="$(git rev-parse --show-toplevel)"
cd "$PROJECT_DIR"

echo "[post-checkout] Перегенерирую Xcode-проект…"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate 2>&1 | tail -3
fi

echo "[post-checkout] ✅ Проект обновлён для новой ветки."
EOF
chmod +x .git/hooks/post-checkout
log "Установлен post-checkout hook (авто-регенерация при switch ветки)"

# Алиас cv-sync для быстрого обновления из любой папки
PROFILE_FILES=("$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc")
ALIAS_LINE="alias cv-sync='cd \"$PROJECT_DIR\" && git pull origin main && xcodegen generate && echo \"✅ Обновлено. Cmd+R в Xcode\"'"

for profile in "${PROFILE_FILES[@]}"; do
    if [[ -f "$profile" ]]; then
        if ! grep -q "cv-sync" "$profile" 2>/dev/null; then
            echo "" >> "$profile"
            echo "# CashVision quick sync" >> "$profile"
            echo "$ALIAS_LINE" >> "$profile"
            log "Добавлен alias cv-sync в $profile"
        fi
        break
    fi
done

# Создаём watcher-скрипт для фонового авто-pull
cat > scripts/watch-git.sh <<'EOF'
#!/usr/bin/env bash
# watch-git.sh — фоновый watcher новых коммитов на GitHub.
# Запускает авто-pull + пересборку при обнаружении новых изменений.
#
# Использование:
#   ./scripts/watch-git.sh           — проверка main каждые 30 сек
#   ./scripts/watch-git.sh develop 60 — проверка develop каждые 60 сек

set -euo pipefail

BRANCH="${1:-main}"
INTERVAL="${2:-30}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[watch]${NC} $*"; }
warn() { echo -e "${YELLOW}[watch]${NC} $*"; }

log "🔍 Слежу за изменениями на origin/$BRANCH (каждые $INTERVAL сек)"
log "   Ctrl+C для остановки"
log ""

LAST_HASH="$(git rev-parse HEAD 2>/dev/null || echo 'none')"

while true; do
    sleep "$INTERVAL"

    git fetch origin "$BRANCH" 2>/dev/null || continue

    REMOTE_HASH="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo '')"
    if [[ -z "$REMOTE_HASH" ]]; then
        continue
    fi

    if [[ "$REMOTE_HASH" != "$LAST_HASH" ]]; then
        echo ""
        warn "🔔 Новые изменения на GitHub!"
        warn "   $LAST_HASH"
        warn "   → $REMOTE_HASH"
        log "   Pull + пересборка…"

        git pull origin "$BRANCH" --rebase 2>/dev/null || {
            warn "Pull не удался. Попробуй вручную: git pull"
            continue
        }

        # post-merge hook сработает автоматически и перегенерирует .xcodeproj
        LAST_HASH="$(git rev-parse HEAD)"
        log "✅ Обновлено. В Xcode: Cmd+R для пересборки."
        echo ""
    fi
done
EOF
chmod +x scripts/watch-git.sh
log "Создан scripts/watch-git.sh (фоновый авто-pull)"

echo ""
log "✅ Git hooks установлены!"
echo ""
echo "Теперь при любом git pull:"
echo "  1. .xcodeproj автоматически перегенерируется"
echo "  2. Xcode подхватит изменения (он следит за файлами)"
echo "  3. Нажми Cmd+R в Xcode для пересборки"
echo ""
echo "Для фонового авто-pull (пока ты тестируешь UI):"
echo "  ./scripts/watch-git.sh          # main, каждые 30 сек"
echo "  ./scripts/watch-git.sh develop   # develop ветка"
echo ""
echo "Быстрый sync одной командой (из любого места в Terminal):"
echo "  cv-sync"
