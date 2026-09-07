import SwiftUI

/// 捕获拼图板在屏幕坐标系中的位置，用于拖拽命中判定
private struct BoardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

/// 拼图游戏页：中间拼图区 + 底部拼图块托盘。
/// 所有业务逻辑（切格 / 打乱 / 判定 / 吸附 / 完成）由 PuzzleEngine 承担，本页只负责交互与呈现。
struct PuzzleGameView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var progress: ProgressManager
    @EnvironmentObject var puzzles: PuzzleRepository
    @StateObject private var engine = PuzzleEngine()

    @State private var currentItem: PuzzleItem

    @State private var boardRect: CGRect = .zero
    @State private var sourceImage: UIImage?
    @State private var cropCache: [Int: UIImage] = [:]
    @State private var drag: DragState?
    @State private var showComplete = false
    @State private var hintPiece: Int?
    @State private var hintPulse = false
    @State private var idleWork: DispatchWorkItem?

    private let spaceName = "puzzleSpace"

    init(item: PuzzleItem) {
        _currentItem = State(initialValue: item)
    }

    /// 拖拽中的块：index 为正确索引，position 为块中心（puzzleSpace 坐标）
    struct DragState {
        let index: Int
        var position: CGPoint
        let origin: CGPoint
    }

    var body: some View {
        GeometryReader { geo in
            let size = Self.boardSize(in: geo.size)

            ZStack(alignment: .topLeading) {
                Theme.cream.ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    boardArea(size: size)
                    trayArea(cell: size / CGFloat(engine.grid))
                }

                // 拖拽中的块浮在最上层
                if let drag {
                    let cell = size / CGFloat(engine.grid)
                    pieceImage(drag.index)
                        .frame(width: cell * 1.08, height: cell * 1.08)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 12, y: 7)
                        .offset(x: drag.position.x - cell * 0.54, y: drag.position.y - cell * 0.54)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: spaceName)
            .onPreferenceChange(BoardFrameKey.self) { boardRect = $0 }
        }
        .navigationTitle(currentItem.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: setup)
        .onDisappear {
            idleWork?.cancel()
            AudioManager.shared.stop()
        }
        .overlay {
            if showComplete { completeOverlay }
        }
    }

    private static func boardSize(in size: CGSize) -> CGFloat {
        min(size.width - 32, size.height * 0.52, 380)
    }

    // MARK: - 顶部

    private var header: some View {
        HStack(spacing: 12) {
            Text("\(engine.placedCount) / \(engine.pieceCount)")
                .font(.system(size: Theme.scaled(15, settings: settings), weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.inkSoft)

            Spacer()

            Button {
                resetGame()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(minWidth: 44, minHeight: 44)
                    .background(Circle().fill(Theme.creamDeep))
            }
            .buttonStyle(PressableButtonStyle(settings: settings))
            .accessibilityLabel("重新开始")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    // MARK: - 拼图板

    private func boardArea(size: CGFloat) -> some View {
        let grid = engine.grid
        let cell = size / CGFloat(grid)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.creamDeep)
                .overlay(gridLines(grid: grid))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            // 辅助模式：淡底图作为参考，帮助低龄儿童判断位置
            if settings.puzzleAssist, let img = sourceImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.14)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            // 已放置的块
            ForEach(engine.boardPieces) { piece in
                let row = piece.correctIndex / grid
                let col = piece.correctIndex % grid
                pieceImage(piece.correctIndex)
                    .frame(width: cell, height: cell)
                    .clipped()
                    .position(x: (CGFloat(col) + 0.5) * cell, y: (CGFloat(row) + 0.5) * cell)
            }

            // 辅助提示：正确格子轻闪一次
            if let hint = hintPiece {
                let r = engine.frame(of: hint, boardSize: size)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.vegetable, lineWidth: 3)
                    .frame(width: r.width, height: r.height)
                    .opacity(hintPulse ? 0.95 : 0.12)
                    .position(x: r.midX, y: r.midY)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: size, height: size)
        // 必须先捕获板自身 frame：不能放在 maxWidth:.infinity 之后，否则会被撑成屏幕宽度，
        // 导致拖拽命中判定用错 boardSize。
        .background(
            GeometryReader { g in
                Color.clear.preference(key: BoardFrameKey.self, value: g.frame(in: .named(spaceName)))
            }
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func gridLines(grid: Int) -> some View {
        GeometryReader { g in
            let step = g.size.width / CGFloat(grid)
            Path { p in
                for i in 1..<grid {
                    let v = step * CGFloat(i)
                    p.move(to: CGPoint(x: v, y: 0))
                    p.addLine(to: CGPoint(x: v, y: g.size.height))
                    p.move(to: CGPoint(x: 0, y: v))
                    p.addLine(to: CGPoint(x: g.size.width, y: v))
                }
            }
            .stroke(Theme.inkSoft.opacity(0.18), lineWidth: 1.5)
        }
    }

    // MARK: - 托盘

    private func trayArea(cell: CGFloat) -> some View {
        let trayCell = min(max(cell * 0.9, 58), 94)
        let columns = max(3, Int(UIScreen.main.bounds.width / (trayCell + 14)))

        return VStack(spacing: 6) {
            Text("把下面的拼图块拖到上面")
                .font(.system(size: Theme.scaled(13, settings: settings), weight: .medium))
                .foregroundStyle(Theme.inkSoft)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columns), spacing: 10) {
                    ForEach(engine.trayPieces) { piece in
                        trayPiece(piece, size: trayCell)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .padding(.top, 4)
    }

    private func trayPiece(_ piece: PuzzlePiece, size: CGFloat) -> some View {
        pieceImage(piece.correctIndex)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
            .opacity(drag?.index == piece.correctIndex ? 0.3 : 1)
            .gesture(
                DragGesture(minimumDistance: 4, coordinateSpace: .named(spaceName))
                    .onChanged { value in
                        if drag == nil {
                            guard !engine.isCompleted else { return }
                            engine.beginDrag()
                            PuzzleSound.pick.play()
                            cancelHint()
                            drag = DragState(index: piece.correctIndex,
                                             position: value.location,
                                             origin: value.startLocation)
                        } else if drag?.index == piece.correctIndex {
                            drag?.position = value.location
                        }
                    }
                    .onEnded { value in
                        handleDrop(index: piece.correctIndex, at: value.location)
                    }
            )
            .accessibilityLabel("拼图块")
    }

    // MARK: - 释放判定

    private func handleDrop(index: Int, at location: CGPoint) {
        let point = CGPoint(x: location.x - boardRect.minX, y: location.y - boardRect.minY)

        if engine.isCorrectDrop(index: index, at: point, boardSize: boardRect.width) {
            // 正确：自动吸附 + 柔和音效 + 锁定（§46）
            withAnimation(.spring(response: 0.3, dampingFraction: 0.62)) {
                drag = nil
                engine.snapPiece(index: index)
            }
            PuzzleSound.place.play()
            scheduleHint()

            if engine.isCompleted {
                engine.completePuzzle()
                let time = engine.elapsed()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    // 原进度逻辑不动（解锁状态保存在 grow.puzzle.progress）
                    progress.recordCompletion(puzzleId: currentItem.id, time: time)
                    // 双写游戏中心结果（仅供"最近探索"展示，与解锁进度互不影响）
                    GameResultStore.shared.record(gameId: "puzzle",
                                                  level: currentItem.difficulty.gameLevel.rawValue,
                                                  completed: true,
                                                  contentId: currentItem.sourceNatureItemId)
                    withAnimation(.easeOut(duration: 0.3)) { showComplete = true }
                    PuzzleSound.complete.play()
                }
            } else {
                engine.endDrag()
            }
        } else {
            // 错误：轻柔回到原位置附近，不播放错误音、不做红色提示（§47）
            withAnimation(.spring(response: 0.42, dampingFraction: 0.75)) {
                drag?.position = drag?.origin ?? location
            }
            let idx = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                if drag?.index == idx { drag = nil }
            }
            engine.endDrag()
            scheduleHint()
        }
    }

    // MARK: - 辅助模式

    private func scheduleHint() {
        idleWork?.cancel()
        hintPiece = nil
        hintPulse = false
        guard settings.puzzleAssist, !engine.isCompleted else { return }

        let work = DispatchWorkItem {
            guard !engine.isCompleted else { return }
            hintPiece = engine.hintIndex()
            withAnimation(.easeInOut(duration: 0.55).repeatCount(3, autoreverses: true)) {
                hintPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                hintPiece = nil
                hintPulse = false
            }
        }
        idleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0, execute: work)
    }

    private func cancelHint() {
        idleWork?.cancel()
        idleWork = nil
        hintPiece = nil
        hintPulse = false
    }

    // MARK: - 生命周期

    private func setup() {
        let name = currentItem.image.hasPrefix("img:")
            ? String(currentItem.image.dropFirst(4))
            : currentItem.image
        sourceImage = IllustrationView.bundleImage(name)

        engine.createPuzzle(item: currentItem)

        // 预生成切片（仅内存缓存，不写磁盘；离开页面即释放）
        var cache: [Int: UIImage] = [:]
        for piece in engine.pieces {
            if let img = cropPiece(piece.correctIndex) { cache[piece.correctIndex] = img }
        }
        cropCache = cache

        progress.recordPlay(puzzleId: currentItem.id)
        scheduleHint()
    }

    private func resetGame() {
        cancelHint()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            engine.resetPuzzle()
        }
        scheduleHint()
    }

    // MARK: - 完成页

    private var nextItem: PuzzleItem? {
        puzzles.puzzles(in: currentItem.difficulty).first {
            $0.id != currentItem.id && !progress.isCompleted($0.id)
        }
    }

    private var completeOverlay: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            PuzzleCompleteView(
                item: currentItem,
                elapsed: engine.elapsed(),
                hasNext: nextItem != nil,
                onReplay: {
                    withAnimation { showComplete = false }
                    resetGame()
                },
                onNext: {
                    guard let next = nextItem else { return }
                    withAnimation { showComplete = false }
                    currentItem = next
                    setup()
                }
            )
        }
        .transition(.opacity)
    }

    // MARK: - 切片（运行时生成，不落盘）

    private func pieceImage(_ index: Int) -> some View {
        Group {
            if let img = cropCache[index] {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(Theme.creamDeep)
            }
        }
    }

    private func cropPiece(_ index: Int) -> UIImage? {
        guard let src = sourceImage,
              let piece = engine.pieces.first(where: { $0.correctIndex == index }),
              let cg = src.cgImage else { return nil }
        let pw = CGFloat(cg.width)
        let ph = CGFloat(cg.height)
        let r = piece.imageRect
        let rect = CGRect(x: r.origin.x * pw, y: r.origin.y * ph,
                          width: r.width * pw, height: r.height * ph).integral
        guard let cut = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cut, scale: src.scale, orientation: src.imageOrientation)
    }
}
