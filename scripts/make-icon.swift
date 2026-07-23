//  make-icon.swift - 生成 1024x1024 像素的 App 图标 PNG(渐变背景 + 白色光标箭头)。
//  直接用 CGBitmapContext 渲染,确保精确 1024x1024 像素(不受屏幕 Retina 倍率影响)。
//  用法: swift scripts/make-icon.swift
import AppKit
import CoreGraphics

let S = 1024
guard let cs = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(data: nil, width: S, height: S,
                          bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("无法创建位图上下文")
}

// 1) 全幅渐变背景(亮蓝 -> 青绿),y-up:左上 -> 右下
let c1 = NSColor(srgbRed: 0.20, green: 0.46, blue: 0.96, alpha: 1).cgColor
let c2 = NSColor(srgbRed: 0.07, green: 0.76, blue: 0.82, alpha: 1).cgColor
let grad = CGGradient(colorsSpace: cs, colors: [c1, c2] as CFArray, locations: [0, 1])!
ctx.saveGState()
ctx.addRect(CGRect(x: 0, y: 0, width: S, height: S))
ctx.clip()
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])
ctx.restoreGState()

// 2) 白色光标箭头(经典箭头轮廓,缩放居中,带柔和阴影)
let pts: [CGPoint] = [
    CGPoint(x: 303, y: 797),  // 箭头尖(上)
    CGPoint(x: 303, y: 227),  // 左下
    CGPoint(x: 455, y: 379),  // 内凹
    CGPoint(x: 569, y: 227),  // 尾部下
    CGPoint(x: 645, y: 265),  // 尾部
    CGPoint(x: 531, y: 417),  // 内凹
    CGPoint(x: 721, y: 417),  // 杆右端
]
let path = CGMutablePath()
path.move(to: pts[0])
for p in pts.dropFirst() { path.addLine(to: p) }
path.closeSubpath()

ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 44,
              color: NSColor.black.withAlphaComponent(0.33).cgColor)
ctx.addPath(path)
ctx.setFillColor(NSColor.white.cgColor)
ctx.fillPath()
ctx.restoreGState()

// 3) 导出 PNG
guard let cgImage = ctx.makeImage(),
      let png = NSBitmapImageRep(cgImage: cgImage)
        .representation(using: .png, properties: [:]) else {
    fatalError("导出 PNG 失败")
}

let outDir = "MouseTools/Resources/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let outURL = URL(fileURLWithPath: outDir + "/icon_1024.png")
try png.write(to: outURL)
print("已生成图标: \(outURL.path)  (\(S)x\(S) 像素, \(png.count) 字节)")
