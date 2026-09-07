import SwiftUI

/// 播放时的小声波指示器
struct WaveIndicator: View {
    let active: Bool
    var color: Color = .white

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: active ? 14 : 6)
                    .animation(
                        active ? .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.12) : .default,
                        value: active
                    )
            }
        }
        .frame(height: 14)
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
