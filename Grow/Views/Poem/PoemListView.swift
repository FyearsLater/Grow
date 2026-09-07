import SwiftUI

/// 古诗小世界：列表 + 分类筛选
struct PoemRootView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    @State private var selectedCategory: PoemCategory?

    private var filtered: [Poem] {
        guard let c = selectedCategory else { return content.poems }
        return content.poems.filter { $0.categories.contains(c) }
    }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("古诗小世界")
                        .font(.system(size: Theme.scaled(30, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.top, 8)

                    // 分类筛选（去 Emoji：模拟器上 Emoji 显示「?」，只留文字）
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryChip(nil, name: "全部")
                            ForEach(PoemCategory.allCases) { c in
                                categoryChip(c, name: c.displayName)
                            }
                        }
                    }

                    // 诗卡列表
                    VStack(spacing: 14) {
                        ForEach(filtered) { poem in
                            NavigationLink {
                                PoemDetailView(poemId: poem.id)
                            } label: {
                                PoemListCard(poem: poem)
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

    private func categoryChip(_ c: PoemCategory?, name: String) -> some View {
        let selected = selectedCategory == c
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedCategory = c }
        } label: {
            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(selected ? Theme.poemAccent.opacity(0.85) : Color.white.opacity(0.8))
                )
                .foregroundStyle(selected ? .white : Theme.inkSoft)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PoemListCard: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var library: UserLibrary
    let poem: Poem

    var body: some View {
        HStack(spacing: 16) {
            // 小插画缩略
            IllustrationView(identifier: poem.illustration)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("《\(poem.title)》")
                    .font(.system(size: Theme.scaled(20, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("\(poem.dynasty) · \(poem.author)")
                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
                HStack(spacing: 6) {
                    ForEach(poem.categories.prefix(2)) { c in
                        Text(c.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Theme.poemAccent.opacity(0.12)))
                            .foregroundStyle(Theme.poemAccent)
                    }
                }
            }
            Spacer()
            if library.favoritePoemIDs.contains(poem.id) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.heart)
            }
        }
        .padding(16)
        .growCard(fill: Theme.poemPaper)
    }
}
