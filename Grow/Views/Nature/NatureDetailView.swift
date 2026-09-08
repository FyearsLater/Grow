import SwiftUI

/// 自然对象详情：大图 + 三语发音 + 折叠简介（按年龄模式显示不同内容）+ 玩一玩入口
struct NatureDetailView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var audio: AudioManager
    let item: NatureItem

    @State private var showMore = false

    private var descriptionKey: String { "\(item.id)-desc" }
    private var descriptionText: String {
        settings.prefersLongDescription ? item.descriptionLong : item.descriptionShort
    }
    private var gameLevel: Int { settings.ageMode == .toddler ? 1 : 2 }

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 主图（占页面约 50%）
                    IllustrationView(identifier: item.illustration)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)

                    // 名称（与卡片页统一：收藏按钮在名称旁）
                    VStack(spacing: 4) {
                        HStack(spacing: 10) {
                            Text(item.nameZh)
                                .font(.system(size: Theme.scaled(38, settings: settings), weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.ink)
                            FavoriteButton(kind: .nature, id: item.id)
                        }
                        Text(item.nameEn)
                            .font(.system(size: Theme.scaled(20, settings: settings), weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.inkSoft)
                    }

                    // 双语发音（国/粤；读完后自动继续朗读介绍）
                    LanguageButtonsRow(
                        name: item.nameZh,
                        nameEn: item.nameEn,
                        itemKey: "\(item.id)-detail",
                        languages: [.mandarin, .cantonese],
                        onFinished: { speakDescription() }
                    )

                    // 简介折叠卡片
                    descriptionCard

                    // 玩一玩（Phase 5：跨 Tab 直达游戏）
                    playSection

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationTitle(item.nameZh)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 记录最近学习
            UserLibrary.shared.recordNatureVisit(item.id)
        }
        .onDisappear {
            audio.stop()
        }
    }

    private func speakDescription() {
        audio.speak(name: descriptionText, language: settings.defaultLanguage, key: descriptionKey)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("了解更多")
                    .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                if audio.playingKey == descriptionKey {
                    WaveIndicator(active: true, color: Theme.categoryColor(item.category))
                }
                Spacer()
            }

            Text(descriptionText)
                .font(.system(size: Theme.scaled(17, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(6)
                .opacity(showMore ? 1 : (settings.prefersLongDescription ? 0.85 : 1))

            if settings.prefersLongDescription {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showMore.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showMore ? "收起" : "展开")
                        Image(systemName: showMore ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.categoryColor(item.category))
                    .frame(minHeight: 44)
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    // MARK: - 玩一玩（按内容属性动态生成，§七：不支持的游戏不显示）

    private var playSection: some View {
        let supported = GameContentResolver.shared.supportedGames(for: item)
        return VStack(alignment: .leading, spacing: 12) {
            Text("玩一玩")
                .font(.system(size: Theme.scaled(16, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)

            if supported.isEmpty {
                Text("这个内容暂时还没有关联的小游戏")
                    .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(supported, id: \.self) { type in
                        playLink(type)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .growCard(fill: .white.opacity(0.7))
    }

    /// 单游戏入口：图标 + 名称，按类型动态路由到对应游戏页（focus 带入当前内容）
    private func playLink(_ type: GameType) -> some View {
        let module = GameModule.from(type)
        return NavigationLink(destination: gameDestination(for: type)) {
            VStack(spacing: 6) {
                GameModuleIcon(module: module, size: 32)
                Text(playTitle(for: type))
                    .font(.system(size: Theme.scaled(15, settings: settings), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 76 * settings.buttonScaleFactor)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(module.tint.opacity(0.35))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(module.tint.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(PressableButtonStyle(settings: settings))
        .accessibilityHint("去玩\(playTitle(for: type))")
    }

    @ViewBuilder
    private func gameDestination(for type: GameType) -> some View {
        switch type {
        case .puzzle:        PuzzleHomeView()
        case .findSame:      FindSameGameView(level: gameLevel, focus: item.id)
        case .matching:      MatchingGameView(level: gameLevel, focus: item.id)
        case .sorting:       SortingGameView(level: gameLevel)
        case .color:         ColorGameView(level: gameLevel, focus: item.id)
        case .shape:         ShapeGameView(level: gameLevel, focus: item.id)
        case .ordering:      SizeOrderingGameView(level: gameLevel, focus: item.id)
        case .counting:      CountingGameView(level: gameLevel, focus: item.id)
        case .spotDifference: SpotDifferenceGameView(level: gameLevel, focus: item.id)
        }
    }

    private func playTitle(for type: GameType) -> String {
        switch type {
        case .puzzle:        return "拼一拼"
        case .findSame:      return "找相同"
        case .matching:      return "找朋友"
        case .sorting:       return "分一分"
        case .color:         return "找颜色"
        case .shape:         return "找形状"
        case .ordering:      return "排一排"
        case .counting:      return "数一数"
        case .spotDifference: return "找不同"
        }
    }
}
