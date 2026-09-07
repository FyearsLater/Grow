import SwiftUI

/// 首页：儿童探索空间（Liquid Glass 设计语言，§1-§17）
/// 统一玻璃卡片体系 + 柔和低饱和主题色 + 大量留白
struct HomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    @EnvironmentObject var library: UserLibrary
    @EnvironmentObject var router: Router
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 柔和渐变背景（§13：微弱渐变 + 空间感，不抢内容）
                LinearGradient(colors: [Theme.homeBgTop, Theme.homeBgBottom],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                BackgroundBlobs()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        mainCards
                        if !recentItems.isEmpty {
                            RecentSection(items: recentItems)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        GlassIconBadge(systemName: "gearshape", size: 40, iconSize: 15)
                    }
                    .buttonStyle(GlassButtonStyle(settings: settings))
                }
            }
            .onAppear {
                withAnimation(GrowAnimation.appear(settings) ?? .easeOut(duration: 0.01)) {
                    appeared = true
                }
            }
            .navigationDestination(isPresented: $router.showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - 品牌头部：轻 Logo + 轻字重副标题（§5）

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // 品牌小叶子：与自然主题呼应，替换巨大粗体 Logo
                ZStack {
                    Circle()
                        .fill(Theme.softGreen.opacity(0.4))
                        .frame(width: 26, height: 26)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.deepGreen)
                }
                Text("Grow")
                    .font(GrowFont.title(settings))
                    .tracking(1)
                    .foregroundStyle(Theme.textPrimary)
            }
            Text("看一看，听一听，探索身边的世界")
                .font(GrowFont.caption(settings))
                .tracking(2.5)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 12)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - 四个核心入口：统一玻璃卡片（§6）

    private var mainCards: some View {
        let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

        return LazyVGrid(columns: columns, spacing: 16) {
            NavigationLink {
                NatureRootView()
            } label: {
                GlassEntryCard(module: .nature)
            }
            .buttonStyle(GlassButtonStyle(settings: settings))

            NavigationLink {
                PoemRootView()
            } label: {
                GlassEntryCard(module: .poem)
            }
            .buttonStyle(GlassButtonStyle(settings: settings))

            NavigationLink {
                LearningHomeView()
            } label: {
                GlassEntryCard(module: .learning)
            }
            .buttonStyle(GlassButtonStyle(settings: settings))

            NavigationLink {
                PuzzleHomeView()
            } label: {
                GlassEntryCard(module: .puzzle)
            }
            .buttonStyle(GlassButtonStyle(settings: settings))
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

// MARK: - 背景装饰（极轻动态，低存在感）

struct BackgroundBlobs: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var drift = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.softGreen.opacity(0.16))
                .frame(width: 260)
                .blur(radius: 30)
                .offset(x: -120, y: -260)
                .offset(y: drift ? 10 : -10)
            Circle()
                .fill(Theme.softBlue.opacity(0.16))
                .frame(width: 210)
                .blur(radius: 30)
                .offset(x: 130, y: -170)
                .offset(y: drift ? -12 : 12)
            Circle()
                .fill(Theme.softLilac.opacity(0.12))
                .frame(width: 180)
                .blur(radius: 30)
                .offset(x: 120, y: 320)
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
                .font(GrowFont.heading(settings))
                .foregroundStyle(Theme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
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
                                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                                Text(entry.title)
                                    .font(GrowFont.caption(settings).weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(minWidth: 72, minHeight: 72)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(GlassButtonStyle(settings: settings))
                    }
                }
            }
        }
    }
}
