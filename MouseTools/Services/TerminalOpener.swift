//  TerminalOpener.swift
//  用 AppleScript 在所选目录打开 Terminal / iTerm2 新窗口。
//  主 App 非沙盒,可执行 NSAppleScript;首次需用户授权控制目标 App(系统 TCC 弹窗)。

import Foundation
import AppKit

enum TerminalOpener {
    static func openTerminal(items: [String], target: String?,
                             completion: @escaping () -> Void) {
        let dir = resolveDir(items: items, target: target)
        let script = """
        tell application "Terminal"
            activate
            do script "cd \(shellEscape(dir))"
        end tell
        """
        runAppleScript(script, appName: "Terminal", completion: completion)
    }

    static func openITerm(items: [String], target: String?,
                          completion: @escaping () -> Void) {
        let dir = resolveDir(items: items, target: target)
        let script = """
        tell application "iTerm"
            activate
            try
                set newWindow to (create window with default profile)
                tell current session of newWindow
                    write text "cd \(shellEscape(dir))"
                end tell
            on error
                tell current session of current window
                    write text "cd \(shellEscape(dir))"
                end tell
            end try
        end tell
        """
        runAppleScript(script, appName: "iTerm", completion: completion)
    }

    // MARK: 辅助

    /// 解析要进入的目录:选中单个文件夹->该文件夹;选中文件->其所在目录;否则用 target;否则 home。
    private static func resolveDir(items: [String], target: String?) -> String {
        if items.count == 1 {
            let u = URL(fileURLWithPath: items[0])
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue {
                return u.path
            }
            return u.deletingLastPathComponent().path
        }
        if let t = target, !t.isEmpty { return t }
        return NSHomeDirectory()
    }

    /// 用单引号包裹路径并转义内部单引号,供 shell cd 安全使用。
    private static func shellEscape(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func runAppleScript(_ source: String, appName: String,
                                       completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            let errMsg = (error?[NSAppleScript.errorMessage] as? String)
            DispatchQueue.main.async {
                if let errMsg = errMsg, !errMsg.isEmpty {
                    Alerts.show(title: "无法打开 \(appName)",
                                message: "\(errMsg)\n\n请确认已在 系统设置 › 隐私与安全性 › 自动化 中授权“鼠标工具”控制 \(appName)。")
                }
                completion()
            }
        }
    }
}
