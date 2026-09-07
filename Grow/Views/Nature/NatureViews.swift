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
                .foregroundStyle(Theme.textPrimary)
            Text("\(count) 个")
                .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180 * settings.pageScaleFactor)
        .glassCard(tint: Theme.categoryColor(category), tintOpacity: 0.18)
    }
}

/// 分类下的大卡片浏览：整页左右翻页（与数字/拼音页同一交互，无邻卡灰边）
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
                    TabView(selection: $index) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                            NavigationLink {
                                NatureDetailView(item: item)
                            } label: {
                                NatureCardFace(item: item)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .padding(.horizontal, 20)
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

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
        .onChange(of: index) { _, newValue in
            // 记录当前实际看到的卡片
            if items.indices.contains(newValue) {
                library.recordNatureVisit(items[newValue].id)
            }
        }
    }
}

/// 单张自然卡片正面：大插画 + 中文名（旁附收藏）+ 英文名 + 三语按钮
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
                HStack(spacing: 10) {
                    Text(item.nameZh)
                        .font(.system(size: Theme.scaled(32, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    FavoriteButton(kind: .nature, id: item.id)
                }
                Text(item.nameEn)
                    .font(.system(size: Theme.scaled(18, settings: settings), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
            }

            LanguageButtonsRow(name: item.nameZh, nameEn: item.nameEn, itemKey: item.id)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.52)
        .glassCard()
    }
}
