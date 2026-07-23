//  CommonAppsTab.swift
//  管理「打开应用」子菜单里的常用应用。

import SwiftUI
import UniformTypeIdentifiers

struct CommonAppsTab: View {
    @EnvironmentObject var config: ConfigModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("常用应用").font(.title2).bold()
            Text("这些应用会出现在右键菜单「鼠标工具 ▸ 打开应用」中,点击即启动。")
                .foregroundStyle(.secondary)

            List {
                ForEach($config.config.apps) { $app in
                    HStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.path))
                            .resizable()
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading) {
                            TextField("显示名", text: $app.name)
                            Text(app.path).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { config.config.apps.remove(atOffsets: $0) }
                .onMove { config.config.apps.move(fromOffsets: $0, toOffset: $1) }
            }

            HStack {
                Button("添加应用…") { pickApp() }
                if !config.config.apps.isEmpty {
                    Button("清空") { config.config.apps.removeAll() }
                }
                Spacer()
            }
            Text("提示:鼠标悬停在行上可删除,拖动行可排序。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func pickApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let name = url.deletingPathExtension().lastPathComponent
        config.config.apps.append(CommonApp(id: UUID(), name: name, path: url.path))
    }
}
