import SwiftUI

/// 配对游戏页：进入 → 说明 → 翻面配对 → 完成 → 反馈 → 再玩/下一组。
/// 逻辑全部在 MatchingEngine；本页只负责交互与呈现。
struct MatchingGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = MatchingEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int
    /// 详情页「找朋友」带来的焦点对象（保证参与本局）
    var focus: String? = nil

    @State private var showComplete = false
    @State private var lastMatchedItem: NatureItem?
    @State private var pendingClose: DispatchWorkItem?

    private var gameLevel: GameLevel? { games.level(gameId: "matching", level: level) }
    private var levelConfig: GameLevelConfig { gameLevel?.configuration ?? GameLevelConfig() }
    private var module: GameModule { GameModule.from(.matching) }

    var body: some View {
        VStack(spacing: 14) {
            GameIntroTip(module: module, text: "找出一样的朋友")
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // 进度（配了几组）
            HStack {
                Spacer()
                Text("\(engine.matchedPairs) / \(engine.totalPairs) 组")
                    .font(.system(size: Theme.scaled(15, settings: settings), weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 22)
            }

            cardsGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.cream.ignoresSafeArea())
        .navigationTitle("配对")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .onDisappear {
            pendingClose?.cancel()
            AudioManager.shared.stop()
        }
        .overlay {
            if showComplete, let hero = lastMatchedItem {
                GameCompleteOverlay(
                    heroItem: hero,
                    accent: module.tint,
                    onReplay: {
                        withAnimation { showComplete = false }
                        engine.reset()
                    },
                    onNext: {
                        withAnimation { showComplete = false }
                        // "下一组" = 同关换一批内容重新开
                        prepareLevel()
                    }
                )
                .transition(.opacity)
            }
        }
    }

    // MARK: - 卡片网格

    private var cardsGrid: some View {
        GeometryReader { geo in
            let columns = engine.totalPairs <= 2 ? 2 : 3
            let side = min((geo.size.width - 40 - CGFloat(columns - 1) * 14) / CGFloat(columns),
                           (geo.size.height - 20) / CGFloat(max((engine.cards.count + columns - 1) / columns, 1)))
            let cardSide = min(max(side, 90), 150)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns),
                          spacing: 14) {
                    ForEach(engine.cards) { card in
                        matchingCard(card, side: cardSide)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func matchingCard(_ card: MatchingEngine.Card, side: CGFloat) -> some View {
        Group {
            if card.isFaceUp || card.isMatched {
                GameOptionCard(item: card.item, state: .normal, showsName: true)
            } else {
                // 背面：柔和主题色 + 模块小图标
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(colors: [module.tint.opacity(0.9), module.tint.opacity(0.6)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    GameModuleIcon(module: module, size: side * 0.42)
                }
                .shadow(color: module.tint.opacity(0.3), radius: 10, y: 5)
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .onTapGesture { tap(card) }
        .opacity(card.isMatched ? 0.75 : 1)
        .animation(GrowAnimation.card(settings), value: card.isFaceUp)
        .animation(GrowAnimation.card(settings), value: card.isMatched)
        .accessibilityLabel(card.isFaceUp ? card.item.nameZh : "翻翻看")
    }

    // MARK: - 交互

    private func tap(_ card: MatchingEngine.Card) {
        switch engine.flip(card.id) {
        case .firstFlip:
            GameSound.pick.play()

        case .matched(let a, let b):
            GameSound.correct.play()
            let item = engine.cards.first { $0.id == a }?.item ?? card.item
            lastMatchedItem = item
            // 正确短语 + 对象名一次朗读（"找到了！苹果"）
            feedback.correct(gameId: "matching", itemName: item.nameZh)
            if engine.isCompleted {
                finish()
            }

        case .mismatch(let first, let second):
            feedback.retry(gameId: "matching")
            // 0.8s 后轻合上（2-3 岁容错，无惩罚）
            let work = DispatchWorkItem { engine.close(ids: [first, second]) }
            pendingClose?.cancel()
            pendingClose = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)

        case .ignored:
            break
        }
    }

    // MARK: - 生命周期

    private func setup() {
        prepareLevel()
        feedback.speakInstruction("找出一样的朋友", gameId: "matching")
    }

    private func prepareLevel() {
        let pool = games.natureItems(for: gameLevel?.contentIds ?? [])
        guard !pool.isEmpty else { return }
        let forced = focus.flatMap { id in pool.first(where: { $0.id == id }) }.map { [$0] } ?? []
        let groupCount = levelConfig.groupCount ?? min(2, max(1, pool.count / 2))
        engine.prepare(pool: pool, groupCount: groupCount, forced: forced)
        lastMatchedItem = engine.pickedItems.first
    }

    private func finish() {
        results.record(gameId: "matching", level: level, completed: true,
                       contentId: lastMatchedItem?.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
