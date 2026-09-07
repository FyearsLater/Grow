import SwiftUI

// MARK: - 趣味游戏首页（小游戏选择页）

/// 结构：页头 → 2×2 可玩游戏大卡 → "最近探索"横条。
/// 本期不上第二优先级占位/禁用卡（颜色/形状/排序/找不同直接不出现——§主理人裁决 4）。
/// Glass 只用于悬浮操作（§约定 7）；卡片主区域用 growCard 实底，清晰明亮。
struct GameHomeView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @EnvironmentObject var content: ContentRepository

    @State private var appeared = false

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible())]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                GlassPageHeader(title: "趣味游戏", subtitle: "玩一玩 · 认一认")
                    .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(games.playableDefinitions) { def in
                        gameCard(def)
                    }
                }

                recentStrip
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("趣味游戏")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(GrowAnimation.appear(settings) ?? .easeOut(duration: 0.01)) { appeared = true }
        }
    }

    // MARK: - 游戏大卡（视觉对齐 GlassEntryCard，但用 growCard 实底）

    @ViewBuilder
    private func gameCard(_ def: GameDefinition) -> some View {
        let module = GameModule.from(def.type)

        Group {
            switch def.type {
            case .puzzle:
                NavigationLink { PuzzleHomeView() } label: { entryCard(def, module: module) }
                    .buttonStyle(PressableButtonStyle(settings: settings))
            case .matching:
                NavigationLink { GameLevelPickerView(type: .matching) } label: { entryCard(def, module: module) }
                    .buttonStyle(PressableButtonStyle(settings: settings))
            case .findSame:
                NavigationLink { GameLevelPickerView(type: .findSame) } label: { entryCard(def, module: module) }
                    .buttonStyle(PressableButtonStyle(settings: settings))
            case .sorting:
                NavigationLink { GameLevelPickerView(type: .sorting) } label: { entryCard(def, module: module) }
                    .buttonStyle(PressableButtonStyle(settings: settings))
            default:
                entryCard(def, module: module).opacity(0.5)
            }
        }
    }

    private func entryCard(_ def: GameDefinition, module: GameModule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            GameModuleIcon(module: module, size: 54)
            Spacer(minLength: 4)
            Text(def.title)
                .font(GrowFont.heading(settings))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(def.description)
                .font(GrowFont.caption(settings))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .frame(minHeight: 156 * settings.buttonScaleFactor)
        .growCard(fill: .white.opacity(0.78))
    }

    // MARK: - 最近探索（空态隐藏；解析 nature 名称展示）

    @ViewBuilder
    private var recentStrip: some View {
        let recents = results.recentExplorations()
        if !recents.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近探索")
                    .font(GrowFont.heading(settings))
                    .foregroundStyle(Theme.ink)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(recents) { recent in
                            if let item = content.natureItems.first(where: { $0.id == recent.contentId }) {
                                VStack(spacing: 6) {
                                    IllustrationView(identifier: item.illustration)
                                        .frame(width: 64, height: 64)
                                    Text(item.nameZh)
                                        .font(.system(size: Theme.scaled(12, settings: settings), weight: .semibold))
                                        .foregroundStyle(Theme.inkSoft)
                                        .lineLimit(1)
                                }
                                .frame(width: 72)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - 游戏难度选择页（配对 / 找相同 / 分类共用；拼图沿用原有难度结构）

/// 统一难度口径（入门/进阶挑战 → L1/L2/L3）；2-3 岁默认档标记"推荐"。
struct GameLevelPickerView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository

    let type: GameType

    private var module: GameModule { GameModule.from(type) }
    private var definition: GameDefinition? { games.definition(ofType: type) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                ForEach(GameDifficultyLevel.allCases) { level in
                    levelRow(level)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle(definition?.title ?? module.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let def = definition {
                GameFeedbackManager.shared.speakInstruction(def.description, gameId: def.id)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            GameModuleIcon(module: module, size: 56)
            Text(definition?.title ?? module.title)
                .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(definition?.description ?? "")
                .font(.system(size: Theme.scaled(14, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func levelRow(_ level: GameDifficultyLevel) -> some View {
        let recommended = games.defaultLevel(of: type) == level.rawValue

        Group {
            switch type {
            case .matching:
                NavigationLink { MatchingGameView(level: level.rawValue) } label: {
                    rowLabel(level, detail: detailText(level), recommended: recommended)
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
            case .findSame:
                NavigationLink { FindSameGameView(level: level.rawValue) } label: {
                    rowLabel(level, detail: detailText(level), recommended: recommended)
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
            case .sorting:
                NavigationLink { SortingGameView(level: level.rawValue) } label: {
                    rowLabel(level, detail: detailText(level), recommended: recommended)
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
            default:
                rowLabel(level, detail: detailText(level), recommended: recommended)
                    .opacity(0.5)
            }
        }
    }

    private func rowLabel(_ level: GameDifficultyLevel, detail: String, recommended: Bool) -> some View {
        HStack(spacing: 18) {
            // 难度徽标
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [module.deepTint, module.deepTint.opacity(0.75)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Text("\(level.rawValue)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(level.displayName)
                        .font(.system(size: Theme.scaled(23, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if recommended {
                        Text("推荐")
                            .font(.system(size: Theme.scaled(12, settings: settings), weight: .bold))
                            .foregroundStyle(module.deepTint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(.white.opacity(0.9)))
                    }
                }
                Text(detail)
                    .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(20)
        .frame(minHeight: 104 * settings.buttonScaleFactor)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient(colors: [module.tint.opacity(0.9), module.tint.opacity(0.6)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: module.tint.opacity(0.32), radius: 12, y: 7)
    }

    /// 各游戏难度口径说明（与引擎实际参数一一对应）
    private func detailText(_ level: GameDifficultyLevel) -> String {
        switch type {
        case .matching:
            switch level {
            case .level1: return "2 组卡片"
            case .level2: return "3 组卡片"
            case .level3: return "3 组 · 长得更像"
            }
        case .findSame:
            switch level {
            case .level1: return "2 个选项"
            case .level2: return "3 个选项"
            case .level3: return "4 个选项 · 长得更像"
            }
        case .sorting:
            switch level {
            case .level1: return "每类 1 件"
            case .level2: return "每类 2 件"
            case .level3: return "每类 3 件"
            }
        default:
            return ""
        }
    }
}
