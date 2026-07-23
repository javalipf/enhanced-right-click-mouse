//  MenuBuilder.swift
//  按配置构建「鼠标工具」右键菜单。每次右键时由扩展调用,配置即时生效。

import Cocoa

enum MenuBuilder {
    static func buildMenu(config: Config, target: AnyObject) -> NSMenu {
        let menu = NSMenu(title: "鼠标工具")
        let f = config.features

        // 压缩 / 解压
        if f.compress {
            menu.addItem(item("压缩为 ZIP", tag: FinderSyncExt.Tag.compress, target: target,
                              image: symbol("doc.zipper")))
        }
        if f.decompress {
            menu.addItem(item("解压", tag: FinderSyncExt.Tag.decompress, target: target,
                              image: symbol("archivebox")))
        }

        // 新建文件
        if f.newFile && !config.templates.isEmpty {
            menu.addItem(submenu(title: "新建文件",
                                 image: symbol("doc.badge.plus"),
                                 items: config.templates.enumerated().map { (i, t) in
                                     item(t.name,
                                          tag: FinderSyncExt.Tag.newFileBase + i,
                                          target: target,
                                          image: fileTypeIcon(fileName: t.fileName))
                                 }))
        }

        // 打开终端 / iTerm2
        if f.openTerminal {
            menu.addItem(item("打开终端", tag: FinderSyncExt.Tag.openTerminal, target: target,
                              image: symbol("terminal")))
        }
        if f.openITerm {
            menu.addItem(item("打开 iTerm2", tag: FinderSyncExt.Tag.openITerm, target: target,
                              image: symbol("chevron.left.forwardslash.chevron.right")))
        }

        // 打开应用
        if f.openApp && !config.apps.isEmpty {
            menu.addItem(submenu(title: "打开应用",
                                 image: symbol("square.grid.2x2"),
                                 items: config.apps.enumerated().map { (i, a) in
                                     item(a.name,
                                          tag: FinderSyncExt.Tag.openAppBase + i,
                                          target: target,
                                          image: fileIcon(path: a.path))
                                 }))
        }

        // 拷贝路径:默认直接拷贝 POSIX;其他格式(HFS / file://)放子菜单保留。
        if f.copyPath {
            menu.addItem(item("拷贝路径", tag: FinderSyncExt.Tag.copyPathPOSIX, target: target,
                              image: symbol("link")))
            menu.addItem(submenu(title: "拷贝路径(其他格式)",
                                 image: symbol("link"),
                                 items: [
                item("HFS 路径", tag: FinderSyncExt.Tag.copyPathHFS, target: target,
                     image: symbol("link")),
                item("file:// URL", tag: FinderSyncExt.Tag.copyPathFileURL, target: target,
                     image: symbol("link")),
            ]))
        }

        // 拷贝文件名
        if f.copyName {
            menu.addItem(submenu(title: "拷贝文件名",
                                 image: symbol("doc.on.clipboard"),
                                 items: [
                item("含扩展名", tag: FinderSyncExt.Tag.copyNameWithExt, target: target,
                     image: symbol("doc.text")),
                item("不含扩展名", tag: FinderSyncExt.Tag.copyNameNoExt, target: target,
                     image: symbol("doc")),
            ]))
        }

        // 常用目录
        if f.commonDirs && !config.dirs.isEmpty {
            menu.addItem(submenu(title: "常用目录",
                                 image: symbol("folder"),
                                 items: config.dirs.enumerated().map { (i, d) in
                                     item(d.name,
                                          tag: FinderSyncExt.Tag.openDirBase + i,
                                          target: target,
                                          image: fileIcon(path: d.path))
                                 }))
        }

        return menu
    }

    // MARK: 辅助

    private static func item(_ title: String, tag: Int, target: AnyObject, image: NSImage? = nil) -> NSMenuItem {
        let mi = NSMenuItem(title: title,
                            action: #selector(FinderSyncExt.menuItemSelected(_:)),
                            keyEquivalent: "")
        mi.target = target
        mi.tag = tag
        mi.image = image
        return mi
    }

    private static func submenu(title: String, image: NSImage? = nil, items: [NSMenuItem]) -> NSMenuItem {
        let sub = NSMenu(title: title)
        for it in items { sub.addItem(it) }
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        parent.image = image
        parent.submenu = sub
        return parent
    }

    // MARK: 图标(进程内缓存,避免每次右键重建 NSImage)

    /// 应用 / 目录图标缓存:key = 路径。图标按路径稳定,无需失效。
    private static var fileIconCache: [String: NSImage] = [:]
    /// 文件类型图标缓存:key = 扩展名。
    private static var typeIconCache: [String: NSImage] = [:]
    private static let iconLock = NSLock()

    /// SF Symbol(模板图像,自适应菜单高亮与深色模式)。配 14pt 以贴合菜单行高。
    private static func symbol(_ name: String) -> NSImage? {
        let cfg = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(cfg)
    }

    /// 应用 / 目录的实际图标。NSWorkspace 经 Launch Services 取图标,沙盒内可用。
    /// 同一进程内按路径缓存,避免每次右键重新取图标 + 重建 NSImage。
    private static func fileIcon(path: String) -> NSImage {
        iconLock.lock()
        let cached = fileIconCache[path]
        iconLock.unlock()
        if let cached = cached { return cached }

        let img = NSWorkspace.shared.icon(forFile: path)
        img.size = NSSize(width: 16, height: 16)
        iconLock.lock()
        fileIconCache[path] = img
        iconLock.unlock()
        return img
    }

    /// 新建文件模板按扩展名取文件类型图标(如 .txt / .sh),按扩展名缓存。
    private static func fileTypeIcon(fileName: String) -> NSImage {
        let ext = (fileName as NSString).pathExtension
        iconLock.lock()
        let cached = typeIconCache[ext]
        iconLock.unlock()
        if let cached = cached { return cached }

        let img = NSWorkspace.shared.icon(forFileType: ext)
        img.size = NSSize(width: 16, height: 16)
        iconLock.lock()
        typeIconCache[ext] = img
        iconLock.unlock()
        return img
    }
}
