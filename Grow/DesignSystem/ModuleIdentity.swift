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
        case .puzzle: return "拼图世界"
        }
    }

    var subtitle: String {
        switch self {
        case .nature: return "认识身边的自然"
        case .poem: return "和古诗一起探索"
        case .learning: return "数字 · 拼音"
        case .puzzle: return "动手拼一拼"
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

private struct PuzzleGlyph: View {
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
