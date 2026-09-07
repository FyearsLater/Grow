import SwiftUI

// MARK: - 设计 Token：间距 / 圆角 / 阴影 / 动画（§17 / §19）

/// 间距系统
enum GrowSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 20
    static let xl: CGFloat = 24
}

/// 圆角系统
enum GrowRadius {
    static let chip: CGFloat = 22
    static let card: CGFloat = 28
    static let sheet: CGFloat = 32
    static let icon: CGFloat = 26
}

/// 动画系统：动画服务于反馈，而不是装饰（§19）
/// 全部经过 Reduce Motion / 动画开关门控。
enum GrowAnimation {
    /// 按压反馈
    static func press(_ settings: SettingsManager) -> Animation? {
        guard settings.animationOn, !settings.reduceMotion else { return nil }
        return .spring(response: 0.28, dampingFraction: 0.55)
    }

    /// 页面内容进入
    static func appear(_ settings: SettingsManager) -> Animation? {
        guard settings.animationOn, !settings.reduceMotion else { return nil }
        return .easeOut(duration: 0.35)
    }

    /// 卡片 / 折叠展开
    static func card(_ settings: SettingsManager) -> Animation? {
        guard settings.animationOn, !settings.reduceMotion else { return nil }
        return .spring(response: 0.35, dampingFraction: 0.8)
    }

    /// 完成时刻
    static func complete(_ settings: SettingsManager) -> Animation? {
        guard settings.animationOn, !settings.reduceMotion else { return nil }
        return .spring(response: 0.5, dampingFraction: 0.6)
    }
}
