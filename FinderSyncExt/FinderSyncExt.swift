//  FinderSyncExt.swift
//  Finder Sync 扩展主类。负责监听目录、构建右键菜单、分发动作。

import Cocoa
import FinderSync

class FinderSyncExt: FIFinderSync {

    /// 动作 tag(用 NSMenuItem.tag 编码动作;动态项 = 基址 + 索引)。
    enum Tag {
        // 交给主 App(Process/AppleScript)
        static let compress = 100
        static let decompress = 101
        static let openTerminal = 102
        static let openITerm = 103
        // 扩展直接执行(剪贴板)
        static let copyPathPOSIX = 110
        static let copyPathHFS = 111
        static let copyPathFileURL = 112
        static let copyNameWithExt = 120
        static let copyNameNoExt = 121
        // 动态:基址 + 索引
        static let newFileBase = 200
        static let openAppBase = 300
        static let openDirBase = 400
    }

    override init() {
        super.init()
        // 监听整个文件系统,使右键菜单全局可用。仅构建菜单,不做徽标计算,开销很小。
        FIFinderSyncController.default().directoryURLs =
            Set([URL(fileURLWithPath: "/")])
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // 在三种上下文菜单(选中项 / 容器空白处 / 侧边栏)中显示;工具栏菜单不处理。
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer, .contextualMenuForSidebar:
            return MenuBuilder.buildMenu(config: ConfigStore.loadForExtension(), target: self)
        default:
            return nil
        }
    }

    @objc func menuItemSelected(_ sender: NSMenuItem) {
        let ctrl = FIFinderSyncController.default()
        let target = ctrl.targetedURL()?.path
        let items = ctrl.selectedItemURLs()?.map { $0.path } ?? []
        ActionRouter.handle(tag: sender.tag, items: items, target: target)
    }
}
