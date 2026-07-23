#!/usr/bin/env bash
#  make-dmg.sh - 把一个已构建、已签名的 MouseTools.app 打包成拖拽安装的 DMG。
#  用法: ./scripts/make-dmg.sh <MouseTools.app 路径> [输出.dmg]
#  仅依赖系统自带 hdiutil,无需 Xcode。
set -euo pipefail

APP_PATH="${1:-}"
OUT_DMG="${2:-}"

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
  echo "用法: $0 <MouseTools.app 路径> [输出.dmg]"
  echo "示例: $0 build/Build/Products/Release/MouseTools.app"
  exit 1
fi

APP_NAME="$(basename "$APP_PATH")"        # MouseTools.app
STEM="${APP_NAME%.app}"                    # MouseTools

# 读取版本号(用于默认 DMG 文件名)
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "1.0")"
[ -n "$OUT_DMG" ] || OUT_DMG="${STEM}-${VERSION}.dmg"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT   # 无论成功或失败都清理临时 staging,避免残留 appex 副本
STAGING="$TMP_DIR/staging"
mkdir -p "$STAGING"

cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "▶ 正在生成 DMG: $OUT_DMG"
hdiutil create \
  -volname "$STEM" \
  -srcfolder "$STAGING" \
  -fs HFS+ \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$OUT_DMG" >/dev/null

rm -rf "$TMP_DIR"
echo "✅ 完成: $OUT_DMG"
echo "   收件人:双击挂载 -> 把「鼠标工具」拖到「Applications」-> 右键打开首次运行。"
