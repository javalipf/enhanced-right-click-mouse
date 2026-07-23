# 鼠标工具 MouseTools

一个免费、本地的 macOS Finder 右键增强 App。通过 **Finder Sync 扩展**在 Finder 右键菜单中增加一个「鼠标工具」子菜单,体验接近市面上的付费工具,但完全本地、免费。

## 功能

右键菜单「鼠标工具 ▸」:

- **压缩为 ZIP** — 用系统 `ditto` 打包,保留资源 fork。
- **解压** — 支持 `.zip` / `.tar` / `.tar.gz` / `.tgz` 等。
- **新建文件 ▸** — 按模板新建文件(文本 / Markdown / Shell…,可在设置里自定义),自动避免重名。
- **打开终端** — 在所选目录用 Terminal.app 打开新窗口。
- **打开 iTerm2** — 在所选目录用 iTerm2 打开新窗口。
- **打开应用 ▸** — 快速启动常用应用(可在设置里增删)。
- **拷贝路径 ▸** — POSIX 路径 / HFS 路径 / `file://` URL。
- **拷贝文件名 ▸** — 含扩展名 / 不含扩展名。
- **常用目录 ▸** — 一键在 Finder 打开常用目录(可在设置里增删)。

## 架构(简述)

| Target | 类型 | 沙盒 | 职责 |
|---|---|---|---|
| `MouseTools` | App (SwiftUI) | 否 | GUI 配置;执行需要 `Process`/`AppleScript` 的重操作(压缩/解压/终端/iTerm2) |
| `FinderSyncExt` | Finder Sync 扩展 | 是(系统强制) | 构建右键菜单;执行轻量操作(剪贴板/新建文件/启动应用/打开目录);重操作交给主 App |

- **配置共享**:主 App(非沙盒)把 `config.json` 写入扩展自身容器目录,扩展从自己的容器读取 —— 无需 App Groups,也无需付费开发者账号。
- **任务交接**:扩展把待办写入 `pending_task.json`,再用 `mousetools://` URL 唤起主 App 执行。

## 前置要求

1. **Xcode**(完整版,非仅命令行工具)— 从 Mac App Store 安装。
   安装后执行:
   ```sh
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
2. **xcodegen**:
   ```sh
   brew install xcodegen
   ```

## 构建与启用

```sh
cd /Users/mackli/IdeaProjects/mouse
./build.sh            # 等价于 xcodegen generate
open MouseTools.xcodeproj
```

在 Xcode 中:

1. **选择签名 Team**:分别选中 `MouseTools` 与 `FinderSyncExt` 两个 target → Signing & Capabilities → Team 选你的 Apple ID(个人免费团队即可)。若没有,在 Xcode → 设置 → Accounts 添加 Apple ID。
2. **Build & Run(⌘R)** 一次。运行一次主 App 才会向系统注册 Finder 扩展。
3. **启用扩展**:在 App 的「关于」页点「启用 Finder 扩展…」,或在
   *系统设置 → 隐私与安全性 → 扩展 → Finder 扩展* 中勾选「鼠标工具扩展」。
4. 在 Finder 中任意位置 **右键 → 鼠标工具 ▸**。

> Finder 有时需要重启才会刷新扩展菜单:按住 ⌥ 右键 Finder 图标 → 重新开启,或 `killall Finder`。

## 免费签名与 DMG 分发(给他人安装)

本方案用**免费的「个人团队(Personal Team)」签名**打包 DMG,**不需要付费开发者账号**。但请注意下方限制。

### 一次性准备

1. 按上面「构建与启用」装好 Xcode,并在 Xcode -> 设置 -> Accounts 添加你的 Apple ID(免费)。
2. 打开 `MouseTools.xcodeproj`,给 `MouseTools` 与 `FinderSyncExt` 两个 target 都选该 Personal Team。
3. **⌘B 构建一次** -- 这会在钥匙串生成「个人团队」签名证书(命令行打包依赖它)。记住你的 **Team ID**(Xcode -> 设置 -> Accounts 里 Apple ID 下那串 10 位字母数字)。

### 打包 DMG

```sh
cd /Users/mackli/IdeaProjects/mouse
export TEAM_ID=你的个人团队ID
./scripts/package.sh
```

脚本会:用 Release 配置 + 个人团队签名构建 -> 校验 App 与扩展签名 -> 生成 `MouseTools-1.0.dmg`(拖拽安装版)。

> 也可先在 Xcode 里构建/归档出 `MouseTools.app`,再单独运行 `./scripts/make-dmg.sh <MouseTools.app 路径>`。

### 收件人安装步骤(发给别人时附上)

1. 双击 `MouseTools-1.0.dmg` 挂载,把「鼠标工具」拖到「Applications」。
2. 在「启动台」或「应用程序」里找到「鼠标工具」,**按住 Control 点击(右键)-> 打开** -> 弹窗里再点「打开」(首次必须如此,否则 Gatekeeper 拦截)。
   - 若提示「已损坏」:终端执行 `xattr -dr com.apple.quarantine /Applications/鼠标工具.app` 后再打开。
3. App 启动后,到 **系统设置 -> 隐私与安全性 -> 扩展 -> Finder 扩展** 勾选「鼠标工具扩展」。
4. `killall Finder`,在 Finder 右键即可见「鼠标工具 ▸」。
5. 首次用「打开终端 / iTerm2」时,允许控制授权。

### ⚠️ 免费签名的重要限制

- **Finder 扩展在他人 Mac 上可能无法加载**:扩展由系统主动加载,对签名要求比普通 App 严格。免费/个人签名的扩展在**别人**的电脑上可能不出现右键菜单(在你自己电脑上正常)。这是无付费账号分发的固有风险,无法保证所有人都能用。
- **Gatekeeper 拦截**:收件人首次必须「右键 > 打开」(或 `xattr` 去隔离),没有付费签名 + 公证就不会自动放行。
- 若需要**所有人都能顺畅安装且扩展稳定加载**,唯一可靠的方式是 Apple 开发者计划($99/年)的 **Developer ID 签名 + 公证**;那时把 `scripts/package.sh` 里的签名方式换成 `developer-id` 导出 + `notarytool` 公证即可(届时我可帮你补公证脚本)。

## 故障排查

- **右键没有「鼠标工具」**:确认已 Build & Run 主 App 一次;确认扩展已勾选;`killall Finder` 后重试。
- **「打开终端 / iTerm2」首次无反应**:系统会弹窗「鼠标工具想要控制 Terminal/iTerm」,请允许。若误点拒绝,到 *系统设置 → 隐私与安全性 → 自动化* 中重新开启。
- **压缩/解压失败**:主 App 非沙盒,对普通用户文件有完全访问;少数受保护目录(如系统目录)可能失败。
- **扩展签名加载失败**:个人免费团队通常可正常加载;若个别机器拒绝加载 ad-hoc/个人签名扩展,可能需要付费开发者账号。
- **构建报错 "No signing certificate 'Mac Development' found"**:原因是团队 ID 填错或证书名不匹配。你的签名身份是「Apple Development」,`package.sh` 已用 `CODE_SIGN_IDENTITY="Apple Development"`。**Team ID 是钥匙串证书的 OU(组织单元)**,不是证书名里邮箱后括号中的那串;用 `security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject` 查看 `OU=` 的值。

## 配置即时生效

在主 App 中修改「常用应用 / 常用目录 / 新建文件模板 / 功能开关」后,**下次右键即生效**(扩展每次构建菜单时重读配置),无需重启。

## 目录结构

```
mouse/
├── project.yml            # XcodeGen 工程描述
├── build.sh               # 生成工程
├── scripts/               # 打包脚本
│   ├── make-dmg.sh        # 把 .app 打包成拖拽安装 DMG(仅依赖系统 hdiutil)
│   └── package.sh         # 免费签名 Release 构建 + 生成 DMG
├── Shared/                # 两 target 共用源码
│   ├── SharedPaths.swift
│   ├── Config.swift
│   ├── ConfigStore.swift
│   └── PendingTask.swift
├── MouseTools/            # 主 App
│   ├── MouseToolsApp.swift
│   ├── AppDelegate.swift
│   ├── ConfigModel.swift
│   ├── ContentView.swift
│   ├── Views/…
│   ├── Services/…
│   └── Resources/MouseTools.entitlements
└── FinderSyncExt/         # Finder Sync 扩展
    ├── FinderSyncExt.swift
    ├── MenuBuilder.swift
    ├── ActionRouter.swift
    └── Resources/FinderSyncExt.entitlements
```

## 许可

本地自用工具,可自由修改分发。
