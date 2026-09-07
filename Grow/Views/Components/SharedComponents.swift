import SwiftUI

/// 播放时的小声波指示器：4 根竖条以不同相位往复跳动（长短跳动）。
/// 由 TimelineView 驱动持续动画；Reduce Motion / 关闭动画时静态显示中高条。
struct WaveIndicator: View {
    @ObservedObject private var settings = SettingsManager.shared
    let active: Bool
    var color: Color = .white

    private static let barCount = 4

    var body: some View {
        Group {
            if active && settings.animationOn && !settings.reduceMotion {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    HStack(spacing: 3) {
                        ForEach(0..<Self.barCount, id: \.self) { i in
                            Capsule()
                                .fill(color)
                                .frame(width: 3, height: barHeight(i, at: context.date))
                        }
                    }
                }
            } else {
                // 静态形态：中高条，保持占位尺寸稳定
                HStack(spacing: 3) {
                    ForEach(0..<Self.barCount, id: \.self) { _ in
                        Capsule()
                            .fill(color)
                            .frame(width: 3, height: 9)
                    }
                }
            }
        }
        .frame(height: 14)
    }

    /// 每根条按相位错开的正弦波在 5~14pt 之间往复变化
    private func barHeight(_ index: Int, at date: Date) -> CGFloat {
        let t = date.timeIntervalSinceReferenceDate
        let phase = t * 4.2 + Double(index) * 0.85
        let s = (sin(phase) + 1) / 2  // 0...1
        return 5 + s * 9
    }
}

/// 三语发音按钮组：一行三个，小巧不喧宾夺主
struct LanguageButtonsRow: View {
    @ObservedObject var audio = AudioManager.shared
    @ObservedObject var settings = SettingsManager.shared
    let name: String        // 当前语言下的读法（MVP 中英同名即可，TTS 按 locale 读）
    let nameEn: String
    let itemKey: String     // 播放 key 前缀

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SpeechLanguage.allCases) { lang in
                languageButton(lang)
            }
        }
    }

    private func languageButton(_ lang: SpeechLanguage) -> some View {
        let key = "\(itemKey)-\(lang.rawValue)"
        let isPlaying = audio.playingKey == key
        let isAvailable = audio.availableLanguages.contains(lang)

        // 按钮文字固定显示语言名称：国 / 粤 / En
        return Button {
            if isAvailable {
                audio.speak(name: lang == .english ? nameEn : name, language: lang, key: key)
            }
        } label: {
            HStack(spacing: 5) {
                if !isAvailable {
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 13, weight: .semibold))
                } else if isPlaying {
                    WaveIndicator(active: true, color: Theme.ink)
                } else {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(lang.displayName)
                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isAvailable ? (isPlaying ? Theme.ink : Theme.inkSoft) : Theme.inkSoft.opacity(0.4))
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(minWidth: 44, minHeight: 44 * settings.buttonScaleFactor)
            .background(
                Capsule().fill(isPlaying ? Theme.creamDeep : (isAvailable ? Theme.cream : Theme.cream.opacity(0.4)))
            )
            .overlay(
                Capsule().strokeBorder(isAvailable ? Theme.inkSoft.opacity(0.18) : Theme.inkSoft.opacity(0.12), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
        .disabled(!isAvailable)
        .accessibilityHint(isAvailable ? "播放 \(lang.displayName) 发音" : "未安装 \(lang.iosSettingsVoiceName) 语音包")
    }
}

/// 收藏按钮
struct FavoriteButton: View {
    @ObservedObject var library = UserLibrary.shared
    let kind: Kind
    let id: String

    enum Kind { case nature, poem }

    private var isFav: Bool {
        switch kind {
        case .nature: return library.favoriteNatureIDs.contains(id)
        case .poem: return library.favoritePoemIDs.contains(id)
        }
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                switch kind {
                case .nature: library.toggleNatureFavorite(id)
                case .poem: library.togglePoemFavorite(id)
                }
            }
        } label: {
            Image(systemName: isFav ? "heart.fill" : "heart")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(isFav ? Theme.heart : Theme.inkSoft.opacity(0.6))
                .scaleEffect(isFav ? 1.08 : 1.0)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(isFav ? "取消收藏" : "收藏")
    }
}

// MARK: - 普通话专用发音按钮（数字 / 拼音 / 拼图完成页复用）

/// 只使用标准普通话：数字、拼音都属于普通话学习体系（§24 / §66）。
struct SpeakButton: View {
    @ObservedObject var audio = AudioManager.shared
    @ObservedObject var settings = SettingsManager.shared

    let text: String
    let key: String
    /// 按钮上的文字（nil 时只显示喇叭）
    var title: String? = nil
    var style: Style = .compact

    enum Style { case compact, prominent }

    private var isPlaying: Bool { audio.playingKey == key }
    private var isAvailable: Bool { audio.availableLanguages.contains(.mandarin) }

    var body: some View {
        Button {
            guard isAvailable else { return }
            audio.speak(name: text, language: .mandarin, key: key)
        } label: {
            HStack(spacing: 8) {
                if isPlaying {
                    WaveIndicator(active: true, color: style == .prominent ? .white : Theme.ink)
                } else {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: style == .prominent ? 22 : 15, weight: .semibold))
                }
                if let title {
                    Text(title)
                        .font(.system(size: Theme.scaled(style == .prominent ? 17 : 14, settings: settings),
                                      weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .foregroundStyle(style == .prominent ? .white : (isPlaying ? Theme.ink : Theme.inkSoft))
            .padding(.horizontal, style == .prominent ? 22 : 14)
            .padding(.vertical, style == .prominent ? 16 : 12)
            .frame(minWidth: 44, minHeight: (style == .prominent ? 56 : 44) * settings.buttonScaleFactor)
            .background(
                Capsule().fill(style == .prominent
                               ? (isPlaying ? Theme.vegetable : Theme.vegetable.opacity(0.85))
                               : (isPlaying ? Theme.creamDeep : Theme.cream))
            )
            .overlay(
                Capsule().strokeBorder(style == .prominent ? Color.clear : Theme.inkSoft.opacity(0.18), lineWidth: 1.5)
            )
            .shadow(color: style == .prominent ? Theme.vegetable.opacity(0.3) : .clear, radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
        .disabled(!isAvailable)
        .accessibilityHint("播放普通话发音")
    }
}
