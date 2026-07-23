//  ProgressPanel.swift
//  压缩/解压时显示的浮动进度面板(不确定进度)。

import AppKit

final class ProgressPanel {
    static let shared = ProgressPanel()

    private let panel: NSPanel
    private let label: NSTextField
    private let indicator: NSProgressIndicator

    private init() {
        indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .large
        indicator.isIndeterminate = true
        indicator.startAnimation(nil)

        label = NSTextField(labelWithString: "")
        label.alignment = .center
        label.font = .systemFont(ofSize: 13)

        let stack = NSStackView(views: [indicator, label])
        stack.orientation = .vertical
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 22, bottom: 18, right: 22)

        let vc = NSViewController()
        vc.view = stack

        panel = NSPanel(contentViewController: vc)
        panel.title = "鼠标工具"
        panel.styleMask = [.titled]
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
    }

    func show(text: String) {
        label.stringValue = text
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        panel.orderOut(nil)
    }
}
