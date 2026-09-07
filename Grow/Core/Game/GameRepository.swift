import Foundation

/// 游戏仓库：加载 games.json（注册表 + 关卡），并把 contentIds 解析为 NatureItem。
/// 内容唯一来源是 nature.json —— 本仓库只做引用与查询，不复制内容（§内容复用铁律）。
final class GameRepository: ObservableObject {
    static let shared = GameRepository()

    @Published private(set) var definitions: [GameDefinition] = []
    @Published private(set) var levels: [GameLevel] = []

    private init() {
        let file = JSONLoader.load("games", as: GameContentFile.self)
        definitions = (file?.definitions ?? []).sorted { $0.sortOrder < $1.sortOrder }
        levels = file?.levels ?? []
        #if DEBUG
        print("[GameRepository] definitions=\(definitions.count) levels=\(levels.count)")
        #endif
    }

    // MARK: - 定义查询

    func definition(ofType type: GameType) -> GameDefinition? {
        definitions.first { $0.type == type }
    }

    /// 可玩游戏（首页 2×2 大卡，按 sort_order）
    var playableDefinitions: [GameDefinition] {
        definitions.filter { $0.isPlayable }
    }

    // MARK: - 关卡查询

    /// 某游戏的全部关卡（按 level 升序）
    func levels(of type: GameType) -> [GameLevel] {
        guard let def = definition(ofType: type) else { return [] }
        return levels
            .filter { $0.gameId == def.id }
            .sorted { $0.level < $1.level }
    }

    func level(gameId: String, level: Int) -> GameLevel? {
        levels.first { $0.gameId == gameId && $0.level == level }
    }

    /// 按年龄模式给出的默认难度：2-3 岁默认 L1（§衔接 SettingsManager）
    func defaultLevel(of type: GameType) -> Int {
        let preferred = SettingsManager.shared.ageMode == .toddler ? 1 : 2
        let available = levels(of: type).map(\.level)
        return available.contains(preferred) ? preferred : (available.min() ?? 1)
    }

    // MARK: - 内容解析（引用 nature.json，不复制）

    func natureItems(for contentIds: [String]) -> [NatureItem] {
        let all = ContentRepository.shared.natureItems
        return contentIds.compactMap { id in all.first { $0.id == id } }
    }

    func natureItem(id: String) -> NatureItem? {
        ContentRepository.shared.natureItems.first { $0.id == id }
    }

    /// 某分类的全部自然对象（供找相同干扰项 / 分类游戏按桶取物）
    func items(in category: NatureCategory) -> [NatureItem] {
        ContentRepository.shared.items(in: category)
    }

    /// 深链/详情页入口使用的默认关卡
    func defaultLevelRoute(type: GameType, focus: String?) -> (level: Int, focus: String?) {
        (defaultLevel(of: type), focus)
    }
}
