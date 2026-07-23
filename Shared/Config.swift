//  Config.swift
//  共享的配置模型(Codable)。主 App 编辑并保存,扩展只读。

import Foundation

struct CommonApp: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String      // 菜单显示名
    var path: String      // .app 的绝对路径
}

struct CommonDir: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String      // 菜单显示名
    var path: String      // 目录绝对路径
}

struct NewFileTemplate: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String      // 菜单显示名,如 “文本文件”
    var fileName: String  // 默认文件名,如 “未命名.txt”
    var content: String   // 初始内容
}

struct FeatureFlags: Codable, Equatable {
    var compress: Bool = true
    var decompress: Bool = true
    var newFile: Bool = true
    var openTerminal: Bool = true
    var openITerm: Bool = true
    var openApp: Bool = true
    var copyPath: Bool = true
    var copyName: Bool = true
    var commonDirs: Bool = true
}

struct Config: Codable, Equatable {
    var features: FeatureFlags = .init()
    var apps: [CommonApp] = []
    var dirs: [CommonDir] = []
    var templates: [NewFileTemplate] = Config.defaultTemplates

    static let defaultTemplates: [NewFileTemplate] = [
        NewFileTemplate(id: UUID(), name: "文本文件", fileName: "未命名.txt", content: ""),
        NewFileTemplate(id: UUID(), name: "Markdown", fileName: "未命名.md", content: "# \n"),
        NewFileTemplate(id: UUID(), name: "Shell 脚本", fileName: "未命名.sh", content: "#!/bin/bash\n"),
    ]

    static let `default` = Config()
}
