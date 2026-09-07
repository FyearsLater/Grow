import SwiftUI

/// 首页：两个核心入口卡片 + 最近学习 + 设置入口
struct HomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    @EnvironmentObject var library: UserLibrary
    @EnvironmentObject var router: Router
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cream.ignoresSafeArea()
                // 背景轻微动态装饰
                BackgroundBlobs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                        mainCards
                        if !recentItems.isEmpty {
                            RecentSection(items: recentItems)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) {
                    appeared = true
                }
            }
            .navigationDestination(isPresented: $router.showSettings) {
                SettingsView()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Grow")
                .font(.system(size: Theme.scaled(40, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("看一看，听一听，探索身边的世界")
                .font(.system(size: Theme.scaled(15, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // 两个主入口卡片（点击切换到对应 Tab）
    private var mainCards: some View {
        VStack(spacing: 18) {
            Button {
                router.tab = .nature
            } label: {
                HomeEntryCard(
                    symbol: "🌱",
                    title: "自然世界",
                    subtitle: "认识我们身边的自然",
                    colors: [Theme.vegetable.opacity(0.85), Theme.vegetable.opacity(0.55)]
                )
            }
            .buttonStyle(PressableButtonStyle())

            Button {
                router.tab = .poem
            } label: {
                HomeEntryCard(
                    symbol: "📖",
                    title: "古诗小世界",
                    subtitle: "和古诗一起认识四季与生活",
                    colors: [Theme.poemWarm.opacity(0.8), Theme.poemWarm.opacity(0.5)]
                )
            }
            .buttonStyle(PressableButtonStyle())
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var recentItems: [RecentEntry] {
        var list: [RecentEntry] = []
        for id in library.recentNatureIDs.prefix(3) {
            if let item = content.natureItems.first(where: { $0.id == id }) {
                list.append(.init(title: item.nameZh, illustration: item.illustration, kind: .nature(id: item.id, category: item.category)))
            }
        }
        for id in library.recentPoemIDs.prefix(3) {
            if let poem = content.poems.first(where: { $0.id == id }) {
                list.append(.init(title: "《\(poem.title)》", illustration: poem.illustration, kind: .poem(id: poem.id)))
            }
        }
        return list
    }
}

// MARK: - 主入口卡片

struct HomeEntryCard: View {
    @EnvironmentObject var settings: SettingsManager
    let symbol: String
    let title: String
    let subtitle: String
    let colors: [Color]

    var body: some View {
        HStack(spacing: 20) {
            Text(symbol)
                .font(.system(size: 56))
                .frame(width: 84, height: 84)
                .background(Circle().fill(.white.opacity(0.55)))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: Theme.scaled(24, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(22)
        .frame(minHeight: 128 * settings.buttonScaleFactor)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: colors[0].opacity(0.35), radius: 14, y: 8)
    }
}

// MARK: - 背景装饰（极轻动态）

struct BackgroundBlobs: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var drift = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.vegetable.opacity(0.08))
                .frame(width: 220)
                .offset(x: -110, y: -240)
                .offset(y: drift ? 10 : -10)
            Circle()
                .fill(Theme.animal.opacity(0.08))
                .frame(width: 170)
                .offset(x: 120, y: -160)
                .offset(y: drift ? -12 : 12)
            Circle()
                .fill(Theme.fruit.opacity(0.07))
                .frame(width: 150)
                .offset(x: 110, y: 300)
                .offset(y: drift ? 8 : -8)
        }
        .onAppear {
            guard settings.animationOn && !settings.reduceMotion else { return }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - 最近学习

struct RecentEntry: Identifiable {
    enum EntryKind {
        case nature(id: String, category: NatureCategory)
        case poem(id: String)
    }
    let id = UUID()
    let title: String
    let illustration: String
    let kind: EntryKind
}

struct RecentSection: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    let items: [RecentEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近看过")
                .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { entry in
                        NavigationLink {
                            // 直达对应条目的详情页，而不是分类卡组
                            switch entry.kind {
                            case .nature(let id, _):
                                if let item = content.natureItems.first(where: { $0.id == id }) {
                                    NatureDetailView(item: item)
                                } else {
                                    NatureCardDeckView(category: content.natureItems.first(where: { $0.id == id })?.category ?? .fruit)
                                }
                            case .poem(let id):
                                PoemDetailView(poemId: id)
                            }
                        } label: {
                            VStack(spacing: 8) {
                                IllustrationView(identifier: entry.illustration)
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(entry.title)
                                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .frame(minWidth: 96, minHeight: 96)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(.white.opacity(0.75))
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
    }
}
