import SwiftUI

// MARK: - 游戏统一视觉符号（§7 约定 6：游戏图标全部在 GameModule 注册，禁止 Emoji）

/// 游戏模块注册表：图标 / 标题 / 柔和染色，全部走 Theme soft* 色板
enum GameModule {
    case puzzle       // 趣味拼图
    case matching     // 配对
    case findSame     // 找相同
    case sorting      // 分类
    // Phase 6.1 新增
    case color        // 找颜色
    case shape        // 找形状
    case ordering     // 排一排（大小排序）
    case counting     // 数一数
    case spotDifference // 找不同
    case locked       // 敬请期待占位

    var title: String {
        switch self {
        case .puzzle: return "趣味拼图"
        case .matching: return "配对"
        case .findSame: return "找相同"
        case .sorting: return "分一分"
        case .color: return "找颜色"
        case .shape: return "找形状"
        case .ordering: return "排一排"
        case .counting: return "数一数"
        case .spotDifference: return "找不同"
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
        case .color: return Theme.softCoral
        case .shape: return Theme.softTeal
        case .ordering: return Theme.softAmber
        case .counting: return Theme.softPlum
        case .spotDifference: return Theme.softAqua
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
        case .color: return Theme.deepCoral
        case .shape: return Theme.deepTeal
        case .ordering: return Theme.deepAmber
        case .counting: return Theme.deepPlum
        case .spotDifference: return Theme.deepAqua
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
        case .color: return .color
        case .shape: return .shape
        case .ordering: return .ordering
        case .counting: return .counting
        case .spotDifference: return .spotDifference
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
            case .color:
                ColorGlyph(deep: module.deepTint, light: module.tint)
            case .shape:
                ShapeGlyph(deep: module.deepTint, light: module.tint)
            case .ordering:
                OrderingGlyph(deep: module.deepTint, light: module.tint)
            case .counting:
                CountingGlyph(deep: module.deepTint, light: module.tint)
            case .spotDifference:
                SpotDifferenceGlyph(deep: module.deepTint, light: module.tint)
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

// MARK: - 找颜色：三色圆点（调色盘感）

struct ColorGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [deep, deep.opacity(0.72)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.40)
                    .offset(x: -w * 0.13, y: w * 0.10)
                Circle()
                    .fill(LinearGradient(colors: [light, light.opacity(0.8)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.34)
                    .offset(x: w * 0.16, y: w * 0.06)
                Circle()
                    .fill(.white.opacity(0.92))
                    .frame(width: w * 0.28)
                    .overlay(Circle().stroke(deep.opacity(0.35), lineWidth: 1.5))
                    .offset(x: w * 0.02, y: -w * 0.18)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - 找形状：圆 + 方 + 三角

struct ShapeGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                Circle()
                    .fill(deep)
                    .frame(width: w * 0.34)
                    .offset(x: -w * 0.16, y: -w * 0.10)
                RoundedRectangle(cornerRadius: w * 0.05, style: .continuous)
                    .fill(light)
                    .frame(width: w * 0.32, height: w * 0.32)
                    .offset(x: w * 0.16, y: -w * 0.12)
                TriangleShape()
                    .fill(deep.opacity(0.78))
                    .frame(width: w * 0.36, height: w * 0.32)
                    .offset(y: w * 0.20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// 三角形（矢量，供形状图标复用）
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - 排一排：由大到小的三条

struct OrderingGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            VStack(spacing: w * 0.07) {
                bar(width: w * 0.62, deep: deep)
                bar(width: w * 0.44, deep: deep.opacity(0.78))
                bar(width: w * 0.26, deep: light)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func bar(width: CGFloat, deep: Color) -> some View {
        Capsule()
            .fill(LinearGradient(colors: [deep, deep.opacity(0.72)],
                                 startPoint: .leading, endPoint: .trailing))
            .frame(width: width, height: width * 0.20)
    }
}

// MARK: - 数一数：三个计数点

struct CountingGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            HStack(spacing: w * 0.09) {
                dot(size: w * 0.20, color: deep)
                dot(size: w * 0.24, color: deep.opacity(0.82))
                dot(size: w * 0.28, color: light)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func dot(size: CGFloat, color: Color) -> some View {
        Circle()
            .fill(LinearGradient(colors: [color, color.opacity(0.75)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: size, height: size)
    }
}

// MARK: - 找不同：四宫格，其中一格被圈出

struct SpotDifferenceGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let cell = w * 0.30
            let gap = w * 0.06
            ZStack {
                VStack(spacing: gap) {
                    HStack(spacing: gap) {
                        cellView(size: cell, color: light)
                        cellView(size: cell, color: light)
                    }
                    HStack(spacing: gap) {
                        cellView(size: cell, color: light)
                        cellView(size: cell, color: deep)
                    }
                }
                // 圈出不同的那一格
                RoundedRectangle(cornerRadius: cell * 0.28, style: .continuous)
                    .stroke(deep, lineWidth: max(2, w * 0.045))
                    .frame(width: cell * 1.34, height: cell * 1.34)
                    .offset(x: (cell + gap) / 2, y: (cell + gap) / 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func cellView(size: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
            .fill(LinearGradient(colors: [color, color.opacity(0.7)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
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
