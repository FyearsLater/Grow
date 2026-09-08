import Foundation

// MARK: - 游戏内容解析中枢（Phase 6.1 Step 5）
//
// 铁律（§六）：Content 是唯一内容母库。
// 任何游戏都通过本解析器取内容，禁止：
//   · 游戏自己维护图片数组
//   · 为同一个内容建多份副本（apple_nature / apple_puzzle / apple_color）
// 以后新增自然内容，只要补好认知属性，就自动进入对应小游戏（§十四）。

final class GameContentResolver {
    static let shared = GameContentResolver()

    private init() {}

    // MARK: - 主入口

    /// 取适合该游戏的内容池（已按认知属性过滤，池中内容一定能玩该游戏）
    func getContents(for type: GameType) -> [NatureItem] {
        switch type {
        case .puzzle, .matching, .findSame, .sorting, .spotDifference:
            // 不依赖额外认知属性，全部自然内容可参与
            return allItems
        case .color:
            return allItems.filter { $0.color != nil }
        case .shape:
            return allItems.filter { $0.shape != nil }
        case .ordering:
            return allItems.filter { $0.supportsSizeGame }
        case .counting:
            return allItems.filter { $0.supportsCounting }
        }
    }

    /// 按难度取内容（难度只影响「数量」，不影响内容合法性）
    func getContents(for type: GameType, level: GameDifficultyLevel) -> [NatureItem] {
        getContents(for: type)
    }

    // MARK: - 属性查询（供各游戏引擎按需取子集）

    /// 指定颜色的全部内容
    func contents(withColor color: ColorDefinition) -> [NatureItem] {
        allItems.filter { $0.color == color }
    }

    /// 指定形状的全部内容
    func contents(withShape shape: ShapeDefinition) -> [NatureItem] {
        allItems.filter { $0.shape == shape }
    }

    /// 当前有内容支撑的颜色（按第一阶段四色优先，不足则补充扩展色）
    /// - Parameter minimum: 至少需要的内容数（保证游戏能凑够选项）
    func availableColors(minimum: Int = 1) -> [ColorDefinition] {
        let phaseOne = ColorDefinition.phaseOne.filter { contents(withColor: $0).count >= minimum }
        guard phaseOne.count >= 2 else {
            // 数据不足时放宽到全部已定义颜色
            return ColorDefinition.allCases.filter { contents(withColor: $0).count >= minimum }
        }
        return phaseOne
    }

    /// 当前有内容支撑的形状
    func availableShapes(minimum: Int = 1) -> [ShapeDefinition] {
        let phaseOne = ShapeDefinition.phaseOne.filter { contents(withShape: $0).count >= minimum }
        guard phaseOne.count >= 2 else {
            return ShapeDefinition.allCases.filter { contents(withShape: $0).count >= minimum }
        }
        return phaseOne
    }

    // MARK: - 单内容能力判断（§七「玩一玩」动态化）

    /// 该内容是否可以玩这个游戏
    func supports(_ type: GameType, item: NatureItem) -> Bool {
        switch type {
        case .puzzle:
            return PuzzleRepository.shared.puzzles(relatingTo: item.id).isEmpty == false
        case .matching, .findSame, .sorting, .spotDifference:
            return true
        case .color:
            return item.color != nil
        case .shape:
            return item.shape != nil
        case .ordering:
            return item.supportsSizeGame
        case .counting:
            return item.supportsCounting
        }
    }

    /// 详情页「玩一玩」动态列表：按内容属性自动决定显示哪些游戏（§七）
    /// 顺序：拼图 → 找相同 → 配对 → 分类 → 找颜色 → 找形状 → 排一排 → 数一数 → 找不同
    func supportedGames(for item: NatureItem) -> [GameType] {
        [GameType.puzzle, .findSame, .matching, .sorting,
         .color, .shape, .ordering, .counting, .spotDifference]
            .filter { supports($0, item: item) }
    }

    // MARK: - 私有

    private var allItems: [NatureItem] { ContentRepository.shared.natureItems }
}
