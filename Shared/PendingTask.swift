//  PendingTask.swift
//  扩展写给主 App 的待办任务。
//  扩展把任务写入 sandboxedTaskURL(自身容器),再唤起主 App;
//  主 App 从 rawTaskURL(原始路径)读取并执行。

import Foundation

struct PendingTask: Codable {
    enum Action: String, Codable {
        case compress
        case decompress
        case openTerminal
        case openITerm
        case newFile      // 兜底:扩展沙盒若阻止在目标目录写文件,交给主 App
        case openDir      // 沙盒扩展无法打开任意目录,交给主 App
    }

    var action: Action
    var items: [String]    // 选中项的 POSIX 路径
    var target: String?    // 当前所在文件夹(targetedURL)的路径
    var createdAt: Double  // 创建时间戳(秒),主 App 据此判断新鲜度
}
