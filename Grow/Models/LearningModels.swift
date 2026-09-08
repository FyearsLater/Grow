import Foundation

// MARK: - 看图识字：数字

/// 数字条目（0–9）
/// 认知链路：数量 → 阿拉伯数字 → 中文数字 → 声音
struct NumberItem: Codable, Identifiable, Equatable {
    let id: String
    let number: Int
    /// 中文数字，如「三」
    let chineseName: String
    /// 展示"数量"用的图形（emoji），UI 按 number 重复展示
    let imageItems: [String]
    /// 预录音频名（为空则使用系统 TTS 朗读 chineseName）
    let audio: String?
    let sortOrder: Int
    /// JSON 可选：内容适用年龄档（ContentItem，缺省回退）
    let ageLevelRaw: String?
    /// JSON 可选：关联内容 id（ContentItem，缺省为自身）
    let relatedIDs: [String]?

    enum CodingKeys: String, CodingKey {
        case id, number, audio
        case chineseName = "chinese_name"
        case imageItems = "image_items"
        case sortOrder = "sort_order"
        case ageLevelRaw = "age_level"
        case relatedIDs = "related_content_ids"
    }
}

extension NumberItem: ContentItem {
    var kind: ContentKind { .number }
    var displayTitle: String { chineseName }
    var illustrationID: String { imageItems.first ?? "emoji:⭐" }
    var storedAgeLevel: AgeLevel? { ageLevelRaw.flatMap(AgeLevel.init(rawValue:)) }
    var storedRelatedIDs: [String]? { relatedIDs }
}

// MARK: - 看图识字：拼音

/// 拼音类型：声母 / 韵母 / 声调（声调为未来预留，Phase 2 不使用）
enum PinyinType: String, Codable, CaseIterable, Identifiable {
    case initial
    case final
    case tone

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .initial: return "声母"
        case .final: return "韵母"
        case .tone: return "声调"
        }
    }

    var symbol: String {
        switch self {
        case .initial: return "🔵"
        case .final: return "🟢"
        case .tone: return "🟡"
        }
    }
}

/// 拼音条目
/// 认知链路：图片 → 示例词 → 拼音符号 → 发音
struct PinyinItem: Codable, Identifiable, Equatable {
    let id: String
    let type: PinyinType
    /// 拼音符号，如 b / ao
    let symbol: String
    /// 示例词，如「猫」
    let exampleWord: String
    /// 示例词完整拼音（含声调），如 māo
    let exampleWordPinyin: String
    /// 插画标识，复用 IllustrationView（img:xxx / emoji:xxx）
    let image: String
    /// 发音文本：系统 TTS 无法正确朗读裸拼音符号（"b" 会被念成英文字母），
    /// 因此使用汉语拼音的「呼读音」汉字（如 b→玻、a→啊）保证发音准确。
    let speakText: String?
    /// 预录音频名（为空则使用系统 TTS）
    let audio: String?
    let sortOrder: Int
    /// JSON 可选：内容适用年龄档（ContentItem，缺省回退）
    let ageLevelRaw: String?
    /// JSON 可选：关联内容 id（ContentItem，缺省为自身）
    let relatedIDs: [String]?

    /// 实际用于朗读的文本
    var speechContent: String { speakText ?? symbol }

    enum CodingKeys: String, CodingKey {
        case id, type, symbol, image, audio
        case exampleWord = "example_word"
        case exampleWordPinyin = "example_word_pinyin"
        case speakText = "speak_text"
        case sortOrder = "sort_order"
        case ageLevelRaw = "age_level"
        case relatedIDs = "related_content_ids"
    }
}

extension PinyinItem: ContentItem {
    var kind: ContentKind { .pinyin }
    var displayTitle: String { exampleWord }
    var illustrationID: String { image }
    var storedAgeLevel: AgeLevel? { ageLevelRaw.flatMap(AgeLevel.init(rawValue:)) }
    var storedRelatedIDs: [String]? { relatedIDs }
}

// MARK: - 趣味拼图

/// 拼图难度：入门 4 块 / 进阶 9 块 / 挑战 16 块
enum PuzzleDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }

    /// 每行（列）块数
    var grid: Int {
        switch self {
        case .easy: return 2
        case .medium: return 3
        case .hard: return 4
        case .expert: return 5
        }
    }

    var pieceCount: Int { grid * grid }

    var displayName: String {
        switch self {
        case .easy: return "入门"
        case .medium: return "进阶"
        case .hard: return "挑战"
        case .expert: return "大师"
        }
    }

    var symbol: String {
        switch self {
        case .easy: return "🌱"
        case .medium: return "🌿"
        case .hard: return "🌳"
        case .expert: return "🏆"
        }
    }

    /// 解锁前置难度（nil 表示默认解锁）
    var requiredPrevious: PuzzleDifficulty? {
        switch self {
        case .easy: return nil
        case .medium: return .easy
        case .hard: return .medium
        case .expert: return .hard
        }
    }

    /// 游戏中心统一难度口径（4/9/16/25 片 → L1/L2/L3/L4，仅用于展示与游戏结果记录）
    var gameLevel: GameDifficultyLevel {
        switch self {
        case .easy: return .level1
        case .medium: return .level2
        case .hard: return .level3
        case .expert: return .level4
        }
    }
}

/// 拼图条目
/// 注意：只保存一张 720×720 原图，切片在运行时由 PuzzleEngine 生成，不落盘。
struct PuzzleItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let category: String
    /// 拼图原图标识（复用 IllustrationView 的 img: 前缀，720×720）
    let image: String
    let difficulty: PuzzleDifficulty
    let pieceCount: Int
    /// 关联的自然认知条目 id，用于完成后「认识一下」跳转
    let sourceNatureItemId: String?
    let sortOrder: Int
    /// JSON 可选：内容适用年龄档（ContentItem，缺省回退）
    let ageLevelRaw: String?
    /// JSON 可选：关联内容 id（ContentItem，缺省由 sourceNatureItemId 派生）
    let relatedIDs: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, category, image, difficulty
        case pieceCount = "piece_count"
        case sourceNatureItemId = "source_nature_item_id"
        case sortOrder = "sort_order"
        case ageLevelRaw = "age_level"
        case relatedIDs = "related_content_ids"
    }
}

extension PuzzleItem: ContentItem {
    var kind: ContentKind { .puzzle }
    var displayTitle: String { title }
    var illustrationID: String { image }
    var storedAgeLevel: AgeLevel? { ageLevelRaw.flatMap(AgeLevel.init(rawValue:)) }
    var storedRelatedIDs: [String]? { relatedIDs }
    /// 缺省关联：对应的自然认知条目（§25 内容关联）
    var relatedContentIDs: [String] {
        if let ids = storedRelatedIDs { return ids }
        return sourceNatureItemId.map { [$0] } ?? []
    }
}

/// 拼图进度
struct PuzzleProgress: Codable, Identifiable, Equatable {
    let puzzleId: String
    var completed: Bool
    var completedCount: Int
    var lastPlayed: Date?
    var bestTime: TimeInterval?

    var id: String { puzzleId }

    enum CodingKeys: String, CodingKey {
        case puzzleId = "puzzle_id"
        case completed
        case completedCount = "completed_count"
        case lastPlayed = "last_played"
        case bestTime = "best_time"
    }

    init(puzzleId: String,
         completed: Bool = false,
         completedCount: Int = 0,
         lastPlayed: Date? = nil,
         bestTime: TimeInterval? = nil) {
        self.puzzleId = puzzleId
        self.completed = completed
        self.completedCount = completedCount
        self.lastPlayed = lastPlayed
        self.bestTime = bestTime
    }
}

// MARK: - 内容文件包装

struct NumberContentFile: Codable { let items: [NumberItem] }
struct PinyinContentFile: Codable { let items: [PinyinItem] }
struct PuzzleContentFile: Codable { let items: [PuzzleItem] }
