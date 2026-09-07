import SwiftUI

// MARK: - Liquid Glass 组件库（§4：所有玻璃效果唯一实现入口）
//
// iOS 26+：使用系统原生 glassEffect() 真·液态玻璃（需 Xcode 26+ / iOS 26 SDK 编译）。
// iOS 17/18 回退：.ultraThinMaterial 基材 + 统一高光/描边/阴影构成项目自定义玻璃材质。

// MARK: - 玻璃基材

/// 胶囊/圆形玻璃面（按钮、Chip 用）
struct GlassSurfaceStyle: ViewModifier {
    let shape: AnyShape
    /// 染色（Primary 层级 / 选中态）
    var tint: Color? = nil
    var tintOpacity: Double = 0.8
    var shadowRadius: CGFloat = 12

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // 真·液态玻璃：系统自带高光/折射/投影，tint 走 Glass.tint
            content
                .glassEffect(
                    tint.map { Glass.regular.tint($0).interactive() } ?? Glass.regular.interactive(),
                    in: shape
                )
        } else {
            legacyMaterial(content)
        }
    }

    private func legacyMaterial(_ content: Content) -> some View {
        content
            .background(
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint {
                        shape.fill(tint.opacity(tintOpacity))
                    }
                    // 顶部高光渐变（玻璃质感）
                    shape.fill(
                        LinearGradient(colors: [Theme.glassTint, .clear],
                                       startPoint: .top, endPoint: .center)
                    )
                }
            )
            .overlay(
                shape.stroke(Theme.glassHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: shadowRadius, y: shadowRadius / 2)
    }
}

extension View {
    func glassSurface(in shape: AnyShape,
                      tint: Color? = nil,
                      tintOpacity: Double = 0.8,
                      shadow: CGFloat = 12) -> some View {
        modifier(GlassSurfaceStyle(shape: shape, tint: tint, tintOpacity: tintOpacity, shadowRadius: shadow))
    }
}

/// 玻璃卡片（§29：Glass 是材质，不是内容——卡片仅轻染分类色）
struct GlassCardStyle: ViewModifier {
    var radius: CGFloat = GrowRadius.card
    var tint: Color? = nil
    var tintOpacity: Double = 0.14

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    tint.map { Glass.regular.tint($0) } ?? Glass.regular,
                    in: RoundedRectangle(cornerRadius: radius, style: .continuous)
                )
        } else {
            legacyMaterial(content)
        }
    }

    private func legacyMaterial(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background(
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint {
                        shape.fill(tint.opacity(tintOpacity))
                    }
                    shape.fill(
                        LinearGradient(colors: [Theme.glassTint, .clear],
                                       startPoint: .top, endPoint: .center)
                    )
                }
            )
            .overlay(
                shape.stroke(Theme.glassHighlight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
    }
}

extension View {
    func glassCard(radius: CGFloat = GrowRadius.card,
                   tint: Color? = nil,
                   tintOpacity: Double = 0.14) -> some View {
        modifier(GlassCardStyle(radius: radius, tint: tint, tintOpacity: tintOpacity))
    }
}

// MARK: - 按压反馈（§18：明确但轻微，兼容 Reduce Motion）

struct GlassButtonStyle: ButtonStyle {
    var settings: SettingsManager = .shared

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && settings.animationOn && !settings.reduceMotion ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(GrowAnimation.press(settings), value: configuration.isPressed)
    }
}

// MARK: - 玻璃按钮标签（纯视觉，供 Button 与 NavigationLink 复用）

struct GlassPill: View {
    @EnvironmentObject var settings: SettingsManager

    let title: String
    var icon: String? = nil
    /// 播放中：显示波纹指示器
    var isPlaying: Bool = false
    var style: GlassButton.Style = .secondary
    var tint: Color = Theme.success

    var body: some View {
        HStack(spacing: 8) {
            if isPlaying {
                WaveIndicator(active: true, color: style == .primary ? .white : Theme.textPrimary)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: style == .primary ? 16 : 15, weight: .semibold))
            }
            Text(title)
                .font(.system(size: Theme.scaled(style == .primary ? 17 : 16, settings: settings),
                              weight: style == .primary ? .bold : .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(style == .primary ? Color.white : Theme.textPrimary)
        .padding(.horizontal, style == .primary ? 26 : 22)
        .frame(minHeight: (style == .primary ? 56 : 50) * settings.buttonScaleFactor)
        .frame(minWidth: style == .primary ? 140 : 110)
        .glassSurface(in: AnyShape(Capsule()),
                      tint: style == .primary ? tint : nil,
                      tintOpacity: 0.82,
                      shadow: style == .primary ? 12 : 8)
    }
}

// MARK: - GlassButton（§5：所有主要按钮统一入口）

struct GlassButton: View {
    @EnvironmentObject var settings: SettingsManager

    enum Style { case primary, secondary }

    let title: String
    var icon: String? = nil
    var style: Style = .secondary
    var tint: Color = Theme.success
    var isPlaying: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            GlassPill(title: title, icon: icon, isPlaying: isPlaying, style: style, tint: tint)
        }
        .buttonStyle(GlassButtonStyle(settings: settings))
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
        .accessibilityHint(title)
    }
}

// MARK: - 圆形玻璃图标

/// 纯视觉圆形玻璃图标（供 NavigationLink / toolbar 使用）
struct GlassIconBadge: View {
    @EnvironmentObject var settings: SettingsManager

    let systemName: String
    var size: CGFloat = 44
    var iconSize: CGFloat = 17
    var tint: Color = Theme.textSecondary

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size * settings.buttonScaleFactor,
                   height: size * settings.buttonScaleFactor)
            .glassSurface(in: AnyShape(Circle()), shadow: 6)
    }
}

/// 圆形玻璃图标按钮（§7：命中区 = 整个圆，远大于图标本身）
struct GlassIconButton: View {
    @EnvironmentObject var settings: SettingsManager

    let systemName: String
    var size: CGFloat = 52
    var iconSize: CGFloat = 18
    var tint: Color = Theme.textSecondary
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size * settings.buttonScaleFactor,
                       height: size * settings.buttonScaleFactor)
                .glassSurface(in: AnyShape(Circle()), shadow: 8)
        }
        .buttonStyle(GlassButtonStyle(settings: settings))
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - GlassChip（胶囊选择器：分类筛选 / 模式切换）

struct GlassChip: View {
    @EnvironmentObject var settings: SettingsManager

    let title: String
    var symbol: String? = nil
    var selected: Bool = false
    var tint: Color = Theme.textPrimary
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 4) {
                if let symbol {
                    Text(symbol)
                }
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(selected ? tint : Theme.textSecondary)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .glassSurface(in: AnyShape(Capsule()),
                          tint: selected ? tint : nil,
                          tintOpacity: 0.16,
                          shadow: selected ? 8 : 5)
            .overlay(
                Capsule().strokeBorder(selected ? tint.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(GlassButtonStyle(settings: settings))
    }
}

// MARK: - 统一入口卡（§6：Icon → 标题 → 描述 的现代层级，全 App 统一）

struct GlassEntryCard: View {
    @EnvironmentObject var settings: SettingsManager

    enum Layout { case vertical, horizontal }

    let module: GrowModule
    /// 计数或状态说明，如「78 个对象」「完成入门后解锁」
    var detail: String? = nil
    var layout: Layout = .vertical

    var body: some View {
        Group {
            switch layout {
            case .vertical:
                VStack(alignment: .leading, spacing: 12) {
                    ModuleIconView(module: module, size: 54)
                    Spacer(minLength: 4)
                    Text(module.title)
                        .font(GrowFont.heading(settings))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(module.subtitle)
                        .font(GrowFont.caption(settings))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .frame(minHeight: 156 * settings.buttonScaleFactor)

            case .horizontal:
                HStack(spacing: 16) {
                    ModuleIconView(module: module, size: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title)
                            .font(GrowFont.heading(settings))
                            .foregroundStyle(Theme.textPrimary)
                        Text(module.subtitle)
                            .font(GrowFont.caption(settings))
                            .foregroundStyle(Theme.textSecondary)
                        if let detail {
                            Text(detail)
                                .font(GrowFont.caption(settings).weight(.semibold))
                                .foregroundStyle(module.deepTint)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
                .padding(18)
                .frame(minHeight: 100 * settings.buttonScaleFactor)
            }
        }
        .glassCard(tint: module.tint.opacity(0.45), tintOpacity: 0.10)
    }
}

// MARK: - 页面头部（标题 + 副标题 + 右侧操作，Glass 语言统一）

struct GlassPageHeader: View {
    @EnvironmentObject var settings: SettingsManager

    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(GrowFont.title(settings))
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(GrowFont.caption(settings))
                        .tracking(2)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            trailing
        }
    }
}
