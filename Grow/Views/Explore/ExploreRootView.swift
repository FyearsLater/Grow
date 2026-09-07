import SwiftUI

/// 探索页：自然世界 / 古诗小世界 / 看图识字（§9）
struct ExploreRootView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var content: ContentRepository
    @EnvironmentObject var learning: LearningRepository
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
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
            withAnimation(.easeOut(duration: 0.35)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("探索")
                    .font(.system(size: Theme.scaled(28, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("挑一个喜欢的去看看")
                    .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Text("🧭")
                .font(.system(size: 40))
        }
        .padding(.top, 8)
        .opacity(appeared ? 1 : 0)
    }

    private var entries: some View {
        VStack(spacing: 16) {
            NavigationLink {
                NatureRootView()
            } label: {
                GlassEntryCard(symbol: "🌱", title: "自然世界", subtitle: "认识身边的自然",
                               detail: "\(content.natureItems.count) 个对象",
                               tint: Theme.vegetable, layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PoemRootView()
            } label: {
                GlassEntryCard(symbol: "📖", title: "古诗小世界", subtitle: "和古诗一起探索",
                               detail: "\(content.poems.count) 首古诗",
                               tint: Theme.poemWarm, layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                LearningHomeView()
            } label: {
                GlassEntryCard(symbol: "🔤", title: "看图识字", subtitle: "数字 · 拼音",
                               detail: "\(learning.numbers.count + learning.pinyins.count) 张卡片",
                               tint: Theme.fruit, layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }
}
