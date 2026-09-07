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

    // 功能色
    static let heart = Color(red: 0.92, green: 0.45, blue: 0.45)        // 收藏红

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
