//  AppDelegate.swift
//  处理启动模式判定与 mousetools:// URL(任务交接)。
//
//  - 普通启动:显示设置窗口。
//  - 任务启动(启动时发现新鲜的 pending_task.json):隐藏窗口、执行任务,完成后转为常驻
//    (菜单栏图标保留,后续操作即时响应,不再每次重启)。
//    “新鲜”= 时间戳 < 10 秒,据此与用户正常启动区分。
//  - 已在运行时收到 URL:执行任务。

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let config = ConfigModel.shared

    private var launchedForTask = false
    private var taskRan = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        launchedForTask = hasFreshTask()
        guard launchedForTask else { return }

        // 任务模式:隐藏主窗口(反馈由进度面板/告警提供)
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.orderOut(nil)
            }
        }
        // 兜底:若 URL 事件意外丢失,3 秒后恢复为正常窗口,避免卡死
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, !self.taskRan, self.launchedForTask else { return }
            self.launchedForTask = false
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              url.scheme?.lowercased() == SharedPaths.urlScheme else { return }
        runPendingTask()
    }

    // MARK: 任务

    private func hasFreshTask() -> Bool {
        guard let data = try? Data(contentsOf: SharedPaths.rawTaskURL),
              let task = try? JSONDecoder().decode(PendingTask.self, from: data) else {
            return false
        }
        let age = Date().timeIntervalSince1970 - task.createdAt
        return age >= 0 && age < 10
    }

    private func runPendingTask() {
        guard let data = try? Data(contentsOf: SharedPaths.rawTaskURL),
              let task = try? JSONDecoder().decode(PendingTask.self, from: data) else {
            return
        }
        try? FileManager.default.removeItem(at: SharedPaths.rawTaskURL)
        taskRan = true

        TaskRunner.run(task: task) { [weak self] in
            DispatchQueue.main.async {
                // 任务完成:App 转为常驻(菜单栏图标保留),后续操作即时响应。
                self?.launchedForTask = false
            }
        }
    }
}
