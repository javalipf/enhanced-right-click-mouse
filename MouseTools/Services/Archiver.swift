//  Archiver.swift
//  压缩 / 解压(主 App 非沙盒,可运行 ditto / tar / unzip)。
//  压缩:ditto -c -k --sequesterRsrc --keepParent(保留资源 fork)。
//  解压:.zip 用 ditto -x -k;tar 系用 tar -xf。

import Foundation
import AppKit

enum Archiver {
    static func compress(items: [String], target: String?,
                         completion: @escaping (Bool) -> Void) {
        guard !items.isEmpty else { completion(false); return }

        let urls = items.map { URL(fileURLWithPath: $0) }
        let parentDir = urls[0].deletingLastPathComponent()

        let baseName: String
        if urls.count == 1 {
            baseName = urls[0].lastPathComponent + ".zip"
        } else {
            let dirName = parentDir.lastPathComponent
            baseName = (dirName.isEmpty ? "Archive" : dirName) + ".zip"
        }
        let outputURL = uniqueURL(baseName: baseName, in: parentDir)

        ProgressPanel.shared.show(text: "正在压缩…")
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-c", "-k", "--sequesterRsrc", "--keepParent"] + items + [outputURL.path]
            let errPipe = Pipe()
            process.standardError = errPipe

            var ok = false
            var errMsg = ""
            do {
                try process.run()
                process.waitUntilExit()
                ok = process.terminationStatus == 0
                if !ok {
                    errMsg = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(),
                                     encoding: .utf8) ?? ""
                }
            } catch {
                errMsg = error.localizedDescription
            }

            DispatchQueue.main.async {
                ProgressPanel.shared.hide()
                if !ok {
                    Alerts.show(title: "压缩失败",
                                message: errMsg.isEmpty ? "请检查文件权限。" : errMsg)
                }
                completion(ok)
            }
        }
    }

    static func decompress(items: [String], completion: @escaping (Bool) -> Void) {
        let archives = items.filter { isArchive($0) }
        guard !archives.isEmpty else { completion(false); return }

        ProgressPanel.shared.show(text: "正在解压…")
        DispatchQueue.global(qos: .userInitiated).async {
            var allOK = true
            for path in archives {
                let url = URL(fileURLWithPath: path)
                let dest = url.deletingLastPathComponent()
                let ext = url.pathExtension.lowercased()
                let ok = (ext == "zip") ? runDittoExtract(path: path, dest: dest)
                                         : runTarExtract(path: path, dest: dest)
                if !ok { allOK = false }
            }
            DispatchQueue.main.async {
                ProgressPanel.shared.hide()
                if !allOK {
                    Alerts.show(title: "解压失败",
                                message: "部分或全部文件解压失败,请确认格式(.zip/.tar/.tar.gz/.tgz)。")
                }
                completion(allOK)
            }
        }
    }

    // MARK: 底层

    private static func runDittoExtract(path: String, dest: URL) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = ["-x", "-k", path, dest.path]
        do { try p.run(); p.waitUntilExit(); return p.terminationStatus == 0 }
        catch { return false }
    }

    private static func runTarExtract(path: String, dest: URL) -> Bool {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        p.arguments = ["-xf", path, "-C", dest.path]
        do { try p.run(); p.waitUntilExit(); return p.terminationStatus == 0 }
        catch { return false }
    }

    private static func isArchive(_ path: String) -> Bool {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        return ["zip", "tar", "gz", "tgz", "bz2", "xz"].contains(ext)
    }

    private static func uniqueURL(baseName: String, in dir: URL) -> URL {
        let fm = FileManager.default
        let base = dir.appendingPathComponent(baseName)
        if !fm.fileExists(atPath: base.path) { return base }
        let ext = base.pathExtension
        let stem = base.deletingPathExtension().lastPathComponent
        var i = 2
        while true {
            let name = ext.isEmpty ? "\(stem) \(i)" : "\(stem) \(i).\(ext)"
            let u = dir.appendingPathComponent(name)
            if !fm.fileExists(atPath: u.path) { return u }
            i += 1
        }
    }
}
