import Foundation

// MARK: - Content 统一基础模型（§21 / §24 / §25）

/// 内容种类
enum ContentKind: String, Codable {
    case nature     // 自然认知
    case poem       // 古诗
    case number     // 数字
    case pinyin     // 拼音
    case puzzle     // 拼图
}

/// 年龄体系（§24）：数据结构就绪，本阶段不做推荐算法
enum AgeLevel: String, Codable, CaseIterable {
    case age23      // 2–3 岁
    case age34      // 3–4 岁
    case age45      // 4–5 岁
    case age56      // 5–6 岁

    var displayName: String {
        switch self {
        case .age23: return "2–3 岁"
        case .age34: return "3–4 岁"
        case .age45: return "4–5 岁"
        case .age56: return "5–6 岁"
        }
    }
}

/// 统一内容协议：让同一内容可被多个能力模块重复利用（未来路线核心）
/// 同一内容未来将贯穿：探索世界 / 语言启蒙 / 数学认知 / 动手探索 / 创意乐园。
protocol ContentItem: Identifiable, Codable {
    var id: String { get }
    var kind: ContentKind { get }
    var displayTitle: String { get }
    /// 插画标识（img: / emoji: / 矢量名）
    var illustrationID: String { get }
    /// JSON 可选字段 age_level，缺省回退默认值
    var storedAgeLevel: AgeLevel? { get }
    /// JSON 可选字段 related_content_ids，缺省回退派生值
    var storedRelatedIDs: [String]? { get }
}

extension ContentItem {
    /// 内容适用的年龄档（缺省 3–4 岁）
    var ageLevel: AgeLevel { storedAgeLevel ?? .age34 }

    /// 内容关联（§25）：缺省为空，由各模型或 Repository 派生
    var relatedContentIDs: [String] { storedRelatedIDs ?? [] }
}
