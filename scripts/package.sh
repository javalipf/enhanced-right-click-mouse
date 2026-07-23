#!/usr/bin/env bash
#  package.sh - 用免费「个人团队」签名构建 Release 版,并打包成 DMG。
#
#  前置(一次性):
#   1. 安装 Xcode 并 `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
#   2. Xcode > 设置 > Accounts 添加你的 Apple ID(免费即可)
#   3. 打开 MouseTools.xcodeproj,为 MouseTools 与 FinderSyncExt 两 target 选该 Personal Team,
#      然后 ⌘B 构建一次 —— 这会在钥匙串生成「个人团队」签名证书(之后命令行才能用)。
#
#  用法:
#   export TEAM_ID=你的个人团队ID      # Xcode > 设置 > Accounts 里那串 10 位字母数字
#   ./scripts/package.sh
set -euo pipefail
cd "$(dirname "$0")/.."

: "${TEAM_ID:?请先 export TEAM_ID=<你的个人团队ID>。注意:它是钥匙串证书的“组织单元 OU”,即 openssl 查看 CN=Apple Development: 邮箱 (XXXX) 里括号外、subject 里的 OU= 一串 10 位字符,而非邮箱后括号里的那串。可用 security find-certificate -c 'Apple Development' -p | openssl x509 -noout -subject 查看。)}"
CONFIG="${CONFIG:-Release}"

echo "▶ 构建 $CONFIG(签名团队:$TEAM_ID)…"
xcodebuild \
  -project MouseTools.xcodeproj \
  -scheme MouseTools \
  -configuration "$CONFIG" \
  -derivedDataPath build \
  -destination 'generic/platform=macOS' \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  CODE_SIGN_IDENTITY="Apple Development" \
  build | tail -20

APP="build/Build/Products/$CONFIG/MouseTools.app"
if [ ! -d "$APP" ]; then
  echo "❌ 未找到构建产物: $APP"
  echo "   请检查上方构建日志。常见原因:个人团队证书未生成(先在 Xcode 里 ⌘B 构建一次)。"
  exit 1
fi

echo
echo "▶ 验证签名…"
codesign -dv --verbose=2 "$APP" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier" || true
codesign -dv --verbose=2 "$APP/Contents/PlugIns/FinderSyncExt.appex" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier" || true

echo
echo "▶ 打包 DMG…"
./scripts/make-dmg.sh "$APP"

echo
echo "✅ 全部完成。"
echo "   ⚠️ 免费签名分发提醒:收件人首次需「右键 > 打开」绕过 Gatekeeper,并在 系统设置 > 隐私与安全性 > 扩展 > Finder 扩展 中启用「鼠标工具扩展」。"
echo "   ⚠️ 免费签名的 Finder 扩展在他人 Mac 上可能无法加载,不保证所有人都能用。"
