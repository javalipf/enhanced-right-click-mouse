//  ConfigStore.swift
//  配置读写。
//  主 App:经原始容器路径读写 rawConfigURL(非沙盒,可访问扩展容器)。
//  扩展:经沙盒重定向路径只读 sandboxedConfigURL(自身容器)。
//
//  缓存:按 URL 缓存已解码的 Config,以文件 mtime 失效。
//  - 扩展每次右键 / 点击都会读取,缓存可避免重复「读盘 + 解码」。
//  - 主 App 与扩展是不同进程,各自维护缓存;主 App 写入后 mtime 改变,
//    扩展下次读取即命中失败 → 重新读盘,从而跨进程拿到新配置。
//  - 主 App 自身 save 后立即清除该条目,规避同秒内 mtime 粒度不足的极端情况。

import Foundation

enum ConfigStore {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private static let decoder = JSONDecoder()

    /// 缓存:key = 配置文件路径,value = (mtime, 已解码配置)。
    private static var cache: [String: (mtime: Date, config: Config)] = [:]
    private static let cacheLock = NSLock()

    /// 主 App:加载配置(不存在则返回默认)。
    static func loadForApp() -> Config {
        load(from: SharedPaths.rawConfigURL) ?? .default
    }

    /// 主 App:保存配置到扩展容器,供扩展读取。
    @discardableResult
    static func saveForApp(_ config: Config) -> Bool {
        do {
            try FileManager.default.createDirectory(
                at: SharedPaths.rawConfigDir,
                withIntermediateDirectories: true)
            let data = try encoder.encode(config)
            try data.write(to: SharedPaths.rawConfigURL, options: .atomic)
            // 写后立即失效自身缓存(mtime 粒度可能不足以区分同秒读写)。
            invalidate(url: SharedPaths.rawConfigURL)
            return true
        } catch {
            NSLog("[MouseTools] 保存配置失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 扩展:只读加载配置(经沙盒重定向路径)。
    static func loadForExtension() -> Config {
        load(from: SharedPaths.sandboxedConfigURL) ?? .default
    }

    private static func load(from url: URL) -> Config? {
        // 取 mtime;文件不存在则直接返回 nil(不缓存「不存在」状态)。
        let mtime: Date
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            mtime = (attrs[.modificationDate] as? Date) ?? .distantPast
        } catch {
            return nil
        }

        // 命中缓存:mtime 未变则直接返回已解码配置,跳过读盘 + 解码。
        let key = url.path
        cacheLock.lock()
        let cached = cache[key]
        cacheLock.unlock()
        if let cached = cached, cached.mtime == mtime {
            return cached.config
        }

        // 未命中:读盘 + 解码,并写入缓存。
        guard let data = try? Data(contentsOf: url),
              let config = try? decoder.decode(Config.self, from: data) else {
            return nil
        }
        cacheLock.lock()
        cache[key] = (mtime, config)
        cacheLock.unlock()
        return config
    }

    private static func invalidate(url: URL) {
        cacheLock.lock()
        cache.removeValue(forKey: url.path)
        cacheLock.unlock()
    }
}
