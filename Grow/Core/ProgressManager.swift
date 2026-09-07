import Foundation

/// 拼图进度与难度解锁（本地持久化，离线可用）
/// 解锁规则：完成前一难度的任意一张，即解锁下一难度（§31 逐级解锁）。
final class ProgressManager: ObservableObject {
    static let shared = ProgressManager()

    @Published private(set) var progress: [String: PuzzleProgress] = [:]

    private let defaults = UserDefaults.standard
    private let key = "grow.puzzle.progress"

    private init() { load() }

    // MARK: - 查询

    func progress(for id: String) -> PuzzleProgress {
        progress[id] ?? PuzzleProgress(puzzleId: id)
    }

    func isCompleted(_ id: String) -> Bool {
        progress[id]?.completed ?? false
    }

    /// 某难度下已完成的拼图数量
    func completedCount(in difficulty: PuzzleDifficulty, repo: PuzzleRepository = .shared) -> Int {
        repo.puzzles(in: difficulty).filter { isCompleted($0.id) }.count
    }

    /// 某难度是否已解锁
    func isUnlocked(_ difficulty: PuzzleDifficulty, repo: PuzzleRepository = .shared) -> Bool {
        guard let prev = difficulty.requiredPrevious else { return true }
        return completedCount(in: prev, repo: repo) > 0
    }

    // MARK: - 记录

    func recordCompletion(puzzleId: String, time: TimeInterval) {
        var p = progress(for: puzzleId)
        p.completed = true
        p.completedCount += 1
        p.lastPlayed = Date()
        p.bestTime = min(p.bestTime ?? time, time)
        progress[puzzleId] = p
        save()
    }

    func recordPlay(puzzleId: String) {
        var p = progress(for: puzzleId)
        p.lastPlayed = Date()
        progress[puzzleId] = p
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: PuzzleProgress].self, from: data) else { return }
        progress = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }
}
