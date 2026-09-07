import SwiftUI

/// 我的收藏：自然对象 + 古诗
struct FavoritesView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var library: UserLibrary
    @EnvironmentObject var content: ContentRepository

    private var favoriteNature: [NatureItem] {
        content.natureItems.filter { library.favoriteNatureIDs.contains($0.id) }
    }

    private var favoritePoems: [Poem] {
        content.poems.filter { library.favoritePoemIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("我的收藏")
                        .font(.system(size: Theme.scaled(30, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 8)

                    if favoriteNature.isEmpty && favoritePoems.isEmpty {
                        emptyState
                    }

                    if !favoriteNature.isEmpty {
                        sectionHeader("🌱 认识的东西")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 14)], spacing: 14) {
                            ForEach(favoriteNature) { item in
                                NavigationLink {
                                    NatureDetailView(item: item)
                                } label: {
                                    FavoriteNatureCell(item: item)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }

                    if !favoritePoems.isEmpty {
                        sectionHeader("📖 喜欢的诗")
                        VStack(spacing: 14) {
                            ForEach(favoritePoems) { poem in
                                NavigationLink {
                                    PoemDetailView(poemId: poem.id)
                                } label: {
                                    PoemListCard(poem: poem)
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart")
                .font(.system(size: 44))
                .foregroundStyle(Theme.inkSoft.opacity(0.4))
            Text("还没有收藏哦")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.inkSoft)
            Text("看到喜欢的东西，点一下 ❤️ 收藏起来")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSoft.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .growCard()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Theme.scaled(17, settings: settings), weight: .bold, design: .rounded))
            .foregroundStyle(Theme.ink)
    }
}

struct FavoriteNatureCell: View {
    @EnvironmentObject var settings: SettingsManager
    let item: NatureItem

    var body: some View {
        VStack(spacing: 8) {
            IllustrationView(identifier: item.illustration)
                .frame(width: 76, height: 76)
            Text(item.nameZh)
                .font(.system(size: Theme.scaled(15, settings: settings), weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .growCard(radius: 22)
    }
}
