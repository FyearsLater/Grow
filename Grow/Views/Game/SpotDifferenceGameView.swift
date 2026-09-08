import SwiftUI

/// 找不同：4~6 个物体，其中 1 个不一样，点出不同的那个。
/// L1 差异明显（跨类别），L3 同类近似；不做成人式细节找茬（§十二）。
struct SpotDifferenceGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = SpotDifferenceEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    /// 详情页焦点内容（第一轮当"异类"）
    var focus: String? = nil

    @State private var showComplete = false
    @State private var shakeToken = 0

    private var gameLevel: GameLevel? { games.level(gameId: "spotdifference", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.spotDifference) }

    /// 物体总数：L1=4 / L2=5 / L3=6
    private var objectCount: Int {
        min(max(levelConfig.optionCount ?? 4, 4), 6)
    }
    private var roundCount: Int { levelConfig.rounds ?? 3 }
    /// L3 起用同类近似物（差异更小）
    private var sameCategory: Bool { levelConfig.sameCategoryDistractors ?? false }

    private var columns: Int { objectCount >= 6 ? 3 : 2 }

    var body: some View {
        VStack(spacing: 14) {
            GameIntroTip(module: module, text: "找出不一样的")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if let round = engine.currentRoundData {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns),
                              spacing: 14) {
                        ForEach(round.options) { option in
                            Button { choose(option) } label: {
                                GameOptionCard(item: option.item, state: .normal, showsName: false)
                                    .frame(height: columns == 3 ? 118 : 138)
                            }
                            .buttonStyle(PressableButtonStyle(settings: settings))
                            .modifier(GameShakeOnError(shakeToken: shakeToken,
                                                       reduceMotion: settings.reduceMotion || !settings.animationOn))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
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
        .navigationTitle("找不同")
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

    // MARK: - 交互

    private func choose(_ option: SpotDifferenceEngine.Option) {
        guard !engine.isCompleted else { return }
        if engine.choose(option.id) {
            feedback.correct(gameId: "spotdifference", itemName: option.item.nameZh)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.advance()
                if engine.isCompleted { finish(hero: option.item) }
            }
        } else {
            feedback.retry(gameId: "spotdifference")
            shakeToken += 1
        }
    }

    private func setup() {
        prepareLevel()
        feedback.speakInstruction("找出不一样的", gameId: "spotdifference")
    }

    private func prepareLevel() {
        let pool = GameContentResolver.shared.getContents(for: .spotDifference)
        let focusItem = focus.flatMap { focusID in pool.first { $0.id == focusID } }
        engine.prepare(rounds: roundCount, optionCount: objectCount,
                       sameCategory: sameCategory, focus: focusItem)
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "spotdifference", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
