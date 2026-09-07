import Foundation

/// 全局路由：Tab 切换 + 各 Tab 的 NavigationStack 路径
final class Router: ObservableObject {
    /// 底部导航：首页 / 探索 / 游戏 / 收藏（设置放在右上角，§8）
    enum Tab: String {
        case home, explore, games, favorites
    }

    enum NatureRoute: Hashable {
        case deck(NatureCategory)
        case item(String)
    }

    enum PoemRoute: Hashable {
        case detail(String)
    }

    @Published var tab: Tab
    @Published var naturePath: [NatureRoute] = []
    @Published var poemPath: [PoemRoute] = []
    /// DEBUG 专用：启动直达设置页（--page=settings）
    @Published var showSettings = false

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        print("[Router] args = \(args)")
        // 调试启动参数：--tab=nature --page=deck:fruit / item:fruit_apple / poem:poem_jingyesi
        if let raw = Self.arg("--tab="), let t = Tab(rawValue: raw) {
            tab = t
        } else {
            tab = .home
        }
        if let page = Self.arg("--page=") {
            if page == "settings" {
                showSettings = true
            } else if page.hasPrefix("deck:"), let cat = NatureCategory(rawValue: String(page.dropFirst(5))) {
                naturePath = [.deck(cat)]
            } else if page.hasPrefix("item:") {
                naturePath = [.item(String(page.dropFirst(5)))]
            } else if page.hasPrefix("poem:") {
                poemPath = [.detail(String(page.dropFirst(5)))]
            }
        }
        #else
        tab = .home
        #endif
    }

    #if DEBUG
    private static func arg(_ prefix: String) -> String? {
        for a in ProcessInfo.processInfo.arguments where a.hasPrefix(prefix) {
            return String(a.dropFirst(prefix.count))
        }
        return nil
    }
    #endif
}
