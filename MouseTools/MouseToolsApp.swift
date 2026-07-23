//  MouseToolsApp.swift
//  主 App 入口。
//
//  作为菜单栏(LSUIElement)应用运行:无 Dock 图标、启动不弹主窗口。
//  设置窗口按需由 SettingsWindowController 弹出(菜单栏「打开设置」)。

import AppKit
import SwiftUI

@main
struct MouseToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 唯一常驻场景:菜单栏图标。没有 WindowGroup -> 启动/任务时不会自动弹窗。
        MenuBarExtra {
            StatusBarMenu()
        } label: {
            Image(nsImage: AppAssets.statusBarIcon)
                .renderingMode(.original)
        }
        .menuBarExtraStyle(.menu)
    }
}

/// 菜单栏下拉菜单。
struct StatusBarMenu: View {
    var body: some View {
        Button("打开设置…") {
            SettingsWindowController.shared.show()
        }
        Divider()
        Button("关于 鼠标工具") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }
        Divider()
        Button("退出 鼠标工具") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

/// 应用级资源(菜单栏图标等)。
enum AppAssets {
    /// 菜单栏图标:圆角蓝->青渐变底 + 白色光标(彩色,与 App 图标风格一致)。
    static let statusBarIcon: NSImage = {
        let size = NSSize(width: 20, height: 20)
        let image = NSImage(size: size)
        image.lockFocus()

        // 圆角底色:蓝 -> 青渐变
        let badge = NSBezierPath(roundedRect: NSRect(x: 1, y: 1, width: 18, height: 18),
                                 xRadius: 6, yRadius: 6)
        let gradient = NSGradient(
            starting: NSColor(srgbRed: 59/255,  green: 130/255, blue: 246/255, alpha: 1), // #3B82F6
            ending:   NSColor(srgbRed: 20/255,  green: 184/255, blue: 166/255, alpha: 1)) // #14B8A6
        gradient?.draw(in: badge, angle: -45)

        // 白色光标箭头(尖端朝左上,几何居中于底色)
        let pts = [
            NSPoint(x: 7.1,  y: 16.4),   // 尖端(左上)
            NSPoint(x: 7.1,  y: 4.4),    // 左竖边下端
            NSPoint(x: 10.3, y: 7.6),    // 内凹
            NSPoint(x: 11.9, y: 3.6),    // 尾部底端
            NSPoint(x: 13.5, y: 4.4),
            NSPoint(x: 11.1, y: 8.4),
            NSPoint(x: 15.9, y: 8.4),    // 下沿右端
        ]
        let cursor = NSBezierPath()
        cursor.move(to: pts[0])
        for p in pts.dropFirst() { cursor.line(to: p) }
        cursor.close()
        NSColor.white.setFill()
        cursor.fill()

        image.unlockFocus()
        image.isTemplate = false   // 保留彩色底色,不转为单色模板
        return image
    }()
}
