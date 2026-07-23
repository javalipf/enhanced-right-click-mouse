//  SettingsWindowController.swift
//  设置窗口:按需创建并显示(菜单栏「打开设置」)。
//  关闭仅隐藏,可重复打开;不随主窗口自动弹出。

import AppKit
import SwiftUI

final class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    private override init() { super.init() }

    func show() {
        if window == nil {
            let rootView = ContentView()
                .environmentObject(ConfigModel.shared)
                .frame(minWidth: 700, minHeight: 480)
            let hosting = NSHostingController(rootView: rootView)
            let w = NSWindow(contentViewController: hosting)
            w.title = "鼠标工具"
            w.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            w.minSize = NSSize(width: 700, height: 480)
            w.setContentSize(NSSize(width: 760, height: 540))
            w.center()
            w.isReleasedWhenClosed = false
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
