//  CommonDirsTab.swift
//  管理「常用目录」子菜单里的常用目录。

import SwiftUI

struct CommonDirsTab: View {
    @EnvironmentObject var config: ConfigModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("常用目录").font(.title2).bold()
            Text("这些目录会出现在右键菜单「鼠标工具 ▸ 常用目录」中,点击即在 Finder 打开。")
                .foregroundStyle(.secondary)

            List {
                ForEach($config.config.dirs) { $dir in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            TextField("显示名", text: $dir.name)
                            Text(dir.path).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { config.config.dirs.remove(atOffsets: $0) }
                .onMove { config.config.dirs.move(fromOffsets: $0, toOffset: $1) }
            }

            HStack {
                Button("添加目录…") { pickDir() }
                if !config.config.dirs.isEmpty {
                    Button("清空") { config.config.dirs.removeAll() }
                }
                Spacer()
            }
            Text("提示:鼠标悬停在行上可删除,拖动行可排序。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func pickDir() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let name = url.lastPathComponent
        config.config.dirs.append(CommonDir(id: UUID(), name: name, path: url.path))
    }
}
