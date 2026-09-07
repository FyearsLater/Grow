import Foundation

// MARK: - 游戏类型

/// 游戏类型（本期实现前 4 个；后 4 个仅注册，不在首页展示——§主理人裁决 4）
enum GameType: String, Codable, CaseIterable {
    case puzzle                                         // 趣味拼图
    case matching                                       // 配对（详情页入口叫「找朋友」）
    case findSame                                       // 找相同
    case sorting                                        // 分类
    case color, shape, ordering, spotDifference         // 占位（本期不上）

    /// 对应游戏中心图标（GameIcons.GameModule）
    var isPlayable: Bool {
        switch self {
        case .puzzle, .matching, .findSame, .sorting: return true
        case .color, .shape, .ordering, .spotDifference: return false
        }
    }
}

// MARK: - 统一难度口径

/// 统一难度口径：Level 1（2 选项/2 物品/大图/明显区别）→ L2（3-4）→ L3（4-6）
/// 禁止用"速度"加难度；拼图映射 4/9/16 片（§跨文件约定 8）
enum GameDifficultyLevel: Int, Codable, CaseIterable, Identifiable {
    case level1 = 1
    case level2 = 2
    case level3 = 3

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .level1: return "入门"
        case .level2: return "进阶"
        case .level3: return "挑战"
        }
    }

    /// 该档建议选项/物品数（拼图除外）
    var suggestedCount: ClosedRange<Int> {
        switch self {
        case .level1: return 2...2
        case .level2: return 3...4
        case .level3: return 4...6
        }
    }
}

// MARK: - 游戏定义与关卡

/// 游戏定义（games.json 顶层条目）
struct GameDefinition: Codable, Identifiable, Equatable {
    let id: String              // "puzzle" / "matching" / ...
    let type: GameType
    let title: String           // "趣味拼图" / "配对" ...
    /// 设计系统矢量图标名（GameModule），禁止 emoji
    let icon: String
    /// 一句话说明，供副标题与 TTS 开局指令
    let description: String
    let sortOrder: Int
    /// true = 占位禁用（缺省 false；本期首页直接不展示占位——§主理人裁决 4）
    let isPlaceholder: Bool?

    var isPlayable: Bool { !(isPlaceholder ?? false) }

    enum CodingKeys: String, CodingKey {
        case id, type, title, icon, description
        case sortOrder = "sort_order"
        case isPlaceholder = "is_placeholder"
    }
}

/// 分类关卡的两个桶（引用 nature category raw，如 "fruit" / "vegetable"）
struct SortCategoryPair: Codable, Equatable {
    let categoryA: String
    let categoryB: String

    enum CodingKeys: String, CodingKey {
        case categoryA = "category_a"
        case categoryB = "category_b"
    }
}

/// 关卡配置（JSON snake_case，全部可选、按 gameType 取用）
struct GameLevelConfig: Codable, Equatable {
    /// 找相同：选项数 2~6
    var optionCount: Int?
    /// 配对：2~3 组
    var groupCount: Int?
    /// 找相同/分类：一轮页数
    var rounds: Int?
    /// 分类：桶定义
    var categoryPairs: [SortCategoryPair]?
    /// 找相同 L3：干扰项是否仅来自同类别（近似物，差异更小）
    var sameCategoryDistractors: Bool?

    enum CodingKeys: String, CodingKey {
        case optionCount = "option_count"
        case groupCount = "group_count"
        case rounds
        case categoryPairs = "category_pairs"
        case sameCategoryDistractors = "same_category_distractors"
    }

    init(optionCount: Int? = nil, groupCount: Int? = nil, rounds: Int? = nil,
         categoryPairs: [SortCategoryPair]? = nil, sameCategoryDistractors: Bool? = nil) {
        self.optionCount = optionCount
        self.groupCount = groupCount
        self.rounds = rounds
        self.categoryPairs = categoryPairs
        self.sameCategoryDistractors = sameCategoryDistractors
    }
}

/// 游戏关卡：内容复用铁律 —— 只存 nature Content ID 引用（§跨文件约定 2）
struct GameLevel: Codable, Identifiable, Equatable {
    var id: String { "\(gameId)_\(level)" }
    let gameId: String                  // 对应 GameDefinition.id
    let level: Int                      // 1/2/3
    let contentIds: [String]            // 引用 nature.json id
    let configuration: GameLevelConfig  // 该关玩法参数

    var difficulty: GameDifficultyLevel {
        GameDifficultyLevel(rawValue: level) ?? .level1
    }

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case level
        case contentIds = "content_ids"
        case configuration
    }
}

/// games.json 文件包装
struct GameContentFile: Codable {
    let definitions: [GameDefinition]
    let levels: [GameLevel]
}

// MARK: - 会话与结果

/// 一局会话（进入游戏页时构建，退出即释放，不持久化）
struct GameSession {
    let gameId: String
    let type: GameType
    let level: GameDifficultyLevel
    let contentIds: [String]
    let startedAt: Date

    init(gameId: String, type: GameType, level: GameDifficultyLevel, contentIds: [String]) {
        self.gameId = gameId
        self.type = type
        self.level = level
        self.contentIds = contentIds
        self.startedAt = Date()
    }
}

/// 游戏结果（聚合持久化；儿童端只展示"最近探索"，无金币/积分/排名）
struct GameResult: Codable, Equatable {
    let gameId: String
    let level: Int
    var completed: Bool            // 该关是否至少完成过一次
    var playCount: Int
    var completedCount: Int
    var lastPlayedAt: Date?
    var lastCompletedAt: Date?
    /// 最近一次游玩的内容 id（用于"最近探索"解析 nature 名称；可为 nil）
    var lastContentId: String?

    var storageKey: String { "\(gameId)_\(level)" }

    enum CodingKeys: String, CodingKey {
        case gameId = "game_id"
        case level, completed
        case playCount = "play_count"
        case completedCount = "completed_count"
        case lastPlayedAt = "last_played_at"
        case lastCompletedAt = "last_completed_at"
        case lastContentId = "last_content_id"
    }
}
