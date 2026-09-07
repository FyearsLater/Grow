import Foundation

/// 全局路由：Tab 切换 + 探索栈深链路径
final class Router: ObservableObject {
    /// 底部导航：首页 / 探索 / 收藏 / 设置
    enum Tab: String {
        case home, explore, favorites, settings
    }

    enum NatureRoute: Hashable {
        case deck(NatureCategory)
        case item(String)
    }

    enum PoemRoute: Hashable {
        case detail(String)
    }

    /// 探索栈深链路由（DEBUG 启动参数用）
    enum ExploreRoute: Hashable {
        case natureDeck(NatureCategory)
        case natureItem(String)
        case poemDetail(String)
        case pinyin(PinyinType)
        case numbers
        /// DEBUG：直达二级页根部（--page=nature / poem / learning）
        case natureRoot
        case poemRoot
        case learningRoot
    }

    @Published var tab: Tab
    @Published var naturePath: [NatureRoute] = []
    @Published var poemPath: [PoemRoute] = []
    @Published var explorePath: [ExploreRoute] = []

    init() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        print("[Router] args = \(args)")
        // 调试启动参数：--tab=explore --page=deck:fruit / item:fruit_apple / poem:poem_xxx / pinyin:initial / numbers / settings
        if let raw = Self.arg("--tab="), let t = Tab(rawValue: raw) {
            tab = t
        } else {
            tab = .home
        }
        if let page = Self.arg("--page=") {
            if page == "settings" {
                tab = .settings
            } else if page.hasPrefix("deck:"), let cat = NatureCategory(rawValue: String(page.dropFirst(5))) {
                explorePath = [.natureDeck(cat)]
                if tab == .home { tab = .explore }
            } else if page.hasPrefix("item:") {
                explorePath = [.natureItem(String(page.dropFirst(5)))]
                if tab == .home { tab = .explore }
            } else if page.hasPrefix("poem:") {
                explorePath = [.poemDetail(String(page.dropFirst(5)))]
                if tab == .home { tab = .explore }
            } else if page.hasPrefix("pinyin:"), let t = PinyinType(rawValue: String(page.dropFirst(7))) {
                explorePath = [.pinyin(t)]
                if tab == .home { tab = .explore }
            } else if page == "numbers" {
                explorePath = [.numbers]
                if tab == .home { tab = .explore }
            } else if page == "nature" {
                explorePath = [.natureRoot]
                if tab == .home { tab = .explore }
            } else if page == "poem" {
                explorePath = [.poemRoot]
                if tab == .home { tab = .explore }
            } else if page == "learning" {
                explorePath = [.learningRoot]
                if tab == .home { tab = .explore }
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
