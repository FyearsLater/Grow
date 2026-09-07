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
        GlassPageHeader(title: "探索", subtitle: "挑一个喜欢的去看看")
            .padding(.top, 8)
            .opacity(appeared ? 1 : 0)
    }

    private var entries: some View {
        VStack(spacing: 16) {
            NavigationLink {
                NatureRootView()
            } label: {
                GlassEntryCard(module: .nature,
                               detail: "\(content.natureItems.count) 个对象",
                               layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                PoemRootView()
            } label: {
                GlassEntryCard(module: .poem,
                               detail: "\(content.poems.count) 首古诗",
                               layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))

            NavigationLink {
                LearningHomeView()
            } label: {
                GlassEntryCard(module: .learning,
                               detail: "\(learning.numbers.count + learning.pinyins.count) 张卡片",
                               layout: .horizontal)
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }
}
