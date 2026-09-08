import SwiftUI

// MARK: - 跨游戏共用 UI：开局说明 / 大图选项卡 / 完成覆盖层（§4.0 通用流程）

// MARK: - 开局说明（图片+声音 > 文字：大字指令，TTS 由页面 onAppear 自动朗读）

struct GameIntroTip: View {
    @EnvironmentObject var settings: SettingsManager

    let module: GameModule
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            GameModuleIcon(module: module, size: 44)
            Text(text)
                .font(.system(size: Theme.scaled(20, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(14)
        .growCard(fill: Theme.creamDeep)
    }
}

// MARK: - 大图选项卡（统一尺寸/圆角/状态）

enum GameCardState: Equatable {
    case normal
    case correct   // 打勾锁定
    case wrong     // 轻晃引导
}

/// 大图选项卡：展示 NatureItem 的插画（找相同目标/选项、配对翻开面等复用）
struct GameOptionCard: View {
    @EnvironmentObject var settings: SettingsManager

    let item: NatureItem
    var state: GameCardState = .normal
    /// 是否在图下方显示名称（配对翻开面显示；找相同选项不显示以免提示答案）
    var showsName: Bool = false
    var cornerRadius: CGFloat = 24

    var body: some View {
        VStack(spacing: 8) {
            IllustrationView(identifier: item.illustration)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)

            if showsName {
                Text(item.nameZh)
                    .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: state == .normal ? 0 : 3)
        )
        .overlay(alignment: .topTrailing) {
            if state == .correct {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.vegetable)
                    .padding(8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .shadow(color: .black.opacity(0.07), radius: 10, y: 5)
    }

    private var borderColor: Color {
        switch state {
        case .normal: return .clear
        case .correct: return Theme.vegetable
        case .wrong: return Theme.heart.opacity(0.55)
        }
    }
}

// MARK: - 轻晃效果（Reduce Motion / 关闭动画时不生效）

/// 水平轻晃 GeometryEffect（错误引导，无错误音无红叉）
struct GameShakeEffect: GeometryEffect {
    var travel: CGFloat = 7
    var shakes: CGFloat = 2
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let rotation = sin(progress * .pi * shakes * 2)
        let offset = rotation * travel
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// 错误轻晃修饰器（Phase 6.1 共享版）
/// 说明：FindSameGameView 里的 ShakeOnError 是文件私有，这里提供跨游戏复用的同名能力。
struct GameShakeOnError: ViewModifier {
    let shakeToken: Int
    let reduceMotion: Bool
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .modifier(GameShakeEffect(progress: progress))
                .onChange(of: shakeToken) { _, _ in
                    progress = 0
                    withAnimation(.easeInOut(duration: 0.4)) { progress = 1 }
                }
        }
    }
}

// MARK: - 数量展示（数一数复用：同一素材重复 N 次，不新增图片）

/// 把同一自然内容重复展示 count 次（§二十二：不生成重复图片）
struct RepeatedItemView: View {
    let item: NatureItem
    let count: Int
    var maxWidth: CGFloat = 300

    private let columns = [GridItem(.adaptive(minimum: 54), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<max(0, count), id: \.self) { _ in
                IllustrationView(identifier: item.illustration)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: maxWidth)
    }
}

// MARK: - 完成覆盖层（四游戏共用：成品大图 + 名称三语发音 + 再玩/下一项/认识一下）

struct GameCompleteOverlay: View {
    @EnvironmentObject var settings: SettingsManager

    /// 完成时刻的主角对象
    let heroItem: NatureItem
    /// "下一项"主按钮的主题色（游戏柔和主色）
    let accent: Color
    let onReplay: () -> Void
    /// "下一项"（nil 时隐藏按钮）
    let onNext: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text("完成！")
                .font(.system(size: Theme.scaled(34, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            IllustrationView(identifier: heroItem.illustration)
                .frame(width: 170, height: 170)
                .growCard(fill: .white.opacity(0.85), radius: 26)

            VStack(spacing: 2) {
                Text(heroItem.nameZh)
                    .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(heroItem.nameEn)
                    .font(.system(size: Theme.scaled(17, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }

            // 名称三语发音（复用现有三语按钮组，§音频唯一出口）
            LanguageButtonsRow(name: heroItem.nameZh,
                               nameEn: heroItem.nameEn,
                               itemKey: "game-complete-\(heroItem.id)")

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                GlassButton(title: "再玩一次",
                            icon: "arrow.counterclockwise",
                            style: .secondary,
                            action: onReplay)

                if let onNext {
                    GlassButton(title: "下一项",
                                icon: "arrow.right",
                                style: .primary,
                                tint: accent,
                                action: onNext)
                }
            }

            NavigationLink {
                NatureDetailView(item: heroItem)
            } label: {
                HStack(spacing: 5) {
                    Text("认识一下")
                        .font(.system(size: Theme.scaled(15, settings: settings), weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Theme.inkSoft)
                .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
        }
        .padding(26)
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Theme.cream)
                .shadow(color: .black.opacity(0.14), radius: 26, y: 12)
        )
        .padding(.horizontal, 28)
    }
}
