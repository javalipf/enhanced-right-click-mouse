//  TaskRunner.swift
//  分发 pending_task 到具体执行器。completion 在主线程调用,且在任务真正完成后(用于任务模式退出判定)。

import AppKit

enum TaskRunner {
    static func run(task: PendingTask, completion: @escaping () -> Void) {
        switch task.action {
        case .compress:
            Archiver.compress(items: task.items, target: task.target) { _ in completion() }
        case .decompress:
            Archiver.decompress(items: task.items) { _ in completion() }
        case .openTerminal:
            TerminalOpener.openTerminal(items: task.items, target: task.target) { completion() }
        case .openITerm:
            TerminalOpener.openITerm(items: task.items, target: task.target) { completion() }
        case .newFile:
            NewFileCreator.create(items: task.items, target: task.target)
            completion()
        case .openDir:
            if let path = task.items.first {
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }
            completion()
        }
    }
}
