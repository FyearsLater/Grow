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

    /// 游戏栈路由（趣味游戏中心，Phase 5）
    enum GameRoute: Hashable {
        case home                          // 趣味游戏首页
        case puzzleHome                    // 拼图：难度选择（沿用原有三级结构）
        case puzzleGame(puzzleId: String)  // 拼图：直达某一局
        case levelSelect(GameType)         // 配对/找相同/分类：难度选择
        case matching(level: Int, focus: String?)
        case findSame(level: Int, focus: String?)
        case sorting(level: Int)
        case natureDetail(String)          // 完成页「认识一下」
    }

    @Published var tab: Tab
    @Published var naturePath: [NatureRoute] = []
    @Published var poemPath: [PoemRoute] = []
    @Published var explorePath: [ExploreRoute] = []
    @Published var gamesPath: [GameRoute] = []
    /// DEBUG 专用：启动直达设置页（--page=settings）
    @Published var showSettings = false

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
                showSettings = true
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
            } else if page == "game:home" {
                tab = .games
                gamesPath = [.home]
            } else if page == "game:puzzle" {
                tab = .games
                gamesPath = [.puzzleHome]
            } else if page == "game:sorting" {
                tab = .games
                gamesPath = [.sorting(level: Self.defaultGameLevel())]
            } else if page.hasPrefix("game:matching") {
                let focus = page.split(separator: ":").count > 2 ? String(page.split(separator: ":")[2]) : nil
                tab = .games
                gamesPath = [.matching(level: Self.defaultGameLevel(), focus: focus)]
            } else if page.hasPrefix("game:findsame") {
                let focus = page.split(separator: ":").count > 2 ? String(page.split(separator: ":")[2]) : nil
                tab = .games
                gamesPath = [.findSame(level: Self.defaultGameLevel(), focus: focus)]
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

    /// 深链游戏默认难度（2-3 岁 L1，其余 L2）
    private static func defaultGameLevel() -> Int {
        UserDefaults.standard.string(forKey: "grow.settings.ageMode") == AgeMode.toddler.rawValue ? 1 : 2
    }
    #endif

    // MARK: - 跨 Tab：自然详情页「玩一玩」入口

    /// 从自然对象发起游戏：切换到游戏 Tab 并直达对应游戏页。
    /// 拼一拼 → 定位到包含该内容的拼图（优先已解锁的）；找相同 / 找朋友 → 以该对象为焦点开一局。
    func openNatureGame(natureId: String, game: GameType) {
        let level = SettingsManager.shared.ageMode == .toddler ? 1 : 2
        tab = .games
        switch game {
        case .puzzle:
            let related = PuzzleRepository.shared.puzzles(relatingTo: natureId)
            if let pickable = related.first(where: { ProgressManager.shared.isUnlocked($0.difficulty) }) ?? related.first {
                gamesPath = [.puzzleGame(puzzleId: pickable.id)]
            } else {
                gamesPath = [.puzzleHome]
            }
        case .matching:
            gamesPath = [.matching(level: level, focus: natureId)]
        case .findSame:
            gamesPath = [.findSame(level: level, focus: natureId)]
        default:
            gamesPath = [.home]
        }
    }
}
