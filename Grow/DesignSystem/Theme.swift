import SwiftUI

/// 统一色彩系统：米白底 + 各分类辅助色（辅助识别，不喧宾夺主）
enum Theme {
    // 基础底色
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.93)        // 米白
    static let creamDeep = Color(red: 0.96, green: 0.93, blue: 0.87)    // 奶油白（卡片底）

    // 文字
    static let ink = Color(red: 0.22, green: 0.24, blue: 0.26)          // 主文字（深灰）
    static let inkSoft = Color(red: 0.45, green: 0.48, blue: 0.50)      // 次级文字

    // 分类辅助色
    static let fruit = Color(red: 0.96, green: 0.65, blue: 0.36)        // 暖橙
    static let vegetable = Color(red: 0.49, green: 0.72, blue: 0.42)    // 绿
    static let animal = Color(red: 0.44, green: 0.66, blue: 0.86)       // 天空蓝
    static let plant = Color(red: 0.56, green: 0.50, blue: 0.78)        // 浅紫

    // 古诗
    static let poemAccent = Color(red: 0.42, green: 0.48, blue: 0.40)   // 墨绿
    static let poemWarm = Color(red: 0.72, green: 0.58, blue: 0.44)     // 暖棕
    static let poemPaper = Color(red: 0.97, green: 0.95, blue: 0.90)    // 宣纸色

    // 模块柔和主题色（低饱和，§3：颜色由设计系统统一控制）
    static let softGreen = Color(red: 0.67, green: 0.82, blue: 0.66)   // 自然世界
    static let softSand  = Color(red: 0.89, green: 0.82, blue: 0.70)   // 古诗小世界
    static let softBlue  = Color(red: 0.65, green: 0.78, blue: 0.89)   // 看图识字
    static let softLilac = Color(red: 0.79, green: 0.73, blue: 0.88)   // 拼图世界

    // 模块深色（图标内容 / 强调，低饱和）
    static let deepGreen = Color(red: 0.35, green: 0.54, blue: 0.38)
    static let deepSand  = Color(red: 0.63, green: 0.50, blue: 0.35)
    static let deepBlue  = Color(red: 0.32, green: 0.50, blue: 0.68)
    static let deepLilac = Color(red: 0.51, green: 0.43, blue: 0.67)

    // 首页背景：极轻渐变，营造空间感（§13）
    static let homeBgTop    = Color(red: 0.99, green: 0.98, blue: 0.95)
    static let homeBgBottom = Color(red: 0.93, green: 0.95, blue: 0.94)

    // 功能色
    static let heart = Color(red: 0.92, green: 0.45, blue: 0.45)        // 收藏红

    // MARK: - 语义颜色（§20：新代码统一使用语义名，旧色名保留兼容）

    static let background = cream                                          // 页面背景
    static let surface = Color.white.opacity(0.7)                          // 卡片面
    static let textPrimary = ink                                           // 主文字
    static let textSecondary = inkSoft                                     // 次级文字
    static let success = vegetable                                         // 成功 / 辅助提示
    static let destructive = heart                                         // 破坏性 / 取消收藏
    static let glassHighlight = Color.white.opacity(0.55)                  // 玻璃高光描边
    static let glassTint = Color.white.opacity(0.4)                        // 玻璃顶部高光

    static func categoryColor(_ c: NatureCategory) -> Color {
        switch c {
        case .fruit: return fruit
        case .vegetable: return vegetable
        case .animal: return animal
        case .plant: return plant
        }
    }

    // MARK: - 字号系统（跟随设置档位）

    static func scaled(_ size: CGFloat, settings: SettingsManager) -> CGFloat {
        size * settings.fontScaleFactor * settings.pageScaleFactor
    }
}

// MARK: - 四级字体系统（§9：Title / Subtitle / Body / Caption）
//
// 原则：儿童 App 不等于粗黑体。圆润（rounded）、中等偏轻字重，
// 标题与说明形成明显层级；全部跟随设置档位缩放。

enum GrowFont {
    /// Title：页面主标题（Grow Logo / 大标题）
    static func title(_ settings: SettingsManager) -> Font {
        .system(size: Theme.scaled(30, settings: settings), weight: .semibold, design: .rounded)
    }

    /// 区块 / 卡片标题
    static func heading(_ settings: SettingsManager) -> Font {
        .system(size: Theme.scaled(18, settings: settings), weight: .semibold, design: .rounded)
    }

    /// Body：正文 / 主要操作文字
    static func body(_ settings: SettingsManager) -> Font {
        .system(size: Theme.scaled(16, settings: settings), weight: .medium)
    }

    /// Subtitle：副标题、一句话说明
    static func subtitle(_ settings: SettingsManager) -> Font {
        .system(size: Theme.scaled(14, settings: settings), weight: .regular)
    }

    /// Caption：辅助说明、最轻一档
    static func caption(_ settings: SettingsManager) -> Font {
        .system(size: Theme.scaled(12.5, settings: settings), weight: .regular)
    }
}

// MARK: - 儿童友好的点击反馈：轻微缩放弹性动画

struct PressableButtonStyle: ButtonStyle {
    var settings: SettingsManager = .shared

    /// 关闭动画时仍保留必要的按压反馈（只变色不缩放）
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && settings.animationOn ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(reduceMotionAnimation, value: configuration.isPressed)
    }

    private var reduceMotionAnimation: Animation? {
        settings.reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.55)
    }
}

// MARK: - 卡片样式

struct GrowCardStyle: ViewModifier {
    var fill: Color = Theme.creamDeep
    var radius: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}

extension View {
    func growCard(fill: Color = Theme.creamDeep, radius: CGFloat = 28) -> some View {
        modifier(GrowCardStyle(fill: fill, radius: radius))
    }
}
