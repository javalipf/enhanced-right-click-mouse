#!/usr/bin/env bash
#  build.sh - 生成 Xcode 工程并提示构建步骤。
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "❌ 未找到 xcodegen。请先安装:"
  echo "   brew install xcodegen"
  exit 1
fi

echo "▶ 生成 Xcode 工程…"
xcodegen generate

echo
echo "✅ 已生成 MouseTools.xcodeproj"
echo
echo "下一步:"
echo "  1) open MouseTools.xcodeproj"
echo "  2) 为 MouseTools 与 FinderSyncExt 两个 target 选择签名 Team(Apple ID 个人团队即可)"
echo "  3) Build & Run(⌘R)一次,以注册 Finder 扩展"
echo "  4) 在 App 内点「启用 Finder 扩展…」,或在 系统设置 > 隐私与安全性 > 扩展 > Finder 扩展 中勾选"
echo "  5) 在 Finder 中右键 -> 鼠标工具 ▸"
