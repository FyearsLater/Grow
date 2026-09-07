import CoreGraphics
import Foundation

/// 单块拼图
struct PuzzlePiece: Identifiable, Equatable {
    /// 正确格子索引（row * grid + col）
    let correctIndex: Int
    /// 是否已放到正确位置（放置后锁定）
    var isPlaced: Bool
    /// 在原图中的裁剪区域（归一化 0–1，运行时切片，不落盘）
    let imageRect: CGRect

    var id: Int { correctIndex }
}

/// 拼图状态
enum PuzzleState: Equatable {
    case idle
    case playing
    case dragging
    case placing
    case completed
}

/// 拼图引擎：只负责业务逻辑（切格 / 打乱 / 判定 / 吸附 / 完成 / 重置），不含任何 UI。
/// 图片只有一张 720×720 原图，切片在运行时按难度计算，不生成、不保存切片文件。
final class PuzzleEngine: ObservableObject {

    @Published private(set) var pieces: [PuzzlePiece] = []
    @Published private(set) var state: PuzzleState = .idle
    @Published private(set) var placedCount = 0
    @Published private(set) var grid = 2

    private(set) var item: PuzzleItem?
    private var startedAt: Date?

    var pieceCount: Int { grid * grid }
    var isCompleted: Bool { pieceCount > 0 && placedCount >= pieceCount }
    /// 托盘中待放置的块（顺序即随机后的展示顺序）
    var trayPieces: [PuzzlePiece] { pieces.filter { !$0.isPlaced } }
    /// 已放置到板上的块
    var boardPieces: [PuzzlePiece] { pieces.filter { $0.isPlaced } }

    // MARK: - 生命周期

    /// 创建一局：按难度切格 + 随机打乱
    func createPuzzle(item: PuzzleItem) {
        self.item = item
        grid = item.difficulty.grid
        let n = grid
        let w = 1.0 / CGFloat(n)

        pieces = (0..<(n * n)).map { i in
            let row = i / n
            let col = i % n
            return PuzzlePiece(
                correctIndex: i,
                isPlaced: false,
                imageRect: CGRect(x: CGFloat(col) * w, y: CGFloat(row) * w, width: w, height: w)
            )
        }
        placedCount = 0
        startedAt = Date()
        state = .playing
        shufflePieces()
    }

    /// 随机排列托盘顺序：避免每次进入都是相同布局
    func shufflePieces() {
        var tray = pieces.filter { !$0.isPlaced }
        tray.shuffle()
        let placed = pieces.filter { $0.isPlaced }
        pieces = tray + placed
    }

    func beginDrag() {
        if state == .playing { state = .dragging }
    }

    func endDrag() {
        if state == .dragging { state = .playing }
    }

    // MARK: - 判定与吸附

    /// 释放点是否命中该块的正确格子（儿童容错：格子即判定范围，不要求像素级精确）
    /// - Parameters:
    ///   - index: 块的正确索引
    ///   - point: 释放点（板坐标系，原点在板左上角）
    ///   - boardSize: 板的边长（正方形）
    func isCorrectDrop(index: Int, at point: CGPoint, boardSize: CGFloat) -> Bool {
        guard pieceCount > 0, boardSize > 0 else { return false }
        let cell = boardSize / CGFloat(grid)
        let col = Int(floor(point.x / cell))
        let row = Int(floor(point.y / cell))
        guard col >= 0, col < grid, row >= 0, row < grid else { return false }
        return row * grid + col == index
    }

    /// 某块正确格子在板上的中心点（吸附动画用）
    func center(of index: Int, boardSize: CGFloat) -> CGPoint {
        let cell = boardSize / CGFloat(grid)
        let row = index / grid
        let col = index % grid
        return CGPoint(x: (CGFloat(col) + 0.5) * cell, y: (CGFloat(row) + 0.5) * cell)
    }

    /// 某块正确格子在板上的 frame（辅助模式闪烁提示用）
    func frame(of index: Int, boardSize: CGFloat) -> CGRect {
        let cell = boardSize / CGFloat(grid)
        let row = index / grid
        let col = index % grid
        return CGRect(x: CGFloat(col) * cell, y: CGFloat(row) * cell, width: cell, height: cell)
    }

    /// 吸附：把块固定到正确位置并锁定
    @discardableResult
    func snapPiece(index: Int) -> Bool {
        guard let i = pieces.firstIndex(where: { $0.correctIndex == index }),
              !pieces[i].isPlaced else { return false }
        pieces[i].isPlaced = true
        placedCount += 1
        state = isCompleted ? .completed : .playing
        return true
    }

    func checkCompletion() -> Bool { isCompleted }

    func completePuzzle() {
        guard isCompleted else { return }
        state = .completed
    }

    /// 本局用时（秒）
    func elapsed() -> TimeInterval {
        guard let startedAt else { return 0 }
        return Date().timeIntervalSince(startedAt)
    }

    /// 重置本局
    func resetPuzzle() {
        for i in pieces.indices { pieces[i].isPlaced = false }
        placedCount = 0
        startedAt = Date()
        state = .playing
        shufflePieces()
    }

    /// 辅助模式：建议提示的下一块（未放置中序号最小的一块）
    func hintIndex() -> Int? {
        pieces.filter { !$0.isPlaced }.map(\.correctIndex).sorted().first
    }
}
