#!/usr/bin/env bash
# release.sh — экспорт IPA и подготовка к релизу.
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[release]${NC} $*"; }

if [[ ! -d build/Archives/CashVision.xcarchive ]]; then
    echo "Сначала запустите ./scripts/archive.sh"
    exit 1
fi

mkdir -p build/IPA

EXPORT_PLIST="build/ExportOptions.plist"
cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
   <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF

log "Экспортирую IPA…"
xcodebuild -exportArchive \
    -archivePath "build/Archives/CashVision.xcarchive" \
    -exportPath build/IPA \
    -exportOptionsPlist "$EXPORT_PLIST" \
    2>&1 | tail -20

log "Готово. IPA: build/IPA/CashVision.ipa"
log "Загрузите через: xcrun altool --upload-app -f build/IPA/CashVision.ipa -t ios"
