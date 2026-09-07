import SwiftUI

@main
struct GrowApp: App {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var library = UserLibrary.shared
    @StateObject private var audio = AudioManager.shared
    @StateObject private var content = ContentRepository.shared
    @StateObject private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(library)
                .environmentObject(audio)
                .environmentObject(content)
                .environmentObject(router)
                .tint(Theme.ink)
                // 儿童应用固定浅色：保证液态玻璃与整体奶白设计一致
                .preferredColorScheme(.light)
        }
    }
}

/// 底部导航：首页 / 自然 / 古诗 / 收藏
/// iOS 26 液态玻璃风格：悬浮胶囊、毛玻璃底、选中高亮。
struct RootTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var settings: SettingsManager

    private let items: [(tab: Router.Tab, title: String, icon: String)] = [
        (.home, "首页", "house.fill"),
        (.nature, "自然", "leaf.fill"),
        (.poem, "古诗", "book.fill"),
        (.favorites, "收藏", "heart.fill")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $router.tab) {
                HomeView()
                    .tag(Router.Tab.home)
                NatureTabRoot()
                    .tag(Router.Tab.nature)
                PoemTabRoot()
                    .tag(Router.Tab.poem)
                FavoritesTabRoot()
                    .tag(Router.Tab.favorites)
            }
            .toolbar(.hidden, for: .tabBar)

            glassTabBar
        }
        .ignoresSafeArea(.keyboard)
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
