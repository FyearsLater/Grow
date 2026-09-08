import SwiftUI

/// 找形状：顶部目标形状 → 下方 2~4 个自然内容 → 点出该形状的那个。
/// 只使用有 shape 属性的内容；形状判断不了的内容不进池（§十九）。
struct ShapeGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = ShapeGameEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    var focus: String? = nil

    @State private var showComplete = false
    @State private var shakeToken = 0

    private var gameLevel: GameLevel? { games.level(gameId: "shape", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.shape) }

    private var roundCount: Int { levelConfig.rounds ?? 3 }
    private var optionCount: Int { min(max(levelConfig.optionCount ?? 2, 2), 4) }

    var body: some View {
        VStack(spacing: 14) {
            if let round = engine.currentRoundData {
                GameIntroTip(module: module, text: "找出\(round.shape.displayName)的")
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                targetShape(round.shape)
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
        .navigationTitle("找形状")
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

    // MARK: - 目标形状

    private func targetShape(_ shape: ShapeDefinition) -> some View {
        VStack(spacing: 8) {
            shapeGlyph(shape)
                .frame(width: 92 * settings.pageScaleFactor, height: 92 * settings.pageScaleFactor)
                .shadow(color: module.deepTint.opacity(0.28), radius: 10, y: 5)
            Text(shape.displayName)
                .font(.system(size: Theme.scaled(26, settings: settings), weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
        }
    }

    @ViewBuilder
    private func shapeGlyph(_ shape: ShapeDefinition) -> some View {
        switch shape {
        case .circle, .oval:
            Circle().fill(module.deepTint)
        case .square, .rectangle:
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(module.deepTint)
        case .triangle:
            TriangleShape().fill(module.deepTint)
        case .star:
            Image(systemName: "star.fill")
                .resizable()
                .foregroundStyle(module.deepTint)
        case .long:
            Capsule().fill(module.deepTint)
        }
    }

    // MARK: - 选项

    private func optionsGrid(_ round: ShapeGameEngine.Round) -> some View {
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

    private func choose(_ option: ShapeGameEngine.Option) {
        guard !engine.isCompleted else { return }
        if engine.choose(option.id) {
            feedback.correct(gameId: "shape", itemName: option.item.nameZh)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                engine.advance()
                if engine.isCompleted {
                    finish(hero: option.item)
                } else {
                    speakCurrentInstruction()
                }
            }
        } else {
            feedback.retry(gameId: "shape")
            shakeToken += 1
        }
    }

    private func setup() {
        prepareLevel()
        speakCurrentInstruction()
    }

    private func prepareLevel() {
        engine.prepare(rounds: roundCount, optionCount: optionCount)
    }

    private func speakCurrentInstruction() {
        guard let round = engine.currentRoundData else { return }
        feedback.speakInstruction("找\(round.shape.displayName)", gameId: "shape")
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "shape", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
