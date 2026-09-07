import SwiftUI

@main
struct GrowApp: App {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var library = UserLibrary.shared
    @StateObject private var audio = AudioManager.shared
    @StateObject private var content = ContentRepository.shared
    @StateObject private var router = Router()
    @StateObject private var learning = LearningRepository.shared
    @StateObject private var puzzles = PuzzleRepository.shared
    @StateObject private var progress = ProgressManager.shared
    @StateObject private var games = GameRepository.shared
    @StateObject private var gameResults = GameResultStore.shared

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(library)
                .environmentObject(audio)
                .environmentObject(content)
                .environmentObject(router)
                .environmentObject(learning)
                .environmentObject(puzzles)
                .environmentObject(progress)
                .environmentObject(games)
                .environmentObject(gameResults)
                .tint(Theme.ink)
                // 儿童应用固定浅色：保证液态玻璃与整体奶白设计一致
                .preferredColorScheme(.light)
        }
    }
}

/// 底部导航：首页 / 探索 / 收藏 / 设置
/// iOS 26+：原生 TabView 自动获得系统 Liquid Glass 标签条（需 iOS 26 SDK 编译）。
/// iOS 17/18 回退：自定义悬浮玻璃胶囊。
struct RootTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var settings: SettingsManager
    @ObservedObject private var voicePrompt = VoicePackPromptCenter.shared

    private let items: [(tab: Router.Tab, title: String, icon: String)] = [
        (.home, "首页", "house.fill"),
        (.explore, "探索", "safari.fill"),
        (.favorites, "收藏", "heart.fill"),
        (.settings, "设置", "gearshape.fill")
    ]

    var body: some View {
        if #available(iOS 26.0, *) {
            nativeTabView
        } else {
            legacyGlassTabView
        }
    }

    /// iOS 26+：标准 TabView，编译即自动采用 Liquid Glass
    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(Router.Tab.home)
            ExploreTabRoot()
                .tabItem { Label("探索", systemImage: "safari.fill") }
                .tag(Router.Tab.explore)
            FavoritesTabRoot()
                .tabItem { Label("收藏", systemImage: "heart.fill") }
                .tag(Router.Tab.favorites)
            SettingsTabRoot()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(Router.Tab.settings)
        }
        .ignoresSafeArea(.keyboard)
        .voicePackPrompt()
    }

    private var legacyGlassTabView: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.tab) {
                HomeView()
                    .tag(Router.Tab.home)
                ExploreTabRoot()
                    .tag(Router.Tab.explore)
                FavoritesTabRoot()
                    .tag(Router.Tab.favorites)
                SettingsTabRoot()
                    .tag(Router.Tab.settings)
            }
            .toolbar(.hidden, for: .tabBar)

            glassTabBar
        }
        .ignoresSafeArea(.keyboard)
        .voicePackPrompt()
    }

    private var glassTabBar: some View {
        VStack(spacing: 0) {
            Spacer()
            HStack(spacing: 0) {
                Spacer()
                ZStack {
                    // 液态玻璃：毛玻璃底 + 顶部高光 + 内描边 + 柔和投影
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.55), .white.opacity(0.10), .white.opacity(0.30)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.85), .white.opacity(0.25)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1
                        )

                    // 选中高亮背景
                    GeometryReader { geo in
                        let width = geo.size.width / CGFloat(items.count)
                        let x = width * CGFloat(items.firstIndex(where: { $0.tab == router.tab }) ?? 0)
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.vegetable.opacity(0.85), Theme.vegetable.opacity(0.60)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(.white.opacity(0.45), lineWidth: 1)
                            )
                            .shadow(color: Theme.vegetable.opacity(0.35), radius: 8, y: 4)
                            .frame(width: width - 12, height: geo.size.height - 12)
                            .position(x: x + width / 2, y: geo.size.height / 2)
                            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: router.tab)
                    }

                    HStack(spacing: 0) {
                        ForEach(items, id: \.tab) { item in
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    router.tab = item.tab
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 19, weight: .semibold))
                                        .symbolEffect(.bounce, value: router.tab == item.tab)
                                    Text(item.title)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(router.tab == item.tab ? .white : Theme.inkSoft)
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 64)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                Spacer()
            }
        }
    }
}

/// 设置：独立 Tab 根视图（v0.4.0 起从首页右上角移入底部导航）
struct SettingsTabRoot: View {
    var body: some View {
        NavigationStack {
            SettingsView()
        }
    }
}

/// 未下载自然语音包时点朗读 → 弹窗引导（去下载 / 暂不）
struct VoicePackPromptModifier: ViewModifier {
    @EnvironmentObject var router: Router
    @ObservedObject var center = VoicePackPromptCenter.shared

    func body(content: Content) -> some View {
        content.alert(item: $center.request) { req in
            let size = VoicePack.all.first { $0.languages.contains(req.language) }?.estimatedMB ?? "数十 MB"
            return Alert(
                title: Text("需要下载语音包"),
                message: Text("朗读「\(req.sampleText)」需要先在 设置 → 自然语音库 下载对应语音包（约 \(size)）。下载需要联网，建议在 Wi-Fi 下进行；下载一次后离线可用，发音远比系统语音自然。"),
                primaryButton: .default(Text("去下载")) {
                    router.tab = .settings
                    // 直接开始下载对应语音包，不用用户再手动找（支持断点续传）
                    if let pack = VoicePack.all.first(where: { $0.languages.contains(req.language) }) {
                        VoicePackManager.shared.download(pack)
                    }
                },
                secondaryButton: .cancel(Text("暂不"))
            )
        }
    }
}

extension View {
    func voicePackPrompt() -> some View { modifier(VoicePackPromptModifier()) }
}

/// Tab 根视图：各自持有独立 NavigationStack（独立于首页的跳转路径）
struct NatureTabRoot: View {
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack(path: $router.naturePath) {
            NatureRootView()
                .navigationDestination(for: Router.NatureRoute.self) { route in
                    switch route {
                    case .deck(let category):
                        NatureCardDeckView(category: category)
                    case .item(let id):
                        if let item = ContentRepository.shared.natureItems.first(where: { $0.id == id }) {
                            NatureDetailView(item: item)
                        }
                    }
                }
        }
    }
}

struct PoemTabRoot: View {
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack(path: $router.poemPath) {
            PoemRootView()
                .navigationDestination(for: Router.PoemRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        PoemDetailView(poemId: id)
                    }
                }
        }
    }
}

struct FavoritesTabRoot: View {
    var body: some View {
        NavigationStack {
            FavoritesView()
        }
    }
}

/// 探索：自然世界 / 古诗小世界 / 看图识字（§9，未来可继续加入英语、汉字等）
struct ExploreTabRoot: View {
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack(path: $router.explorePath) {
            ExploreRootView()
                .navigationDestination(for: Router.ExploreRoute.self) { route in
                    switch route {
                    case .natureDeck(let category):
                        NatureCardDeckView(category: category)
                    case .natureItem(let id):
                        if let item = ContentRepository.shared.natureItems.first(where: { $0.id == id }) {
                            NatureDetailView(item: item)
                        }
                    case .poemDetail(let id):
                        PoemDetailView(poemId: id)
                    case .pinyin(let type):
                        PinyinView(type: type)
                    case .numbers:
                        NumberView()
                    case .natureRoot:
                        NatureRootView()
                    case .poemRoot:
                        PoemRootView()
                    case .learningRoot:
                        LearningHomeView()
                    }
                }
        }
    }
}

