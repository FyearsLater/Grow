import SwiftUI

/// 找颜色：顶部目标颜色 → 下方 2~4 个自然内容 → 点出该颜色的那个。
/// 2-3 岁口径：大图、大点击区、错误仅轻晃+语音引导，无惩罚（§十五/§十六）。
struct ColorGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = ColorGameEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    /// 详情页「玩一玩」带入的焦点内容（本期颜色游戏按颜色出题，focus 仅用于记录）
    var focus: String? = nil

    @State private var showComplete = false
    @State private var shakeToken = 0

    private var gameLevel: GameLevel? { games.level(gameId: "color", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.color) }

    private var roundCount: Int { levelConfig.rounds ?? 3 }
    private var optionCount: Int { min(max(levelConfig.optionCount ?? 2, 2), 4) }

    var body: some View {
        VStack(spacing: 14) {
            if let round = engine.currentRoundData {
                GameIntroTip(module: module, text: "找出\(round.color.displayName)的")
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                // 目标颜色（大色块 + 中文名，图片+声音 > 文字）
                targetChip(round.color)
                    .padding(.top, 4)

                optionsGrid(round)
            } else {
                Spacer()
                Text("内容准备中…")
                    .font(GrowFont.body(settings))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("找颜色")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .onDisappear { AudioManager.shared.stop() }
        .overlay {
            if showComplete, let hero = engine.lastSolvedItem {
                GameCompleteOverlay(
                    heroItem: hero,
                    accent: module.tint,
                    onReplay: {
                        withAnimation { showComplete = false }
                        engine.reset()
                    },
                    onNext: {
                        withAnimation { showComplete = false }
                        prepareLevel()
                    }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - 目标颜色

    private func targetChip(_ color: ColorDefinition) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.color)
                .frame(width: 92 * settings.pageScaleFactor, height: 92 * settings.pageScaleFactor)
                .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 4))
                .shadow(color: color.color.opacity(0.35), radius: 12, y: 6)
            Text(color.displayName)
                .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: - 选项

    private func optionsGrid(_ round: ColorGameEngine.Round) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                ForEach(round.options) { option in
                    Button { choose(option) } label: {
                        GameOptionCard(item: option.item, state: .normal, showsName: false)
                            .frame(height: 138)
                    }
                    .buttonStyle(PressableButtonStyle(settings: settings))
                    .modifier(GameShakeOnError(shakeToken: shakeToken,
                                               reduceMotion: settings.reduceMotion || !settings.animationOn))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - 交互

    private func choose(_ option: ColorGameEngine.Option) {
        guard !engine.isCompleted else { return }
        if engine.choose(option.id) {
            feedback.correct(gameId: "color", itemName: option.item.nameZh)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.advance()
                if engine.isCompleted {
                    finish(hero: option.item)
                } else {
                    speakCurrentInstruction()
                }
            }
        } else {
            feedback.retry(gameId: "color")
            shakeToken += 1
        }
    }

    // MARK: - 生命周期

    private func setup() {
        prepareLevel()
        speakCurrentInstruction()
    }

    private func prepareLevel() {
        engine.prepare(rounds: roundCount, optionCount: optionCount)
    }

    private func speakCurrentInstruction() {
        guard let round = engine.currentRoundData else { return }
        feedback.speakInstruction("找\(round.color.displayName)", gameId: "color")
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "color", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
