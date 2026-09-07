import SwiftUI

// MARK: - 游戏统一视觉符号（§7 约定 6：游戏图标全部在 GameModule 注册，禁止 Emoji）

/// 游戏模块注册表：图标 / 标题 / 柔和染色，全部走 Theme soft* 色板
enum GameModule {
    case puzzle       // 趣味拼图
    case matching     // 配对
    case findSame     // 找相同
    case sorting      // 分类
    case locked       // 敬请期待占位

    var title: String {
        switch self {
        case .puzzle: return "趣味拼图"
        case .matching: return "配对"
        case .findSame: return "找相同"
        case .sorting: return "分一分"
        case .locked: return "敬请期待"
        }
    }

    /// 卡片轻染主题色（柔和）
    var tint: Color {
        switch self {
        case .puzzle: return Theme.softLilac
        case .matching: return Theme.softGreen
        case .findSame: return Theme.softBlue
        case .sorting: return Theme.softSand
        case .locked: return Theme.creamDeep
        }
    }

    /// 图标主体深色
    var deepTint: Color {
        switch self {
        case .puzzle: return Theme.deepLilac
        case .matching: return Theme.deepGreen
        case .findSame: return Theme.deepBlue
        case .sorting: return Theme.deepSand
        case .locked: return Theme.inkSoft
        }
    }

    /// GameType → GameModule（数据层 → 视觉层唯一映射）
    static func from(_ type: GameType) -> GameModule {
        switch type {
        case .puzzle: return .puzzle
        case .matching: return .matching
        case .findSame: return .findSame
        case .sorting: return .sorting
        default: return .locked
        }
    }
}

// MARK: - 统一图标视图

/// 游戏图标：squircle 柔光底 + Soft 3D 内容（与 ModuleIconView 同一视觉系统）
struct GameModuleIcon: View {
    let module: GameModule
    var size: CGFloat = 56

    var body: some View {
        SoftIconContainer(tint: module.tint, size: size) {
            switch module {
            case .puzzle:
                PuzzleGlyph(deep: module.deepTint, light: module.tint)
            case .matching:
                MatchingGlyph(deep: module.deepTint, light: module.tint)
            case .findSame:
                FindSameGlyph(deep: module.deepTint, light: module.tint)
            case .sorting:
                SortingGlyph(deep: module.deepTint, light: module.tint)
            case .locked:
                LockedGlyph(deep: module.deepTint)
            }
        }
    }
}

// MARK: - 配对：两张翻扣的小卡（一深一浅微旋相叠）

struct MatchingGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 后面一张（浅色，微旋）
                RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                    .fill(LinearGradient(colors: [.white.opacity(0.95), light.opacity(0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                        .stroke(.white.opacity(0.8), lineWidth: 1.5))
                    .frame(width: w * 0.52, height: w * 0.52)
                    .rotationEffect(.degrees(12))
                    .offset(x: w * 0.14, y: w * 0.14)

                // 前面一张（深色 Soft 3D）
                ZStack {
                    RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                        .fill(LinearGradient(colors: [deep, deep.opacity(0.75)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    // 卡面问号点（两个小圆点示意"翻面找朋友"）
                    HStack(spacing: w * 0.05) {
                        Circle().fill(.white.opacity(0.85)).frame(width: w * 0.09)
                        Circle().fill(.white.opacity(0.85)).frame(width: w * 0.09)
                    }
                }
                .frame(width: w * 0.54, height: w * 0.54)
                .rotationEffect(.degrees(-8))
                .offset(x: -w * 0.10, y: -w * 0.10)
                .shadow(color: deep.opacity(0.28), radius: w * 0.05, y: w * 0.035)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - 找相同：两个一样的圆 + 对勾徽标

struct FindSameGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 左圆（浅）
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.95), light.opacity(0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.42)
                    .offset(x: -w * 0.20, y: w * 0.04)

                // 右圆（深，与左圆同样大小——"一样"）
                Circle()
                    .fill(LinearGradient(colors: [deep, deep.opacity(0.75)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.42)
                    .offset(x: w * 0.12, y: -w * 0.02)
                    .shadow(color: deep.opacity(0.26), radius: w * 0.05, y: w * 0.03)

                // 对勾徽标
                Circle()
                    .fill(.white)
                    .frame(width: w * 0.26)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: w * 0.14, weight: .bold))
                            .foregroundStyle(deep)
                    )
                    .offset(x: w * 0.26, y: -w * 0.30)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - 分类：两个小筐 + 落入的小物

struct SortingGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 上方两个待分类的小物
                Circle()
                    .fill(LinearGradient(colors: [.white.opacity(0.95), light.opacity(0.9)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.20)
                    .offset(x: -w * 0.13, y: -w * 0.28)
                Capsule()
                    .fill(LinearGradient(colors: [deep, deep.opacity(0.78)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.24, height: w * 0.13)
                    .rotationEffect(.degrees(-14))
                    .offset(x: w * 0.14, y: -w * 0.26)

                // 两个小筐
                bin(x: -w * 0.19, deep: deep, light: light, w: w)
                bin(x: w * 0.19, deep: deep, light: light, w: w)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func bin(x: CGFloat, deep: Color, light: Color, w: CGFloat) -> some View {
        ZStack {
            // 筐身（梯形感：上宽下窄用两个圆角矩形叠出）
            RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                .fill(LinearGradient(colors: [deep.opacity(0.85), deep.opacity(0.6)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.34, height: w * 0.30)
            // 筐口
            RoundedRectangle(cornerRadius: w * 0.04, style: .continuous)
                .fill(light.opacity(0.9))
                .frame(width: w * 0.38, height: w * 0.10)
                .offset(y: -w * 0.17)
        }
        .offset(x: x, y: w * 0.20)
    }
}

// MARK: - 敬请期待：三点省略号（柔和，不做"禁止"感）

struct LockedGlyph: View {
    let deep: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            HStack(spacing: w * 0.10) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(LinearGradient(colors: [deep.opacity(0.75), deep.opacity(0.5)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.14)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
