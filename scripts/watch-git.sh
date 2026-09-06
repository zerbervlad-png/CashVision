#!/usr/bin/env bash
# watch-git.sh — фоновый watcher новых коммитов на GitHub.
# При обнаружении изменений: pull + перегенерация .xcodeproj + пересборка.
#
# Использование:
#   ./scripts/watch-git.sh           — main, каждые 15 сек
#   ./scripts/watch-git.sh develop   — develop ветка
#   ./scripts/watch-git.sh main 30    — main, каждые 30 сек

set -e

BRANCH="${1:-main}"
INTERVAL="${2:-15}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[watch]${NC} $*"; }
warn() { echo -e "${YELLOW}[watch]${NC} $*"; }
info() { echo -e "${BLUE}[watch]${NC} $*"; }

echo ""
info "🔍 CashVision auto-sync watcher"
info "   Ветка: $BRANCH"
info "   Интервал: ${INTERVAL}сек"
info "   Ctrl+C для остановки"
info "   При новых коммитах — авто-pull + перегенерация проекта"
echo ""

LAST_HASH="$(git rev-parse HEAD 2>/dev/null || echo 'none')"

while true; do
    sleep "$INTERVAL"

    # Тихий fetch
    git fetch origin "$BRANCH" 2>/dev/null || continue

    REMOTE_HASH="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo '')"
    if [ -z "$REMOTE_HASH" ]; then
        continue
    fi

    if [ "$REMOTE_HASH" != "$LAST_HASH" ]; then
        echo ""
        warn "🔔 Новые изменения на GitHub!"
        warn "   Локально:  $LAST_HASH"
        warn "   На GitHub: $REMOTE_HASH"
        log "   Pull + перегенерация проекта…"

        # Pull с rebase
        git pull origin "$BRANCH" --rebase 2>/dev/null || {
            warn "Pull --rebase не удался, пробую обычный…"
            git pull origin "$BRANCH" 2>/dev/null || {
                warn "❌ Pull не удался. Возможен конфликт. Реши вручную:"
                warn "   git pull origin $BRANCH"
                continue
            }
        }

        # Перегенерация .xcodeproj
        if command -v xcodegen >/dev/null 2>&1; then
            log "   Перегенерирую CashVision.xcodeproj…"
            xcodegen generate 2>&1 | tail -2
        fi

        LAST_HASH="$(git rev-parse HEAD)"

        # Получаем последний commit message
        COMMIT_MSG="$(git log -1 --pretty=format:'%s' 2>/dev/null || echo '')"
        log "✅ Обновлено: $COMMIT_MSG"
        log "   В Xcode нажми Cmd+R для пересборки"
        echo ""
    fi
done
