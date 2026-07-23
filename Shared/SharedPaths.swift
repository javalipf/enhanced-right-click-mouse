//  SharedPaths.swift
//  主 App 与 Finder Sync 扩展共享的路径常量。
//
//  关键设计(无需 App Groups / 无需付费开发者账号):
//  - 扩展沙盒只能访问自身容器;主 App 非沙盒,可访问任意路径。
//  - 共享落点 = 扩展自身容器的 Application Support/MouseTools 目录。
//    · 扩展经“沙盒重定向路径”访问(sandboxed*);
//    · 主 App 经“原始容器路径”访问(raw*)。
//  两者指向同一个物理目录。

import Foundation

enum SharedPaths {
    static let appBundleID = "com.mackli.mousetools"
    static let extensionBundleID = "com.mackli.mousetools.finderext"
    static let urlScheme = "mousetools"

    static let configDirName = "MouseTools"
    static let configFileName = "config.json"
    static let taskFileName = "pending_task.json"

    // MARK: 扩展视角(沙盒重定向)— 扩展读写自身容器用

    /// 扩展容器内的 Application Support/MouseTools 目录。
    static var sandboxedConfigDir: URL {
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(configDirName, isDirectory: true)
    }

    static var sandboxedConfigURL: URL {
        sandboxedConfigDir.appendingPathComponent(configFileName)
    }

    static var sandboxedTaskURL: URL {
        sandboxedConfigDir.appendingPathComponent(taskFileName)
    }

    // MARK: 主 App 视角(原始路径)— 非沙盒直接访问扩展容器用

    /// 主 App 视角下,扩展容器的 Application Support/MouseTools 目录(原始路径)。
    static var rawConfigDir: URL {
        let home = NSHomeDirectory()
        let containerAppSupport = home +
            "/Library/Containers/\(extensionBundleID)/Data/Library/Application Support"
        return URL(fileURLWithPath: containerAppSupport)
            .appendingPathComponent(configDirName, isDirectory: true)
    }

    static var rawConfigURL: URL {
        rawConfigDir.appendingPathComponent(configFileName)
    }

    static var rawTaskURL: URL {
        rawConfigDir.appendingPathComponent(taskFileName)
    }
}
