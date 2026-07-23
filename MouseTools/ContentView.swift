//  ContentView.swift
//  主窗口:侧边栏 + 详情页。

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var config: ConfigModel
    @State private var selection: SidebarItem? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("通用", systemImage: "gearshape").tag(SidebarItem.general)
                Label("常用应用", systemImage: "app").tag(SidebarItem.apps)
                Label("常用目录", systemImage: "folder").tag(SidebarItem.dirs)
                Label("关于", systemImage: "info.circle").tag(SidebarItem.about)
            }
            .navigationTitle("鼠标工具")
            .frame(minWidth: 180)
        } detail: {
            switch selection {
            case .apps:  CommonAppsTab()
            case .dirs:  CommonDirsTab()
            case .about: AboutTab()
            default:     GeneralTab()
            }
        }
    }
}

enum SidebarItem: Hashable {
    case general, apps, dirs, about
}
