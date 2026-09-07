import SwiftUI

// MARK: - 拖拽命中区捕获（分类桶 frame，参照 PuzzleGameView 的 PreferenceKey 范式）

private struct BucketFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// 分类游戏页：拖动底部物品到两个分类桶，宽松吸附（落点距桶中心 < 桶宽 60%）。
/// 逻辑在 SortingEngine；放对入桶+朗读、放错弹回（温和回弹，无错误音）。
struct SortingGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var games: GameRepository
    @EnvironmentObject var results: GameResultStore
    @StateObject private var engine = SortingEngine()
    @ObservedObject private var feedback = GameFeedbackManager.shared

    let level: Int

    @State private var bucketFrames: [String: CGRect] = [:]
    @State private var drag: DragState?
    @State private var showComplete = false

    private struct DragState: Equatable {
        let item: SortingEngine.SortItem
        var position: CGPoint
        let origin: CGPoint
    }

    private let spaceName = "sortSpace"

    private var gameLevel: GameLevel? { games.level(gameId: "sorting", level: level) }
    private var module: GameModule { GameModule.from(.sorting) }

    /// 每桶件数：L1=1 / L2=2 / L3=3
    private var perBucket: Int {
        switch level {
        case 1: return 1
        case 2: return 2
        default: return 3
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                Theme.cream.ignoresSafeArea()

                VStack(spacing: 10) {
                    GameIntroTip(module: module, text: "把物品放进对应的筐")
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    bucketsArea
                        .padding(.horizontal, 20)

                    trayArea
                }

                // 拖拽中的物品浮在最上层
                if let drag {
                    trayCard(drag.item)
                        .frame(width: 96, height: 96)
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 7)
                        .offset(x: drag.position.x - 48, y: drag.position.y - 48)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: spaceName)
            .onPreferenceChange(BucketFrameKey.self) { bucketFrames = $0 }
        }
        .navigationTitle("分一分")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .onDisappear {
            AudioManager.shared.stop()
        }
        .overlay {
            if showComplete, let hero = engine.lastSortedItem {
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

    // MARK: - 分类桶（各占半宽，高 ≥ 200）

    private var bucketsArea: some View {
        HStack(spacing: 16) {
            ForEach(engine.buckets) { bucket in
                bucketView(bucket)
            }
        }
        .frame(height: 210 * settings.pageScaleFactor)
    }

    private func bucketView(_ bucket: SortingEngine.Bucket) -> some View {
        let color = Theme.categoryColor(bucket.category)
        let isHot = isDraggingOver(bucket)

        return VStack(spacing: 10) {
            // 桶口
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.35))
                .frame(width: 110, height: 26)
            // 桶身
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(colors: [color.opacity(0.55), color.opacity(0.30)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    VStack(spacing: 6) {
                        // 桶代表：该类第一个对象的小图（水果→苹果形既视感，用矢量类别图标）
                        Text(bucket.category.displayName)
                            .font(.system(size: Theme.scaled(20, settings: settings), weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(bucket.placedCount) 件")
                            .font(.system(size: Theme.scaled(12, settings: settings), weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(color.opacity(isHot ? 0.9 : 0.4),
                                lineWidth: isHot ? 3 : 1.5)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            GeometryReader { g in
                Color.clear.preference(key: BucketFrameKey.self,
                                       value: [bucket.category.rawValue: g.frame(in: .named(spaceName))])
            }
        )
        .scaleEffect(isHot ? 1.04 : 1.0)
        .animation(GrowAnimation.card(settings), value: isHot)
    }

    /// 宽松吸附：拖拽点进入桶 frame 即视为悬停
    private func isDraggingOver(_ bucket: SortingEngine.Bucket) -> Bool {
        guard let drag, let frame = bucketFrames[bucket.category.rawValue] else { return false }
        return frame.contains(drag.position)
    }

    // MARK: - 物品托盘（自适应多行网格，卡 84pt）

    private var trayArea: some View {
        VStack(spacing: 6) {
            Text("把下面的物品拖进上面的筐")
                .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)

            let columns = [GridItem(.adaptive(minimum: 84), spacing: 14)]
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(engine.tray) { item in
                    trayCard(item)
                        .frame(width: 84, height: 84)
                        .opacity(drag?.item.id == item.id ? 0.3 : 1)
                        .gesture(dragGesture(item))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .padding(.bottom, 12)
    }

    private func trayCard(_ item: SortingEngine.SortItem) -> some View {
        IllustrationView(identifier: item.item.illustration)
            .frame(width: 84, height: 84)
            .growCard(fill: .white.opacity(0.85), radius: 20)
    }

    private func dragGesture(_ item: SortingEngine.SortItem) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(spaceName))
            .onChanged { value in
                if drag == nil {
                    guard !engine.isCompleted else { return }
                    GameSound.pick.play()
                    drag = DragState(item: item,
                                     position: value.location,
                                     origin: value.startLocation)
                } else if drag?.item.id == item.id {
                    drag?.position = value.location
                }
            }
            .onEnded { value in
                handleDrop(item: item, at: value.location)
            }
    }

    // MARK: - 释放判定（宽松吸附：距桶中心 < 桶宽 60%）

    private func handleDrop(item: SortingEngine.SortItem, at location: CGPoint) {
        // 找到落点所在（或最近）的桶
        var hitCategory: NatureCategory?
        for (raw, frame) in bucketFrames {
            guard let category = NatureCategory(rawValue: raw) else { continue }
            let center = CGPoint(x: frame.midX, y: frame.midY)
            let dx = location.x - center.x
            let dy = location.y - center.y
            let threshold = frame.width * 0.6
            if abs(dx) < threshold && abs(dy) < frame.height * 0.8 {
                hitCategory = category
                break
            }
        }

        if let category = hitCategory, engine.drop(item, into: category) {
            // 放对：入桶 + "对啦！苹果"（正确音效由 GameFeedbackManager.correct() 统一播放）
            feedback.correct(gameId: "sorting", itemName: item.item.nameZh)
            drag = nil
            if engine.isCompleted {
                finish(hero: item.item)
            }
        } else {
            // 放错 / 没落到桶：弹回原位（温和回弹，无错误音）
            withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                drag?.position = drag?.origin ?? location
            }
            feedback.retry(gameId: "sorting")
            let dragged = drag
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                if drag?.item.id == dragged?.item.id { drag = nil }
            }
        }
    }

    // MARK: - 生命周期

    private func setup() {
        prepareLevel()
        feedback.speakInstruction("把物品放进对应的筐", gameId: "sorting")
    }

    private func prepareLevel() {
        let config = gameLevel?.configuration ?? GameLevelConfig()
        let pairs = config.categoryPairs ?? []
        let pool = games.natureItems(for: gameLevel?.contentIds ?? [])
        engine.prepare(items: pool, pairs: pairs, perBucket: perBucket)
    }

    private func finish(hero: NatureItem) {
        results.record(gameId: "sorting", level: level, completed: true, contentId: hero.id)
        GameSound.complete.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(GrowAnimation.complete(settings)) { showComplete = true }
        }
    }
}
