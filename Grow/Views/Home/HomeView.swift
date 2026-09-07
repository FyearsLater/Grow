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

    // 四个主入口：2 × 2 玻璃卡片布局（§6 / §7 / §11）
    private var mainCards: some View {
        let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

        return LazyVGrid(columns: columns, spacing: 16) {
            NavigationLink {
                NatureRootView()
            } label: {
                GlassEntryCard(symbol: "🌱", title: "自然世界", subtitle: "认识身边的自然",
                               tint: Theme.vegetable)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PoemRootView()
            } label: {
                GlassEntryCard(symbol: "📖", title: "古诗小世界", subtitle: "和古诗一起探索",
                               tint: Theme.poemWarm)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                LearningHomeView()
            } label: {
                GlassEntryCard(symbol: "🔤", title: "看图识字", subtitle: "数字 · 拼音",
                               tint: Theme.fruit)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PuzzleHomeView()
            } label: {
                GlassEntryCard(symbol: "🧩", title: "趣味拼图", subtitle: "动手拼一拼",
                               tint: Theme.plant)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
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
                            // 无边框无底色：缩略图 + 名称，保持背景干净
                            VStack(spacing: 8) {
                                IllustrationView(identifier: entry.illustration)
                                    .frame(width: 58, height: 58)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                                Text(entry.title)
                                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                            }
                            .frame(minWidth: 72, minHeight: 72)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }
        }
    }
}
