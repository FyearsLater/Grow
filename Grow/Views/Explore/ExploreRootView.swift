import SwiftUI

/// 探索页：自然世界 / 古诗小世界 / 看图识字（§9）
struct ExploreRootView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    @EnvironmentObject var learning: LearningRepository
    @EnvironmentObject var games: GameRepository
    @State private var appeared = false
    @State private var discovery: Discovery?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                if let discovery {
                    discoveryCard(discovery)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                }
                entries
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
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
        GlassPageHeader(title: "探索", subtitle: "挑一个喜欢的去看看")
            .padding(.top, 8)
            .opacity(appeared ? 1 : 0)
    }

    private var entries: some View {
        VStack(spacing: 16) {
            NavigationLink {
                NatureRootView()
            } label: {
                GlassEntryCard(module: .nature,
                               detail: "\(content.natureItems.count) 个对象",
                               layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PoemRootView()
            } label: {
                GlassEntryCard(module: .poem,
                               detail: "\(content.poems.count) 首古诗",
                               layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                LearningHomeView()
            } label: {
                GlassEntryCard(module: .learning,
                               detail: "\(learning.numbers.count + learning.pinyins.count) 张卡片",
                               layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    // MARK: - 今日发现：随机推荐一个内容、游戏或古诗词

    private func makeDiscovery() -> Discovery? {
        let makers: [() -> Discovery?] = [
            { content.natureItems.randomElement().map { .nature($0) } },
            { content.poems.randomElement().map { .poem($0) } },
            { learning.numbers.randomElement().map { .number($0) } },
            { learning.pinyins.randomElement().map { .pinyin($0) } },
            { games.playableDefinitions.isEmpty ? nil : .game }
        ]
        return makers.randomElement()?()
    }

    @ViewBuilder
    private func discoveryCard(_ discovery: Discovery) -> some View {
        NavigationLink { discoveryDestination(discovery) } label: {
            HStack(spacing: 16) {
                discoveryIcon(discovery, size: 64)
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(discovery.badge)
                            .font(.system(size: Theme.scaled(12, settings: settings), weight: .bold, design: .rounded))
                            .foregroundStyle(discovery.accent)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(discovery.accent.opacity(0.7))
                    }
                    Text(discovery.title)
                        .font(.system(size: Theme.scaled(18, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(discovery.subtitle)
                        .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .growCard(fill: discovery.accent.opacity(0.18))
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
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
        case .poem(let poem):
            IllustrationView(identifier: poem.illustration)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
        case .number:
            LearningTopicIcon(topic: .numbers, size: size)
        case .pinyin(let item):
            LearningTopicIcon(topic: item.type == .final ? .final : .initial, size: size)
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
