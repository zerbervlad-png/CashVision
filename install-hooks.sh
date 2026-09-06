#!/usr/bin/env bash
# install-hooks.sh — установка Git hooks для авто-pull после изменений.
#
# После установки:
#   - `git pull` автоматически перегенерирует .xcodeproj
#   - Xcode подхватит изменения (он следит за файловой системой)
#   - Cmd+R в Xcode = пересборка с актуальным кодом

set -e

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[hooks]${NC} $*"; }

PROJECT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
cd "$PROJECT_DIR"

mkdir -p .git/hooks

# post-merge hook — после git pull
cat > .git/hooks/post-merge <<'HOOK'
#!/usr/bin/env bash
set -e
PROJECT_DIR="$(git rev-parse --show-toplevel)"
cd "$PROJECT_DIR"

echo "[post-merge] Перегенерирую Xcode-проект…"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate 2>&1 | tail -2
fi
echo "[post-merge] ✅ Проект обновлён. В Xcode: Cmd+R для пересборки."
HOOK
chmod +x .git/hooks/post-merge
log "✅ post-merge hook установлен (авто-регенерация после pull)"

# post-checkout hook — при переключении веток
cat > .git/hooks/post-checkout <<'HOOK'
#!/usr/bin/env bash
set -e
PROJECT_DIR="$(git rev-parse --show-toplevel)"
cd "$PROJECT_DIR"

echo "[post-checkout] Перегенерирую Xcode-проект…"
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate 2>&1 | tail -2
fi
echo "[post-checkout] ✅ Проект обновлён для новой ветки."
HOOK
chmod +x .git/hooks/post-checkout
log "✅ post-checkout hook установлен (авто-регенерация при switch)"

# Алиас cv-sync
ALIAS_LINE="alias cv-sync='cd \"$PROJECT_DIR\" && git pull origin main && xcodegen generate && echo \"✅ Обновлено. Cmd+R в Xcode\"'"

for profile in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    if [ -f "$profile" ]; then
        if ! grep -q "cv-sync" "$profile" 2>/dev/null; then
            echo "" >> "$profile"
            echo "# CashVision quick sync" >> "$profile"
            echo "$ALIAS_LINE" >> "$profile"
            log "✅ Алиас cv-sync добавлен в $profile"
        fi
        break
    fi
done

echo ""
log "✅ Git hooks установлены!"
echo ""
echo "Теперь при git pull:"
echo "  1. .xcodeproj автоматически перегенерируется"
echo "  2. Xcode подхватит изменения"
echo "  3. Нажми Cmd+R в Xcode для пересборки"
echo ""
echo "Для фонового авто-pull (пока тестируешь UI):"
echo "  ./scripts/watch-git.sh          # main, каждые 15 сек"
echo "  ./scripts/watch-git.sh develop   # develop ветка"
echo ""
echo "Быстрый sync одной командой (из любого места):"
echo "  cv-sync"
