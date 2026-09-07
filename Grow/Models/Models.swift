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
    }
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

    enum CodingKeys: String, CodingKey {
        case id, title, author, dynasty, categories, illustration, lines, annotations
        case kidSummary = "kid_summary"
        case sortOrder = "sort_order"
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
    }

    /// 整首正文（用于整首朗读的 range 映射）
    var fullText: String { lines.map(\.text).joined(separator: "\n") }
}

// MARK: - 内容包

struct NatureContentFile: Codable {
    let items: [NatureItem]
}

struct PoemContentFile: Codable {
    let poems: [Poem]
}
