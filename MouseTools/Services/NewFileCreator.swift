//  NewFileCreator.swift
//  兜底:当扩展沙盒无法在目标目录创建文件时,由主 App(非沙盒)创建。
//  items[0] = 默认文件名,items[1] = 初始内容,target = 目标目录。

import AppKit

enum NewFileCreator {
    static func create(items: [String], target: String?) {
        let fileName = items.first ?? "未命名.txt"
        let content = items.count > 1 ? items[1] : ""
        guard let dirPath = target else { return }
        let dir = URL(fileURLWithPath: dirPath)

        let name = uniqueName(base: fileName, in: dir)
        let fileURL = dir.appendingPathComponent(name)
        let data = Data(content.utf8)
        if FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil) {
            // 仅创建文件,不打开/跳转目录。
        }
    }

    private static func uniqueName(base: String, in dir: URL) -> String {
        let fm = FileManager.default
        if !fm.fileExists(atPath: dir.appendingPathComponent(base).path) { return base }
        let ext = (base as NSString).pathExtension
        let stem = (base as NSString).deletingPathExtension
        var i = 2
        while true {
            let name = ext.isEmpty ? "\(stem) \(i)" : "\(stem) \(i).\(ext)"
            if !fm.fileExists(atPath: dir.appendingPathComponent(name).path) { return name }
            i += 1
        }
    }
}
