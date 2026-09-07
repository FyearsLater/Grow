import SwiftUI

/// 自然世界：四个大分类卡片
struct NatureRootView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible())]

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("自然世界")
                        .font(.system(size: Theme.scaled(30, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(NatureCategory.allCases) { category in
                            NavigationLink {
                                NatureCardDeckView(category: category)
                            } label: {
                                CategoryCard(category: category, count: content.items(in: category).count)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

struct CategoryCard: View {
    @EnvironmentObject var settings: SettingsManager
    let category: NatureCategory
    let count: Int

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.55))
                    .frame(width: 76, height: 76)
                Text(category.symbol)
                    .font(.system(size: 46))
            }
            Text(category.displayName)
                .font(.system(size: Theme.scaled(20, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text("\(count) 个")
                .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180 * settings.pageScaleFactor)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.categoryColor(category).opacity(0.28))
        )
        .shadow(color: Theme.categoryColor(category).opacity(0.2), radius: 10, y: 6)
    }
}

/// 分类下的大卡片浏览：左右滑动，能看到下一张卡的一部分
struct NatureCardDeckView: View {
    @EnvironmentObject var content: ContentRepository
    @EnvironmentObject var library: UserLibrary
    @EnvironmentObject var audio: AudioManager
    let category: NatureCategory

    @State private var index = 0

    private var items: [NatureItem] { content.items(in: category) }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if items.isEmpty {
                Text("内容制作中…")
                    .foregroundStyle(Theme.inkSoft)
            } else {
                VStack(spacing: 8) {
                    // 横向滑动卡片，两侧露出下一张的一部分
                    ScrollView(.horizontal) {
                        HStack(spacing: 16) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                                NavigationLink {
                                    NatureDetailView(item: item)
                                } label: {
                                    NatureCardFace(item: item)
                                }
                                .buttonStyle(PressableButtonStyle())
                                .frame(width: cardWidth)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: scrollPosition)
                    .scrollIndicators(.hidden)
                    .padding(.horizontal, sideInset)

                    // 页点
                    HStack(spacing: 8) {
                        ForEach(0..<items.count, id: \.self) { i in
                            Capsule()
                                .fill(i == index ? Theme.categoryColor(category) : Theme.inkSoft.opacity(0.2))
                                .frame(width: i == index ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: index)
                        }
                    }
                    .padding(.bottom, 8)

                    Text("左右滑动，看更多")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.inkSoft.opacity(0.7))
                }
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let first = items.first {
                library.recordNatureVisit(first.id)
            }
        }
    }

    // scrollPosition 绑定
    private var scrollPosition: Binding<String?> {
        Binding(
            get: { items.indices.contains(index) ? items[index].id : nil },
            set: { newValue in
                if let id = newValue, let i = items.firstIndex(where: { $0.id == id }) {
                    index = i
                    // 记录当前实际看到的卡片（之前误记了 first）
                    library.recordNatureVisit(items[i].id)
                }
            }
        )
    }

    private var sideInset: CGFloat { UIScreen.main.bounds.width * 0.08 }
    private var cardWidth: CGFloat { UIScreen.main.bounds.width * 0.78 }
}

/// 单张自然卡片正面：大插画 + 中文名 + 英文名 + 三语按钮
struct NatureCardFace: View {
    @EnvironmentObject var settings: SettingsManager
    let item: NatureItem

    var body: some View {
        VStack(spacing: 16) {
            IllustrationView(identifier: item.illustration)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            VStack(spacing: 4) {
                Text(item.nameZh)
                    .font(.system(size: Theme.scaled(32, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(item.nameEn)
                    .font(.system(size: Theme.scaled(18, settings: settings), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }

            LanguageButtonsRow(name: item.nameZh, nameEn: item.nameEn, itemKey: item.id)

            Spacer(minLength: 0)
        }
        .frame(width: UIScreen.main.bounds.width * 0.78)
        .frame(height: UIScreen.main.bounds.height * 0.52)
        .growCard()
        .overlay(alignment: .topTrailing) {
            FavoriteButton(kind: .nature, id: item.id)
                .padding(10)
        }
    }
}
