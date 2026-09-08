import Foundation

// MARK: - 自然认知

enum NatureCategory: String, Codable, CaseIterable, Identifiable {
    case fruit      // 水果
    case vegetable  // 蔬菜
    case animal     // 动物
    case plant      // 植物

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fruit: return "水果"
        case .vegetable: return "蔬菜"
        case .animal: return "动物"
        case .plant: return "植物"
        }
    }

    var symbol: String {
        switch self {
        case .fruit: return "🍎"
        case .vegetable: return "🥦"
        case .animal: return "🐼"
        case .plant: return "🌱"
        }
    }
}

/// 自然认知对象（水果 / 蔬菜 / 动物 / 植物）
struct NatureItem: Codable, Identifiable, Equatable {
    let id: String
    let category: NatureCategory
    let nameZh: String
    let nameEn: String
    /// 2-4 岁版本简介（1-3 句）
    let descriptionShort: String
    /// 4-6 岁版本简介（3-5 句）
    let descriptionLong: String
    /// 音频资源名（MVP 阶段为空则使用系统 TTS）
    let mandarinAudio: String?
    let cantoneseAudio: String?
    let englishAudio: String?
    /// 插画类型（程序化插画标识）
    let illustration: String
    var sortOrder: Int
    /// JSON 可选：内容适用年龄档（ContentItem，缺省回退）
    let ageLevelRaw: String?
    /// JSON 可选：关联内容 id（ContentItem，缺省由 Repository 派生）
    let relatedIDs: [String]?

    // MARK: Phase 6.1 认知属性（全部可选；无法判断的填 nil —— §十九）
    /// 颜色（统一 ColorDefinition）
    let color: ColorDefinition?
    /// 形状（统一 ShapeDefinition）
    let shape: ShapeDefinition?
    /// 大小档位（仅大小排序用，不代表真实尺寸）
    let size: SizeDefinition?
    /// 是否可用于「数一数」数量游戏
    let countingAvailable: Bool?
    /// 数量训练区间 [min, max]，缺省 1–3
    let countingRange: [Int]?
    /// 是否支持「排一排」大小排序游戏（同一素材生成大/中/小，不新增图片）
    let sizeGameSupported: Bool?
    /// 游戏标签（供 GameContentResolver 过滤，如 "counting" / "sorting"）
    let gameTags: [String]?

    enum CodingKeys: String, CodingKey {
        case id, category, illustration
        case nameZh = "name_zh"
        case nameEn = "name_en"
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case mandarinAudio = "mandarin_audio"
        case cantoneseAudio = "cantonese_audio"
        case englishAudio = "english_audio"
        case sortOrder = "sort_order"
        case ageLevelRaw = "age_level"
        case relatedIDs = "related_content_ids"
        case color, shape, size
        case countingAvailable = "counting_available"
        case countingRange = "counting_range"
        case sizeGameSupported = "size_game_supported"
        case gameTags = "game_tags"
    }

    // MARK: 容错解码（§十九：无法明确判断的属性一律 nil，单条脏数据不拖垮整文件）
    //
    // 关键点：color/shape/size 是枚举，若 JSON 写了非法原始值（如 "brown"/"round"），
    // 合成的可选解码会向下抛出，导致整条 NatureItem 解码失败 → 整份 nature.json 解码失败 → 全模块清空。
    // 这里用 .from(_:) 容错助手（未知值返回 nil、round→circle），保证单条脏数据不会污染整文件。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        category = try c.decode(NatureCategory.self, forKey: .category)
        nameZh = try c.decode(String.self, forKey: .nameZh)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        descriptionShort = try c.decode(String.self, forKey: .descriptionShort)
        descriptionLong = try c.decode(String.self, forKey: .descriptionLong)
        illustration = try c.decode(String.self, forKey: .illustration)
        sortOrder = try c.decode(Int.self, forKey: .sortOrder)
        mandarinAudio = try c.decodeIfPresent(String.self, forKey: .mandarinAudio)
        cantoneseAudio = try c.decodeIfPresent(String.self, forKey: .cantoneseAudio)
        englishAudio = try c.decodeIfPresent(String.self, forKey: .englishAudio)
        ageLevelRaw = try c.decodeIfPresent(String.self, forKey: .ageLevelRaw)
        relatedIDs = try c.decodeIfPresent([String].self, forKey: .relatedIDs)
        color = ColorDefinition.from(try c.decodeIfPresent(String.self, forKey: .color))
        shape = ShapeDefinition.from(try c.decodeIfPresent(String.self, forKey: .shape))
        size = SizeDefinition.from(try c.decodeIfPresent(String.self, forKey: .size))
        countingAvailable = try c.decodeIfPresent(Bool.self, forKey: .countingAvailable)
        countingRange = try c.decodeIfPresent([Int].self, forKey: .countingRange)
        sizeGameSupported = try c.decodeIfPresent(Bool.self, forKey: .sizeGameSupported)
        gameTags = try c.decodeIfPresent([String].self, forKey: .gameTags)
    }
}

// MARK: - 认知属性便捷读取

extension NatureItem {
    /// 是否可参与数量游戏（缺省 false）
    var supportsCounting: Bool { countingAvailable ?? false }

    /// 数量训练区间（缺省 1–3）
    var countingBounds: ClosedRange<Int> { CountingRange.resolve(countingRange) }

    /// 是否可参与大小排序游戏（缺省 false）
    var supportsSizeGame: Bool { sizeGameSupported ?? false }

    /// 是否带指定游戏标签
    func hasGameTag(_ tag: String) -> Bool {
        gameTags?.contains(tag) ?? false
    }
}

// MARK: - ContentItem 协议实现（§21）

extension NatureItem: ContentItem {
    var kind: ContentKind { .nature }
    var displayTitle: String { nameZh }
    var illustrationID: String { illustration }
    var storedAgeLevel: AgeLevel? { ageLevelRaw.flatMap(AgeLevel.init(rawValue:)) }
    var storedRelatedIDs: [String]? { relatedIDs }
}

// MARK: - 古诗

/// 古诗分类
enum PoemCategory: String, Codable, CaseIterable, Identifiable {
    case spring = "spring"      // 春天
    case summer = "summer"      // 夏天
    case autumn = "autumn"      // 秋天
    case winter = "winter"      // 冬天
    case night = "night"        // 夜晚
    case nature = "nature"      // 自然
    case family = "family"      // 亲情
    case daily = "daily"        // 日常
    case river = "river"        // 江河
    case lake = "lake"          // 湖泊
    case mountain = "mountain"  // 山川
    case festival = "festival"  // 节日
    case history = "history"    // 历史

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spring: return "春天"
        case .summer: return "夏天"
        case .autumn: return "秋天"
        case .winter: return "冬天"
        case .night: return "夜晚"
        case .nature: return "自然"
        case .family: return "亲情"
        case .daily: return "日常"
        case .river: return "江河"
        case .lake: return "湖泊"
        case .mountain: return "山川"
        case .festival: return "节日"
        case .history: return "历史"
        }
    }

    var symbol: String {
        switch self {
        case .spring: return "🌸"
        case .summer: return "☀️"
        case .autumn: return "🍂"
        case .winter: return "❄️"
        case .night: return "🌙"
        case .nature: return "🌿"
        case .family: return "👨‍👩‍👧"
        case .daily: return "🎈"
        case .river: return "🏞️"
        case .lake: return "🌊"
        case .mountain: return "⛰️"
        case .festival: return "🎊"
        case .history: return "🏰"
        }
    }
}

/// 单句（含拼音），供逐句朗读使用
struct PoemLine: Codable, Identifiable, Equatable {
    var id: String { "\(poemId)-\(order)" }
    let poemId: String
    let order: Int
    let text: String
    let pinyin: String

    enum CodingKeys: String, CodingKey {
        case poemId = "poem_id"
        case order, text, pinyin
    }
}

/// 注释（每条 10-30 字）
struct Annotation: Codable, Identifiable, Equatable {
    var id: String { "\(poemId)-\(target)" }
    let poemId: String
    let target: String
    let explanation: String

    enum CodingKeys: String, CodingKey {
        case poemId = "poem_id"
        case target, explanation
    }
}

/// 古诗
struct Poem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let author: String
    let dynasty: String
    let categories: [PoemCategory]
    /// 插画类型（程序化插画标识）
    let illustration: String
    let lines: [PoemLine]
    let annotations: [Annotation]
    /// 👀 小朋友可以这样理解
    let kidSummary: String
    var sortOrder: Int
    /// JSON 可选：内容适用年龄档（ContentItem，缺省回退）
    let ageLevelRaw: String?
    /// JSON 可选：关联内容 id（ContentItem，缺省由 Repository 派生）
    let relatedIDs: [String]?

    enum CodingKeys: String, CodingKey {
        case id, title, author, dynasty, categories, illustration, lines, annotations
        case kidSummary = "kid_summary"
        case sortOrder = "sort_order"
        case ageLevelRaw = "age_level"
        case relatedIDs = "related_content_ids"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        author = try c.decode(String.self, forKey: .author)
        dynasty = try c.decode(String.self, forKey: .dynasty)
        illustration = try c.decode(String.self, forKey: .illustration)
        lines = try c.decode([PoemLine].self, forKey: .lines)
        annotations = try c.decode([Annotation].self, forKey: .annotations)
        kidSummary = try c.decode(String.self, forKey: .kidSummary)
        sortOrder = try c.decode(Int.self, forKey: .sortOrder)
        ageLevelRaw = try c.decodeIfPresent(String.self, forKey: .ageLevelRaw)
        relatedIDs = try c.decodeIfPresent([String].self, forKey: .relatedIDs)
        // 分类容错：遇到未知分类（如以后新增）只跳过该项，不让整首诗/整个文件解码失败
        let rawCategories = try c.decode([String].self, forKey: .categories)
        categories = rawCategories.compactMap(PoemCategory.init(rawValue:))
    }

    init(id: String, title: String, author: String, dynasty: String, categories: [PoemCategory],
         illustration: String, lines: [PoemLine], annotations: [Annotation], kidSummary: String, sortOrder: Int) {
        self.id = id
        self.title = title
        self.author = author
        self.dynasty = dynasty
        self.categories = categories
        self.illustration = illustration
        self.lines = lines
        self.annotations = annotations
        self.kidSummary = kidSummary
        self.sortOrder = sortOrder
        self.ageLevelRaw = nil
        self.relatedIDs = nil
    }

    /// 整首正文（用于整首朗读的 range 映射）
    var fullText: String { lines.map(\.text).joined(separator: "\n") }
}

// MARK: - ContentItem 协议实现（§21）

extension Poem: ContentItem {
    var kind: ContentKind { .poem }
    var displayTitle: String { title }
    var illustrationID: String { illustration }
    var storedAgeLevel: AgeLevel? { ageLevelRaw.flatMap(AgeLevel.init(rawValue:)) }
    var storedRelatedIDs: [String]? { relatedIDs }
}

// MARK: - 内容包

struct NatureContentFile: Codable {
    let items: [NatureItem]
}

struct PoemContentFile: Codable {
    let poems: [Poem]
}
