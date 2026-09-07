import SwiftUI

/// 找相同游戏页：顶部目标大图 + 2~6 选项，点选与目标相同的图。
/// 逻辑在 FindSameEngine；点对推进、点错仅轻晃+语音引导。
struct FindSameGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = FindSameEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    /// 详情页「找相同」带来的焦点对象（作为第一轮目标）
    var focus: String? = nil

    @State private var showComplete = false
    @State private var shakeToken = 0

    private var gameLevel: GameLevel? { games.level(gameId: "findsame", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.findSame) }

    /// 选项列数：L1/L2 两列，L3 三列（选项多）
    private var optionColumns: Int {
        (levelConfig.optionCount ?? 2) >= 5 ? 3 : 2
    }

    var body: some View {
        VStack(spacing: 14) {
            GameIntroTip(module: module, text: "找出和它一样的")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if let round = engine.currentRoundData {
                // 目标（上 40%）
                GameOptionCard(item: round.target, state: .normal, showsName: false)
                    .frame(maxWidth: 320)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 24)

                // 选项网格（下半）
                optionsGrid(round)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("找相同")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .onDisappear {
            AudioManager.shared.stop()
        }
        .overlay {
            if showComplete, let hero = engine.lastSolvedTarget {
                GameCompleteOverlay(
                    heroItem: hero,
                    accent: module.tint,
                    onReplay: {
                        withAnimation { showComplete = false }
                        engine.reset()
                    },
                    onNext: {
                        withAnimation { showComplete = false }
                        // "下一项" = 同关换一批目标重新开
                        prepareLevel()
                    }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - 选项网格

    private func optionsGrid(_ round: FindSameEngine.Round) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: optionColumns),
                      spacing: 14) {
                ForEach(round.options) { option in
                    Button {
                        choose(option)
                    } label: {
                        GameOptionCard(item: option.item, state: cardState(option), showsName: false)
                            .frame(height: optionColumns == 3 ? 118 : 138)
                    }
                    .buttonStyle(PressableButtonStyle(settings: settings))
                    .modifier(ShakeOnError(shakeToken: shakeToken,
                                           reduceMotion: settings.reduceMotion || !settings.animationOn))
                    .disabled(option.state == .correct)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    private func cardState(_ option: FindSameEngine.Option) -> GameCardState {
        switch option.state {
        case .normal: return .normal
        case .correct: return .correct
        case .wrong: return .wrong
        }
    }

    // MARK: - 交互

    private func choose(_ option: FindSameEngine.Option) {
        guard !engine.isCompleted else { return }
        if engine.choose(option.id) {
            GameSound.correct.play()
            feedback.correct(gameId: "findsame", itemName: option.item.nameZh)
            // 自动进入下一轮（留出朗读/打勾时间）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.advance()
                if engine.isCompleted { finish(hero: option.item) }
            }
        } else {
            feedback.retry(gameId: "findsame")
            shakeToken += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                engine.clearWrongStates()
            }
        }
    }

    // MARK: - 生命周期

    private func setup() {
        prepareLevel()
        feedback.speakInstruction("找出和它一样的", gameId: "findsame")
    }

    private func prepareLevel() {
        let pool = games.natureItems(for: gameLevel?.contentIds ?? [])
        guard !pool.isEmpty else { return }
        let targets: [NatureItem]
        if let focus, let focusItem = games.natureItem(id: focus) {
            // 焦点对象当第一轮目标，其余从池中补
            let rest = pool.filter { $0.id != focusItem.id }
            targets = [focusItem] + rest
        } else {
            targets = pool
        }
        let allNature = games.items(in: .fruit) + games.items(in: .vegetable)
            + games.items(in: .animal) + games.items(in: .plant)
        let sameCategory = levelConfig.sameCategoryDistractors ?? false
        engine.prepare(targets: targets,
                       pool: allNature,
                       rounds: levelConfig.rounds ?? 3,
                       optionCount: levelConfig.optionCount ?? 2,
                       sameCategoryDistractors: sameCategory,
                       orderedTargets: focus != nil)
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "findsame", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}

// MARK: - 错误轻晃修饰器（Reduce Motion / 关闭动画时不晃）

/// token 变化时做一次水平轻晃（错误引导），门控减弱动态效果
private struct ShakeOnError: ViewModifier {
    let shakeToken: Int
    let reduceMotion: Bool
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .modifier(GameShakeEffect(progress: progress))
                .onChange(of: shakeToken) { _, _ in
                    progress = 0
                    withAnimation(.easeInOut(duration: 0.4)) { progress = 1 }
                }
        }
    }
}
