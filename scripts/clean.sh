#!/usr/bin/env bash
# clean.sh — очистка build-артефактов.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "[clean] Удаляю build/, DerivedData, .xcodeproj (кроме project.yml)…"
rm -rf build/
rm -rf CashVision.xcodeproj
rm -rf .build
rm -rf backend/__pycache__ backend/api/__pycache__ backend/tests/__pycache__
echo "[clean] Готово."
