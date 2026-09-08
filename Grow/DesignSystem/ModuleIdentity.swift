import SwiftUI

// MARK: - 模块统一视觉符号（§7 / §8：四个图标属于同一视觉系统）
//
// 统一规则：
// - 同一容器：圆角连续 squircle，柔和模块色渐变底 + 顶部高光
// - 同一画法：SwiftUI 矢量 Soft 3D —— 低饱和深色渐变主体 + 白色高光
// - 不使用 Emoji、不混用 SF Symbol / 扁平 / 3D 风格

enum GrowModule {
    case nature      // 自然世界
    case poem        // 古诗小世界
    case learning    // 看图识字
    case puzzle      // 拼图世界

    var title: String {
        switch self {
        case .nature: return "自然世界"
        case .poem: return "古诗小世界"
        case .learning: return "看图识字"
        case .puzzle: return "趣味游戏"
        }
    }

    var subtitle: String {
        switch self {
        case .nature: return "认识身边的自然"
        case .poem: return "和古诗一起探索"
        case .learning: return "数字 · 拼音"
        case .puzzle: return "拼图 · 配对 · 找相同 · 分类"
        }
    }

    /// 卡片轻染主题色（柔和）
    var tint: Color {
        switch self {
        case .nature: return Theme.softGreen
        case .poem: return Theme.softSand
        case .learning: return Theme.softBlue
        case .puzzle: return Theme.softLilac
        }
    }

    /// 图标主体深色
    var deepTint: Color {
        switch self {
        case .nature: return Theme.deepGreen
        case .poem: return Theme.deepSand
        case .learning: return Theme.deepBlue
        case .puzzle: return Theme.deepLilac
        }
    }
}

// MARK: - 统一图标视图

/// 模块图标：squircle 柔光底 + 统一 Soft 3D 内容
struct ModuleIconView: View {
    let module: GrowModule
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            // 容器：柔和模块色渐变底
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(colors: [module.tint.opacity(0.55), module.tint.opacity(0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .fill(
                            LinearGradient(colors: [.white.opacity(0.55), .clear],
                                           startPoint: .top, endPoint: .center)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )

            // 内容（按模块绘制，画布归一化）
            content
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .shadow(color: module.tint.opacity(0.35), radius: size * 0.10, y: size * 0.05)
    }

    @ViewBuilder
    private var content: some View {
        switch module {
        case .nature: SproutGlyph(deep: module.deepTint)
        case .poem: PoemScrollGlyph(deep: module.deepTint)
        case .learning: CharacterCardGlyph(deep: module.deepTint)
        case .puzzle: PuzzleGlyph(deep: module.deepTint, light: module.tint)
        }
    }
}

// MARK: - 自然世界：嫩芽（双叶 + 弯茎 + 小土丘）

private struct SproutGlyph: View {
    let deep: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 小土丘
                HalfCircleShape()
                    .fill(LinearGradient(colors: [deep.opacity(0.22), deep.opacity(0.10)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.62, height: w * 0.16)
                    .offset(y: w * 0.40)

                // 弯茎
                StemShape()
                    .stroke(LinearGradient(colors: [deep, deep.opacity(0.75)],
                                           startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: w * 0.075, lineCap: .round))
                    .frame(width: w * 0.5, height: w * 0.52)
                    .offset(y: w * 0.20)

                // 左右两片叶子（Soft 3D 渐变 + 高光）
                leaf(x: -w * 0.24, y: -w * 0.12, flip: false, w: w)
                leaf(x: w * 0.24, y: -w * 0.12, flip: true, w: w)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func leaf(x: CGFloat, y: CGFloat, flip: Bool, w: CGFloat) -> some View {
        return ZStack {
            LeafShape()
                .fill(LinearGradient(colors: [deep, deep.opacity(0.70)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            // 叶面高光
            LeafShape()
                .fill(LinearGradient(colors: [.white.opacity(0.45), .clear],
                                     startPoint: .top, endPoint: .bottom))
                .padding(w * 0.015)
        }
        .frame(width: w * 0.42, height: w * 0.24)
        .scaleEffect(x: flip ? -1 : 1)
        .rotationEffect(.degrees(flip ? -22 : 22))
        .offset(x: x, y: y)
    }
}

private struct StemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                       control: CGPoint(x: rect.midX + rect.width * 0.10, y: rect.midY))
        return p
    }
}

private struct HalfCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                       control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.3))
        p.closeSubpath()
        return p
    }
}

// MARK: - 古诗小世界：诗卷（卷轴 + 诗文行）

private struct PoemScrollGlyph: View {
    let deep: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 卷纸
                RoundedRectangle(cornerRadius: w * 0.07, style: .continuous)
                    .fill(LinearGradient(colors: [.white, Theme.softSand.opacity(0.45)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.72, height: w * 0.78)
                    .shadow(color: deep.opacity(0.18), radius: w * 0.04, y: w * 0.03)

                // 诗文行
                VStack(alignment: .leading, spacing: w * 0.07) {
                    textLine(width: w * 0.40, w: w)
                    textLine(width: w * 0.30, w: w)
                    textLine(width: w * 0.35, w: w)
                }
                .offset(x: -w * 0.06, y: 0)

                // 上卷轴
                RollerGlyph(deep: deep)
                    .frame(width: w * 0.86, height: w * 0.17)
                    .offset(y: -w * 0.40)
                // 下卷轴
                RollerGlyph(deep: deep)
                    .frame(width: w * 0.86, height: w * 0.17)
                    .offset(y: w * 0.40)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func textLine(width: CGFloat, w: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: w * 0.03)
            .fill(deep.opacity(0.35))
            .frame(width: width, height: w * 0.06)
    }
}

private struct RollerGlyph: View {
    let deep: Color

    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [deep, deep.opacity(0.72)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                                    startPoint: .top, endPoint: .center)))
    }
}

// MARK: - 看图识字：汉字卡片（微倾白卡 + 「字」）

private struct CharacterCardGlyph: View {
    let deep: Color
    @EnvironmentObject private var settings: SettingsManager

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 微倾的白色认知卡
                RoundedRectangle(cornerRadius: w * 0.10, style: .continuous)
                    .fill(LinearGradient(colors: [.white, Theme.softBlue.opacity(0.35)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.74, height: w * 0.74)
                    .rotationEffect(.degrees(-5))
                    .shadow(color: deep.opacity(0.20), radius: w * 0.05, y: w * 0.035)

                Text("字")
                    .font(.system(size: w * 0.44, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [deep, deep.opacity(0.78)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .rotationEffect(.degrees(-5))
                    .offset(y: -w * 0.01)

                // 右下角小圆点（认知符号点缀）
                Circle()
                    .fill(LinearGradient(colors: [Theme.softBlue, Theme.softBlue.opacity(0.6)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.15)
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1.5))
                    .offset(x: w * 0.27, y: w * 0.28)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - 拼图世界：两块拼图组合

/// 拼图双块（Soft 3D）：ModuleIconView(.puzzle) 与 GameModuleIcon(.puzzle) 共用
struct PuzzleGlyph: View {
    let deep: Color
    let light: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 后面一块（浅色，微旋）
                PuzzlePieceShape()
                    .fill(LinearGradient(colors: [.white.opacity(0.95), light.opacity(0.85)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(PuzzlePieceShape().stroke(.white.opacity(0.8), lineWidth: 1.5))
                    .frame(width: w * 0.50, height: w * 0.50)
                    .rotationEffect(.degrees(14))
                    .offset(x: w * 0.15, y: w * 0.17)

                // 前面一块（深色 Soft 3D）
                ZStack {
                    PuzzlePieceShape()
                        .fill(LinearGradient(colors: [deep, deep.opacity(0.75)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    // 顶面高光
                    PuzzlePieceShape()
                        .fill(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                             startPoint: .top, endPoint: .center))
                        .padding(w * 0.02)
                }
                .frame(width: w * 0.52, height: w * 0.52)
                .rotationEffect(.degrees(-8))
                .offset(x: -w * 0.10, y: -w * 0.08)
                .shadow(color: deep.opacity(0.28), radius: w * 0.05, y: w * 0.035)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// 拼图块：圆角方 + 右侧凸钮 + 上侧凹孔
struct PuzzlePieceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(rect.width, rect.height) * 0.22
        let knob = min(rect.width, rect.height) * 0.17
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r), style: .continuous)
        // 右侧凸钮
        p.addEllipse(in: CGRect(x: rect.maxX - knob * 0.55,
                                y: rect.midY - knob,
                                width: knob * 1.55,
                                height: knob * 2))
        return p
    }
}

// MARK: - 二级页统一图标容器（与 ModuleIconView 同一视觉系统）
//
// 二级页面（自然世界分类 / 看图识字分类）的入口图标统一走这里：
// squircle 柔光底 + Soft 3D 矢量内容，不再使用 Emoji。

struct SoftIconContainer<Content: View>: View {
    /// 容器染色的柔和主题色
    let tint: Color
    var size: CGFloat = 56
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(colors: [tint.opacity(0.55), tint.opacity(0.22)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .fill(
                            LinearGradient(colors: [.white.opacity(0.55), .clear],
                                           startPoint: .top, endPoint: .center)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 1)
                )

            content()
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.35), radius: size * 0.10, y: size * 0.05)
    }
}

// MARK: - 自然世界四分类图标（水果 / 蔬菜 / 动物 / 植物）

/// 自然分类统一 Soft 3D 矢量图标，替换原 Emoji symbol（模拟器显示「?」）。
struct NatureCategoryIcon: View {
    let category: NatureCategory
    var size: CGFloat = 56

    /// 分类柔和染色（容器的浅色底）
    private var tint: Color { Theme.categoryColor(category) }

    var body: some View {
        SoftIconContainer(tint: tint, size: size) {
            switch category {
            case .fruit: AppleGlyph()
            case .vegetable: BroccoliGlyph()
            case .animal: PandaGlyph(ink: Theme.ink)
            case .plant: FlowerGlyph(petal: .white, center: Theme.fruit)
            }
        }
    }
}

/// 水果：苹果（红果身 + 果柄 + 绿叶）
private struct AppleGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 果柄
                Capsule()
                    .fill(LinearGradient(colors: [Theme.poemWarm, Theme.poemWarm.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.07, height: w * 0.26)
                    .rotationEffect(.degrees(6))
                    .offset(y: -w * 0.34)

                // 叶子
                LeafShape()
                    .fill(LinearGradient(colors: [Theme.deepGreen, Theme.deepGreen.opacity(0.72)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.32, height: w * 0.17)
                    .rotationEffect(.degrees(-28))
                    .offset(x: w * 0.17, y: -w * 0.30)

                // 果身：双圆相融的苹果轮廓
                HStack(spacing: -w * 0.12) {
                    Circle().fill(appleFill)
                    Circle().fill(appleFill)
                }
                .frame(width: w * 0.56, height: w * 0.64)
                .offset(y: w * 0.10)
                .shadow(color: Theme.heart.opacity(0.3), radius: w * 0.05, y: w * 0.03)

                // 顶部高光
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.55), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.15, height: w * 0.30)
                    .offset(x: -w * 0.15, y: -w * 0.02)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var appleFill: LinearGradient {
        LinearGradient(colors: [Theme.heart, Theme.heart.opacity(0.78)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// 蔬菜：西兰花（深绿花球 + 浅绿短茎）
private struct BroccoliGlyph: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 短茎
                RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
                    .fill(LinearGradient(colors: [Theme.vegetable, Theme.vegetable.opacity(0.75)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.30, height: w * 0.34)
                    .offset(y: w * 0.28)

                // 花球：三团相融
                ZStack {
                    Circle().fill(crownFill).frame(width: w * 0.42, height: w * 0.42)
                        .offset(x: -w * 0.17, y: w * 0.05)
                    Circle().fill(crownFill).frame(width: w * 0.42, height: w * 0.42)
                        .offset(x: w * 0.17, y: w * 0.05)
                    Circle().fill(crownFill).frame(width: w * 0.50, height: w * 0.50)
                        .offset(y: -w * 0.12)
                }
                .offset(y: -w * 0.04)
                .shadow(color: Theme.deepGreen.opacity(0.28), radius: w * 0.05, y: w * 0.03)

                // 花球顶面高光
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.4), .clear],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.30, height: w * 0.16)
                    .offset(x: -w * 0.10, y: -w * 0.24)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var crownFill: LinearGradient {
        LinearGradient(colors: [Theme.deepGreen, Theme.deepGreen.opacity(0.78)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// 动物：熊猫（白脸 + 圆耳 + 黑眼圈），脸部用白高光跳出容器底色
private struct PandaGlyph: View {
    let ink: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 圆耳
                Circle().fill(earFill).frame(width: w * 0.28, height: w * 0.28)
                    .offset(x: -w * 0.26, y: -w * 0.26)
                Circle().fill(earFill).frame(width: w * 0.28, height: w * 0.28)
                    .offset(x: w * 0.26, y: -w * 0.26)

                // 脸
                Circle()
                    .fill(LinearGradient(colors: [.white, Theme.creamDeep],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.78, height: w * 0.78)
                    .shadow(color: ink.opacity(0.15), radius: w * 0.04, y: w * 0.03)

                // 黑眼圈
                Ellipse().fill(eyeFill).frame(width: w * 0.20, height: w * 0.28)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -w * 0.15, y: -w * 0.02)
                Ellipse().fill(eyeFill).frame(width: w * 0.20, height: w * 0.28)
                    .rotationEffect(.degrees(18))
                    .offset(x: w * 0.15, y: -w * 0.02)

                // 眼睛高光点
                Circle().fill(.white).frame(width: w * 0.06, height: w * 0.06)
                    .offset(x: -w * 0.13, y: -w * 0.06)
                Circle().fill(.white).frame(width: w * 0.06, height: w * 0.06)
                    .offset(x: w * 0.13, y: -w * 0.06)

                // 鼻子
                Capsule().fill(eyeFill).frame(width: w * 0.12, height: w * 0.08)
                    .offset(y: w * 0.14)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var earFill: LinearGradient {
        LinearGradient(colors: [ink, ink.opacity(0.8)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var eyeFill: LinearGradient {
        LinearGradient(colors: [ink.opacity(0.92), ink.opacity(0.75)],
                       startPoint: .top, endPoint: .bottom)
    }
}

/// 植物：小花（五瓣花 + 暖色花心）
private struct FlowerGlyph: View {
    let petal: Color
    let center: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // 五片花瓣
                ForEach(0..<5, id: \.self) { i in
                    Ellipse()
                        .fill(petalFill)
                        .frame(width: w * 0.26, height: w * 0.42)
                        .offset(y: -w * 0.24)
                        .rotationEffect(.degrees(Double(i) * 72))
                        .shadow(color: petal.opacity(0.18), radius: w * 0.03, y: w * 0.02)
                }

                // 花心
                Circle()
                    .fill(LinearGradient(colors: [center, center.opacity(0.78)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: w * 0.30, height: w * 0.30)
                    .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.5), .clear],
                                                           startPoint: .top, endPoint: .center))
                        .padding(w * 0.03))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var petalFill: LinearGradient {
        LinearGradient(colors: [petal, petal.opacity(0.72)],
                       startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - 拼图难度图标（按块数画迷你拼块阵，替换 Emoji）

/// 难度图标：grid×grid 的迷你拼块，右下角一块半透明表示「待拼上」
struct PuzzleDifficultyIcon: View {
    /// 每行（列）块数：2 / 3 / 4
    let grid: Int
    /// 拼块深色
    let deep: Color
    var size: CGFloat = 56

    var body: some View {
        GeometryReader { geo in
            let side = geo.size.width
            let gap = side * 0.07
            let cell = (side - gap * CGFloat(grid - 1)) / CGFloat(grid)
            VStack(spacing: gap) {
                ForEach(0..<grid, id: \.self) { r in
                    HStack(spacing: gap) {
                        ForEach(0..<grid, id: \.self) { c in
                            Group {
                                if r == grid - 1 && c == grid - 1 {
                                    // 待拼上的最后一块：半透明
                                    RoundedRectangle(cornerRadius: cell * 0.30, style: .continuous)
                                        .fill(deep.opacity(0.35))
                                } else {
                                    RoundedRectangle(cornerRadius: cell * 0.30, style: .continuous)
                                        .fill(LinearGradient(colors: [deep, deep.opacity(0.72)],
                                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                            }
                            .frame(width: cell, height: cell)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 看图识字分类图标（数字 / 声母 / 韵母）

enum LearningTopic {
    case numbers   // 数字
    case initial   // 声母
    case final     // 韵母

    /// 卡片上绘制的示例字符
    var glyphText: String {
        switch self {
        case .numbers: return "123"
        case .initial: return "b"
        case .final: return "a"
        }
    }
}

/// 看图识字分类统一图标：微倾白卡 + 示例字符（同一 Soft 3D 视觉系统，替换 Emoji）
struct LearningTopicIcon: View {
    let topic: LearningTopic
    var size: CGFloat = 56

    /// 容器染色的柔和主题色
    private var tint: Color {
        switch topic {
        case .numbers: return Theme.fruit
        case .initial: return Theme.animal
        case .final: return Theme.plant
        }
    }

    /// 卡片文字的 Soft 3D 深色
    private var deep: Color {
        switch topic {
        case .numbers: return Theme.fruit
        case .initial: return Theme.deepBlue
        case .final: return Theme.deepLilac
        }
    }

    var body: some View {
        SoftIconContainer(tint: tint, size: size) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    // 微倾的白色认知卡
                    RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                        .fill(LinearGradient(colors: [.white, tint.opacity(0.30)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.80, height: w * 0.80)
                        .rotationEffect(.degrees(-5))
                        .shadow(color: deep.opacity(0.20), radius: w * 0.05, y: w * 0.035)

                    Text(topic.glyphText)
                        .font(.system(size: topic == .numbers ? w * 0.30 : w * 0.44,
                                      weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(
                            LinearGradient(colors: [deep, deep.opacity(0.78)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .rotationEffect(.degrees(-5))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

// MARK: - 拼音单字母图标（按实际声母/韵母符号绘制，避免「q 显示成 b」之类错配）

/// 与 LearningTopicIcon 同视觉系统，但绘制的是「具体某条拼音」的 symbol（如 q / ang），
/// 而不是分类通用示例字（.initial 固定画 "b"）。用于探索页单条拼音发现卡。
struct PinyinSymbolIcon: View {
    let symbol: String
    let type: PinyinType
    var size: CGFloat = 56

    /// 容器染色的柔和主题色（与 LearningTopicIcon 的 声母/韵母 一致）
    private var tint: Color {
        switch type {
        case .initial: return Theme.animal
        case .final: return Theme.plant
        case .tone: return Theme.plant
        }
    }

    /// 卡片文字的 Soft 3D 深色
    private var deep: Color {
        switch type {
        case .initial: return Theme.deepBlue
        case .final: return Theme.deepLilac
        case .tone: return Theme.deepLilac
        }
    }

    var body: some View {
        SoftIconContainer(tint: tint, size: size) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    // 微倾的白色认知卡
                    RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                        .fill(LinearGradient(colors: [.white, tint.opacity(0.30)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.80, height: w * 0.80)
                        .rotationEffect(.degrees(-5))
                        .shadow(color: deep.opacity(0.20), radius: w * 0.05, y: w * 0.035)

                    Text(symbol)
                        .font(.system(size: symbol.count > 1 ? w * 0.28 : w * 0.44,
                                      weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(
                            LinearGradient(colors: [deep, deep.opacity(0.78)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .rotationEffect(.degrees(-5))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

// MARK: - 数字单值图标（按实际数字绘制，避免「7 显示成 123」之类错配）

/// 与 LearningTopicIcon 同视觉系统，但绘制「具体某个数字」而非分类通用示例 "123"。
/// 用于探索页单条数字发现卡。
struct NumberSymbolIcon: View {
    let number: Int
    var size: CGFloat = 56

    /// 容器染色的柔和主题色（与 LearningTopicIcon 的 数字 一致）
    private var tint: Color { Theme.fruit }
    /// 卡片文字的 Soft 3D 深色
    private var deep: Color { Theme.fruit }

    var body: some View {
        SoftIconContainer(tint: tint, size: size) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    // 微倾的白色认知卡
                    RoundedRectangle(cornerRadius: w * 0.14, style: .continuous)
                        .fill(LinearGradient(colors: [.white, tint.opacity(0.30)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.80, height: w * 0.80)
                        .rotationEffect(.degrees(-5))
                        .shadow(color: deep.opacity(0.20), radius: w * 0.05, y: w * 0.035)

                    Text("\(number)")
                        .font(.system(size: w * 0.44, weight: .semibold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(
                            LinearGradient(colors: [deep, deep.opacity(0.78)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .rotationEffect(.degrees(-5))
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
