//  ActionRouter.swift
//  根据 menu tag 分发动作。
//  - 剪贴板 / 新建文件 / 启动应用 / 打开目录:扩展直接执行(沙盒允许,即时)。
//  - 压缩 / 解压 / 终端 / iTerm2:写 pending_task 并唤起主 App 执行(沙盒禁止 Process/AppleScript)。

import Cocoa
import CoreFoundation

enum ActionRouter {
    static func handle(tag: Int, items: [String], target: String?) {
        let config = ConfigStore.loadForExtension()

        switch tag {
        // MARK: 交给主 App
        case FinderSyncExt.Tag.compress:
            handoff(.compress, items: items, target: target)
        case FinderSyncExt.Tag.decompress:
            handoff(.decompress, items: items, target: target)
        case FinderSyncExt.Tag.openTerminal:
            handoff(.openTerminal, items: items, target: target)
        case FinderSyncExt.Tag.openITerm:
            handoff(.openITerm, items: items, target: target)

        // MARK: 拷贝路径(剪贴板)
        case FinderSyncExt.Tag.copyPathPOSIX:
            copyToClipboard(items.joined(separator: "\n"))
        case FinderSyncExt.Tag.copyPathHFS:
            copyToClipboard(items.map(hfsPath).joined(separator: "\n"))
        case FinderSyncExt.Tag.copyPathFileURL:
            copyToClipboard(items.map { URL(fileURLWithPath: $0).absoluteString }
                                  .joined(separator: "\n"))

        // MARK: 拷贝文件名(剪贴板)
        case FinderSyncExt.Tag.copyNameWithExt:
            copyToClipboard(items.map { URL(fileURLWithPath: $0).lastPathComponent }
                                  .joined(separator: "\n"))
        case FinderSyncExt.Tag.copyNameNoExt:
            copyToClipboard(items.map { nameWithoutExtension($0) }
                                  .joined(separator: "\n"))

        // MARK: 动态项
        default:
            if tag >= FinderSyncExt.Tag.newFileBase
                && tag < FinderSyncExt.Tag.newFileBase + config.templates.count {
                let t = config.templates[tag - FinderSyncExt.Tag.newFileBase]
                newFile(template: t, target: target, selected: items)
            } else if tag >= FinderSyncExt.Tag.openAppBase
                && tag < FinderSyncExt.Tag.openAppBase + config.apps.count {
                launchApp(config.apps[tag - FinderSyncExt.Tag.openAppBase])
            } else if tag >= FinderSyncExt.Tag.openDirBase
                && tag < FinderSyncExt.Tag.openDirBase + config.dirs.count {
                openDir(config.dirs[tag - FinderSyncExt.Tag.openDirBase])
            }
        }
    }

    // MARK: 直接执行

    private static func copyToClipboard(_ string: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
    }

    /// HFS 风格路径(Macintosh HD:Users:...)。
    private static func hfsPath(_ posix: String) -> String {
        let url = URL(fileURLWithPath: posix) as CFURL
        // CFURLPathStyle 的 Swift 桥接未暴露命名 case,用 raw value:HFS = 1。
        let hfsStyle = CFURLPathStyle(rawValue: 1)!
        return CFURLCopyFileSystemPath(url, hfsStyle) as String? ?? posix
    }

    private static func nameWithoutExtension(_ posix: String) -> String {
        URL(fileURLWithPath: posix).deletingPathExtension().lastPathComponent
    }

    private static func newFile(template: NewFileTemplate, target: String?, selected: [String]) {
        // 目标目录:若选中单个文件夹,在其中创建;否则用当前所在文件夹 target。
        var dir: URL?
        if selected.count == 1 {
            let u = URL(fileURLWithPath: selected[0])
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue {
                dir = u
            }
        }
        if dir == nil, let t = target, !t.isEmpty {
            dir = URL(fileURLWithPath: t)
        }
        guard let dir = dir else { return }

        let name = uniqueName(base: template.fileName, in: dir)
        let fileURL = dir.appendingPathComponent(name)
        let data = Data(template.content.utf8)
        if FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil) {
            // 仅创建文件,不打开/跳转目录(Finder 会自动刷新显示新文件)。
        } else {
            // 沙盒可能阻止在目标目录写入,交给主 App(非沙盒)执行
            handoff(.newFile, items: [template.fileName, template.content], target: dir.path)
        }
    }

    private static func launchApp(_ app: CommonApp) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error = error {
                NSLog("[MouseTools] 启动应用失败 \(app.name): \(error.localizedDescription)")
            }
        }
    }

    private static func openDir(_ dir: CommonDir) {
        // 沙盒扩展无法打开任意目录,交给主 App(非沙盒)打开。
        handoff(.openDir, items: [dir.path], target: nil)
    }

    // MARK: 交给主 App

    private static func handoff(_ action: PendingTask.Action, items: [String], target: String?) {
        let task = PendingTask(action: action,
                               items: items,
                               target: target,
                               createdAt: Date().timeIntervalSince1970)
        do {
            try FileManager.default.createDirectory(at: SharedPaths.sandboxedConfigDir,
                                                    withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(task)
            try data.write(to: SharedPaths.sandboxedTaskURL, options: .atomic)
        } catch {
            NSLog("[MouseTools] 写入任务失败: \(error.localizedDescription)")
            return
        }
        var components = URLComponents()
        components.scheme = SharedPaths.urlScheme
        components.host = "run"
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: 工具

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
