import Foundation

/// 趣味拼图内容仓库
/// 只保存一张 720×720 原图；切片由 PuzzleEngine 在运行时计算，不生成也不保存切片文件。
final class PuzzleRepository: ObservableObject {
    static let shared = PuzzleRepository()

    @Published private(set) var puzzles: [PuzzleItem] = []

    private init() {
        puzzles = (JSONLoader.load("puzzles", as: PuzzleContentFile.self)?.items ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func puzzles(in difficulty: PuzzleDifficulty) -> [PuzzleItem] {
        puzzles.filter { $0.difficulty == difficulty }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func puzzle(id: String) -> PuzzleItem? {
        puzzles.first { $0.id == id }
    }

    func count(in difficulty: PuzzleDifficulty) -> Int {
        puzzles(in: difficulty).count
    }

    /// 内容关联（§25）：某自然认知对象可参与的拼图
    func puzzles(relatingTo natureID: String) -> [PuzzleItem] {
        puzzles.filter { $0.relatedContentIDs.contains(natureID) }
    }
}
