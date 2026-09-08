import Foundation
import SwiftUI

// MARK: - 自然内容认知属性（Phase 6.1 Step 4）
//
// 原则（§十九）：属性为可选，不为凑数据乱填。
// 无法明确判断的一律 nil，游戏只调用「有明确属性」的内容。

// MARK: - 颜色

/// 统一颜色定义：全 App 唯一颜色口径，各游戏不得自行定义颜色（§四）
enum ColorDefinition: String, Codable, CaseIterable, Identifiable {
    // 第一阶段
    case red, yellow, blue, green
    // 后续扩展
    case orange, purple, pink, black, white

    var id: String { rawValue }

    /// 儿童端中文名
    var displayName: String {
        switch self {
        case .red: return "红色"
        case .yellow: return "黄色"
        case .blue: return "蓝色"
        case .green: return "绿色"
        case .orange: return "橙色"
        case .purple: return "紫色"
        case .pink: return "粉色"
        case .black: return "黑色"
        case .white: return "白色"
        }
    }

    /// 朗读文本（TTS：「找红色」）
    var spokenName: String { displayName }

    /// 展示色（设计系统统一控制，非各游戏自定义）
    var color: Color {
        switch self {
        case .red: return Color(red: 0.90, green: 0.30, blue: 0.28)
        case .yellow: return Color(red: 0.96, green: 0.79, blue: 0.22)
        case .blue: return Color(red: 0.29, green: 0.55, blue: 0.85)
        case .green: return Color(red: 0.42, green: 0.72, blue: 0.36)
        case .orange: return Color(red: 0.96, green: 0.60, blue: 0.24)
        case .purple: return Color(red: 0.62, green: 0.45, blue: 0.80)
        case .pink: return Color(red: 0.95, green: 0.58, blue: 0.71)
        case .black: return Color(red: 0.25, green: 0.25, blue: 0.27)
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.93)
        }
    }

    /// 第一阶段只上四色（Demo → 验证 → 扩展，§二十七）
    static var phaseOne: [ColorDefinition] { [.red, .yellow, .blue, .green] }

    /// JSON 容错：未知值返回 nil，不影响整条内容解码
    static func from(_ raw: String?) -> ColorDefinition? {
        guard let raw else { return nil }
        return ColorDefinition(rawValue: raw.lowercased())
    }
}

// MARK: - 形状

/// 统一形状定义（§四）。注意：不适合判断形状的内容一律 nil。
enum ShapeDefinition: String, Codable, CaseIterable, Identifiable {
    // 第一阶段
    case circle, square, triangle
    // 后续扩展
    case rectangle, oval, star
    /// 长条形（胡萝卜、香蕉等；非几何严格定义，儿童可辨识即可）
    case long

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circle: return "圆形"
        case .square: return "方形"
        case .triangle: return "三角形"
        case .rectangle: return "长方形"
        case .oval: return "椭圆形"
        case .star: return "星形"
        case .long: return "长长形"
        }
    }

    var spokenName: String { displayName }

    static var phaseOne: [ShapeDefinition] { [.circle, .square, .triangle] }

    /// JSON 容错 + 别名：数据里写 "round" 也认作圆形（§四 苹果 = round）
    static func from(_ raw: String?) -> ShapeDefinition? {
        guard let raw else { return nil }
        let key = raw.lowercased()
        if let direct = ShapeDefinition(rawValue: key) { return direct }
        switch key {
        case "round": return .circle
        case "rect": return .rectangle
        default: return nil
        }
    }
}

// MARK: - 大小

/// 大小档位（仅用于「排一排」大小排序游戏，不代表内容真实尺寸 —— §四）
enum SizeDefinition: String, Codable, CaseIterable, Identifiable, Comparable {
    case small, medium, large

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }

    /// 排序权重（大 > 中 > 小）
    var order: Int {
        switch self {
        case .small: return 0
        case .medium: return 1
        case .large: return 2
        }
    }

    /// 渲染缩放（同一素材生成 大/中/小，不新增图片 —— §二十二）
    var scale: CGFloat {
        switch self {
        case .small: return 0.52
        case .medium: return 0.74
        case .large: return 1.0
        }
    }

    static func < (lhs: SizeDefinition, rhs: SizeDefinition) -> Bool {
        lhs.order < rhs.order
    }

    static func from(_ raw: String?) -> SizeDefinition? {
        guard let raw else { return nil }
        return SizeDefinition(rawValue: raw.lowercased())
    }

    /// 由大到小（第一阶段只做 大 → 小，§十）
    static var descending: [SizeDefinition] { [.large, .medium, .small] }
}

// MARK: - 数量

/// 数量训练区间。第一阶段只支持 1–3（§四：不因认知模块有 0–9 就强推 0–9）
enum CountingRange {
    static let phaseOne = 1...3

    static func resolve(_ raw: [Int]?) -> ClosedRange<Int> {
        guard let raw, raw.count >= 2 else { return phaseOne }
        let lower = min(raw[0], raw[1])
        let upper = max(raw[0], raw[1])
        guard lower >= 1, upper >= lower else { return phaseOne }
        return lower...upper
    }
}
