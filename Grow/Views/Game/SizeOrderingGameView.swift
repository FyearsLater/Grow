import SwiftUI

/// 排一排（大小排序）：同一素材生成 大/中/小 三个，依次点出「最大的 → 最小的」。
/// 第一阶段只做 大 → 小；错误只轻晃+语音「再看看～」，不出现错误/失败（§十/§十六）。
struct SizeOrderingGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = SizeOrderingEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    /// 详情页焦点内容（优先拿它来排序）
    var focus: String? = nil

    @State private var showComplete = false
    @State private var shakeToken = 0

    private var gameLevel: GameLevel? { games.level(gameId: "ordering", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.ordering) }

    var body: some View {
        VStack(spacing: 16) {
            GameIntroTip(module: module, text: "从大到小排一排")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            slotsRow

            if engine.pending.isEmpty && !engine.placed.isEmpty {
                Spacer()
            } else {
                pendingRow
            }

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("排一排")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .onDisappear { AudioManager.shared.stop() }
        .overlay {
            if showComplete, let hero = engine.solvedItem {
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

    // MARK: - 已放置槽位

    private var slotsRow: some View {
        HStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.creamDeep)
                        .frame(height: 96 * settings.pageScaleFactor)
                    if index < engine.placed.count {
                        IllustrationView(identifier: engine.placed[index].item.illustration)
                            .frame(width: 78 * engine.placed[index].size.scale * settings.pageScaleFactor,
                                   height: 78 * engine.placed[index].size.scale * settings.pageScaleFactor)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.inkSoft.opacity(0.35))
                    }
                }
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(index == engine.placed.count ? module.deepTint.opacity(0.55) : .clear, lineWidth: 2.5)
                )
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 待排序物体

    private var pendingRow: some View {
        HStack(alignment: .bottom, spacing: 18) {
            ForEach(engine.pending) { object in
                Button { place(object) } label: {
                    VStack(spacing: 6) {
                        IllustrationView(identifier: object.item.illustration)
                            .frame(width: 108 * object.size.scale * settings.pageScaleFactor,
                                   height: 108 * object.size.scale * settings.pageScaleFactor)
                        Text(object.size.displayName)
                            .font(.system(size: Theme.scaled(13, settings: settings), weight: .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 150 * settings.buttonScaleFactor)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.85))
                    )
                }
                .buttonStyle(PressableButtonStyle(settings: settings))
                .modifier(GameShakeOnError(shakeToken: shakeToken,
                                           reduceMotion: settings.reduceMotion || !settings.animationOn))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 交互

    private func place(_ object: SizeOrderingEngine.Object) {
        guard !engine.isCompleted else { return }
        if engine.place(object.id) {
            GameSound.correct.play()
            if engine.isCompleted {
                feedback.correct(gameId: "ordering", itemName: object.item.nameZh)
                finish(hero: object.item)
            }
        } else {
            // §十：轻微提示，不显示错误/失败
            feedback.retry(gameId: "ordering")
            shakeToken += 1
        }
    }

    private func setup() {
        prepareLevel()
        feedback.speakInstruction("从大到小排一排", gameId: "ordering")
    }

    private func prepareLevel() {
        let pool = GameContentResolver.shared.getContents(for: .ordering)
        guard !pool.isEmpty else { return }
        let picked: NatureItem
        if let focus, let focusItem = pool.first(where: { $0.id == focus }) {
            picked = focusItem
        } else {
            picked = RandomizationService.shared.shuffle(pool)[0]
        }
        engine.prepare(item: picked, count: 3)
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "ordering", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
