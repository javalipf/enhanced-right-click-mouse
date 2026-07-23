//  GeneralTab.swift
//  功能开关 + 新建文件模板编辑。

import SwiftUI

struct GeneralTab: View {
    @EnvironmentObject var config: ConfigModel

    var body: some View {
        Form {
            Section("功能开关(取消勾选则不在右键菜单显示)") {
                Toggle("压缩为 ZIP", isOn: $config.config.features.compress)
                Toggle("解压", isOn: $config.config.features.decompress)
                Toggle("新建文件", isOn: $config.config.features.newFile)
                Toggle("打开终端", isOn: $config.config.features.openTerminal)
                Toggle("打开 iTerm2", isOn: $config.config.features.openITerm)
                Toggle("打开常用应用", isOn: $config.config.features.openApp)
                Toggle("拷贝路径", isOn: $config.config.features.copyPath)
                Toggle("拷贝文件名", isOn: $config.config.features.copyName)
                Toggle("常用目录", isOn: $config.config.features.commonDirs)
            }

            Section("新建文件模板") {
                ForEach($config.config.templates) { $template in
                    HStack {
                        TextField("显示名", text: $template.name).frame(width: 110)
                        TextField("文件名", text: $template.fileName).frame(width: 150)
                        TextField("初始内容", text: $template.content, axis: .vertical)
                            .lineLimit(1...3)
                    }
                }
                .onDelete { config.config.templates.remove(atOffsets: $0) }
                .onMove { config.config.templates.move(fromOffsets: $0, toOffset: $1) }
                Button("添加模板") {
                    config.config.templates.append(
                        NewFileTemplate(id: UUID(), name: "新模板", fileName: "未命名.txt", content: ""))
                }
            }
        }
        .formStyle(.grouped)
    }
}
