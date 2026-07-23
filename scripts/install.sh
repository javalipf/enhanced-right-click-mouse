#!/usr/bin/env bash
#  install.sh - 把构建产物干净地安装到 /Applications,并清理历史扩展残留。
#
#  背景:每次 xcodebuild 都会把 build/.../MouseTools.app 注册进 LaunchServices。
#  多次打包安装后,旧 build 路径、DerivedData、临时副本等会残留,导致「打开方式」
#  重复、Finder 扩展注册混乱。本脚本在安装前注销所有非 /Applications 的
#  MouseTools 注册,装完只保留 /Applications 一份。
#
#  用法: ./scripts/install.sh [MouseTools.app 路径]
#        默认使用 build/Build/Products/Release/MouseTools.app
set -euo pipefail
cd "$(dirname "$0")/.."

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
APP="${1:-build/Build/Products/Release/MouseTools.app}"
DEST="/Applications/MouseTools.app"
APPEX="$DEST/Contents/PlugIns/FinderSyncExt.appex"

if [ ! -d "$APP" ]; then
  echo "❌ 找不到构建产物: $APP"
  echo "   先构建: TEAM_ID=xxx ./scripts/package.sh   或   xcodebuild ... build"
  exit 1
fi

echo "▶ 停止运行中的进程…"
killall MouseTools 2>/dev/null || true
killall FinderSyncExt 2>/dev/null || true
sleep 1

echo "▶ 注销所有历史残留注册(保留 /Applications)…"
# 枚举 LaunchServices 里所有 MouseTools.app 路径,除 /Applications 外全部注销
"$LSREGISTER" -dump 2>/dev/null \
  | grep -oE '/[^ ]*MouseTools\.app' \
  | sort -u \
  | while read -r p; do
      [ "$p" = "$DEST" ] && continue
      echo "   - 注销 $p"
      "$LSREGISTER" -u "$p" 2>/dev/null || true
    done || true
# 旧的 /Applications 安装也注销,随后用 -f 重新注册,确保是最新版本
"$LSREGISTER" -u "$DEST" 2>/dev/null || true

echo "▶ 安装到 $DEST …"
rm -rf "$DEST"
cp -R "$APP" "$DEST"

echo "▶ 注册新版本…"
"$LSREGISTER" -f "$DEST"
pluginkit -a "$APPEX" 2>/dev/null || true

echo "▶ 重启 Finder…"
killall Finder 2>/dev/null || true

echo "▶ 启动…"
open -a "$DEST"

echo "✅ 完成。当前 LaunchServices 中的 MouseTools 注册:"
"$LSREGISTER" -dump 2>/dev/null | grep -oE '/[^ ]*MouseTools\.app' | sort -u || true
