import SwiftUI

/// 探索页：随机发现——每次进入 / 点击「换一换」，随机展示四个板块中的一个内容。
/// 与首页（固定入口）职责区分：探索页只做「随机惊喜发现」。
struct ExploreRootView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    @EnvironmentObject var learning: LearningRepository
    @EnvironmentObject var games: GameRepository
    @State private var appeared = false
    @State private var discovery: Discovery?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                header

                if let discovery {
                    discoveryCard(discovery)
                        .id(discovery.id)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92).combined(with: .opacity),
                            removal: .opacity))
                }

                refreshButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .animation(GrowAnimation.card(settings), value: discovery?.id)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("探索")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if discovery == nil { discovery = makeDiscovery() }
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }

    private var header: some View {
        GlassPageHeader(title: "探索", subtitle: "每次都有新发现")
            .padding(.top, 8)
            .opacity(appeared ? 1 : 0)
    }

    // MARK: - 随机发现大卡（点击进入对应内容）

    @ViewBuilder
    private func discoveryCard(_ discovery: Discovery) -> some View {
        NavigationLink { discoveryDestination(discovery) } label: {
            VStack(spacing: 16) {
                // 类别标签
                Text(discovery.badge)
                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(discovery.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(discovery.accent.opacity(0.16)))

                discoveryIcon(discovery, size: 132)
                    .frame(width: 132, height: 132)

                VStack(spacing: 6) {
                    Text(discovery.title)
                        .font(.system(size: Theme.scaled(30, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(discovery.subtitle)
                        .font(.system(size: Theme.scaled(16, settings: settings), weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text("点开看看")
                        .font(.system(size: Theme.scaled(14, settings: settings), weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(discovery.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .growCard(fill: discovery.accent.opacity(0.16))
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - 换一换（刷新随机内容）

    private var refreshButton: some View {
        Button {
            guard let current = discovery else { return }
            withAnimation(GrowAnimation.card(settings)) {
                discovery = makeDiscovery(excluding: current)
            }
            // 播报新内容名称，强化「发现」感
            if let next = discovery { speakDiscovery(next) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20, weight: .bold))
                Text("换一换")
                    .font(.system(size: Theme.scaled(19, settings: settings), weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 36)
            .frame(minHeight: 58 * settings.buttonScaleFactor)
            .background(Capsule().fill(Theme.vegetable))
            .shadow(color: Theme.vegetable.opacity(0.35), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
        .accessibilityHint("随机换一个内容")
        .opacity(appeared ? 1 : 0)
    }

    private func speakDiscovery(_ discovery: Discovery) {
        let settings = SettingsManager.shared
        AudioManager.shared.speak(name: discovery.spokenText,
                                  language: settings.defaultLanguage,
                                  key: "explore-\(discovery.id)")
    }

    // MARK: - 随机选题（避免与当前内容重复）

    private func makeDiscovery(excluding current: Discovery? = nil) -> Discovery? {
        for _ in 0..<6 {
            let makers: [() -> Discovery?] = [
                { RandomizationService.shared.shuffle(content.natureItems).first.map { .nature($0) } },
                { content.poems.randomElement().map { .poem($0) } },
                { learning.numbers.randomElement().map { .number($0) } },
                { learning.pinyins.randomElement().map { .pinyin($0) } },
                { games.playableDefinitions.isEmpty ? nil : .game }
            ]
            if let next = makers.randomElement()?(), next.id != current?.id {
                return next
            }
        }
        return current
    }

    @ViewBuilder
    private func discoveryDestination(_ discovery: Discovery) -> some View {
        switch discovery {
        case .nature(let item): NatureDetailView(item: item)
        case .poem(let poem): PoemDetailView(poemId: poem.id)
        case .number: NumberView()
        case .pinyin(let item): PinyinView(type: item.type)
        case .game: GameHomeView()
        }
    }

    @ViewBuilder
    private func discoveryIcon(_ discovery: Discovery, size: CGFloat) -> some View {
        switch discovery {
        case .nature(let item):
            IllustrationView(identifier: item.illustration)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        case .poem(let poem):
            IllustrationView(identifier: poem.illustration)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
        case .number(let item):
            NumberSymbolIcon(number: item.number, size: size)
        case .pinyin(let item):
            PinyinSymbolIcon(symbol: item.symbol, type: item.type, size: size)
        case .game:
            GameModuleIcon(module: .puzzle, size: size)
        }
    }
}

// MARK: - Discovery 模型

private enum Discovery: Identifiable {
    case nature(NatureItem)
    case poem(Poem)
    case number(NumberItem)
    case pinyin(PinyinItem)
    case game

    var id: String {
        switch self {
        case .nature(let item): return "nature-\(item.id)"
        case .poem(let poem): return "poem-\(poem.id)"
        case .number(let item): return "number-\(item.id)"
        case .pinyin(let item): return "pinyin-\(item.id)"
        case .game: return "game-home"
        }
    }

    var badge: String {
        switch self {
        case .nature: return "自然卡片"
        case .poem: return "古诗"
        case .number: return "数字"
        case .pinyin: return "拼音"
        case .game: return "小游戏"
        }
    }

    var title: String {
        switch self {
        case .nature(let item): return item.nameZh
        case .poem(let poem): return poem.title
        case .number(let item): return item.chineseName
        case .pinyin(let item): return "\(item.symbol) · \(item.exampleWord)"
        case .game: return "趣味游戏"
        }
    }

    var subtitle: String {
        switch self {
        case .nature(let item): return item.nameEn
        case .poem(let poem): return "\(poem.dynasty) · \(poem.author)"
        case .number(let item): return "数字 \(item.number)"
        case .pinyin(let item): return item.type.displayName
        case .game: return "玩一玩 · 认一认"
        }
    }

    /// 换一换时的朗读文本
    var spokenText: String {
        switch self {
        case .nature(let item): return item.nameZh
        case .poem(let poem): return "古诗，\(poem.title)"
        case .number(let item): return item.chineseName
        case .pinyin(let item): return item.symbol
        case .game: return "一起玩游戏"
        }
    }

    var accent: Color {
        switch self {
        case .nature: return Theme.softGreen
        case .poem: return Theme.softSand
        case .number: return Theme.fruit
        case .pinyin: return Theme.softBlue
        case .game: return Theme.softLilac
        }
    }
}
