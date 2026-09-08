import SwiftUI

/// 数一数：显示 N 个物品 → 下方 1/2/3 → 选出正确数量。
/// 与「看图识字 0-9」区分：本阶段只训练 1–3，区间来自内容 countingRange（§四/§十一）。
struct CountingGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = CountingEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    /// 详情页焦点内容（第一轮强制数它）
    var focus: String? = nil

    @State private var showComplete = false
    @State private var shakeToken = 0

    private var gameLevel: GameLevel? { games.level(gameId: "counting", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.counting) }

    private var roundCount: Int { levelConfig.rounds ?? 3 }
    private var optionCount: Int { min(max(levelConfig.optionCount ?? 3, 2), 3) }

    var body: some View {
        VStack(spacing: 16) {
            GameIntroTip(module: module, text: "有几个呀？数一数")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            if let round = engine.currentRoundData {
                // 物品群（同一素材重复 N 次，不新增图片）
                VStack(spacing: 10) {
                    RepeatedItemView(item: round.item, count: round.count, maxWidth: 300)
                        .padding(18)
                        .growCard(fill: .white.opacity(0.8), radius: 26)

                    Text(round.item.nameZh)
                        .font(.system(size: Theme.scaled(20, settings: settings), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }

                numberOptions
            } else {
                Spacer()
                Text("内容准备中…")
                    .font(GrowFont.body(settings))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("数一数")
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

    // MARK: - 数字选项（大按钮，2-3 岁友好）

    private var numberOptions: some View {
        HStack(spacing: 16) {
            if let round = engine.currentRoundData {
                ForEach(round.options, id: \.self) { value in
                    Button { choose(value) } label: {
                        Text("\(value)")
                            .font(.system(size: Theme.scaled(40, settings: settings), weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 92 * settings.buttonScaleFactor)
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(module.tint.opacity(0.45))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .strokeBorder(module.deepTint.opacity(0.5), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(PressableButtonStyle(settings: settings))
                    .modifier(GameShakeOnError(shakeToken: shakeToken,
                                               reduceMotion: settings.reduceMotion || !settings.animationOn))
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - 交互

    private func choose(_ value: Int) {
        guard !engine.isCompleted, let round = engine.currentRoundData else { return }
        if engine.choose(value) {
            feedback.correct(gameId: "counting", itemName: "\(round.count)个\(round.item.nameZh)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.advance()
                if engine.isCompleted {
                    finish(hero: round.item)
                }
            }
        } else {
            feedback.retry(gameId: "counting")
            shakeToken += 1
        }
    }

    private func setup() {
        prepareLevel()
        feedback.speakInstruction("有几个呀？数一数", gameId: "counting")
    }

    private func prepareLevel() {
        let pool = GameContentResolver.shared.getContents(for: .counting)
        let focusItem = focus.flatMap { focusID in pool.first { $0.id == focusID } }
        engine.prepare(rounds: roundCount, optionCount: optionCount, focus: focusItem)
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "counting", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
