//  ConfigModel.swift
//  SwiftUI 可观察的配置模型。任何修改都会自动持久化到扩展容器(供扩展读取)。

import Foundation
import Combine

final class ConfigModel: ObservableObject {
    static let shared = ConfigModel()

    @Published var config: Config {
        didSet { ConfigStore.saveForApp(config) }
    }

    init() {
        config = ConfigStore.loadForApp()
    }
}
