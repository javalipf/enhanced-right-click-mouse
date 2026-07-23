//  AboutTab.swift
//  版本信息、启用扩展入口、故障排查。

import SwiftUI
import FinderSync

struct AboutTab: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("鼠标工具").font(.largeTitle).bold()
            Text("版本 \(appVersion)").foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("启用 Finder 扩展").font(.headline)
                Text("若右键菜单未出现「鼠标工具」,点击下方按钮,并在系统设置中勾选「鼠标工具扩展」。")
                    .foregroundStyle(.secondary)
                Button("启用 Finder 扩展…") {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("故障排查").font(.headline)
                Text(
                    "• 首次使用「打开终端 / iTerm2」时,系统会弹窗请求授权,请允许;误拒可在 系统设置 › 隐私与安全性 › 自动化 中重开。\n" +
                    "• 扩展需用 Apple ID 签名(个人免费团队即可)。\n" +
                    "• 修改配置后,下次右键即生效,无需重启。\n" +
                    "• 若菜单不刷新,可执行 killall Finder。"
                )
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
