import Foundation

/// 游戏结果聚合持久化（UserDefaults key "grow.game.results"）。
/// 与 ProgressManager（拼图解锁进度 grow.puzzle.progress）完全独立、互不干扰；
/// 拼图完成时两边各自记录（双写），旧进度数据零迁移零丢失。
final class GameResultStore: ObservableObject {
    static let shared = GameResultStore()

    /// 「最近探索」条目：内容 id + 游戏来源，供首页/游戏中心解析 nature 名称展示
    struct RecentExploration: Identifiable, Equatable {
        let contentId: String
        let gameId: String
        let date: Date

        var id: String { contentId }
    }

    @Published private(set) var results: [String: GameResult] = [:]

    private let defaults = UserDefaults.standard
    private static let storageKey = "grow.game.results"

    private init() { load() }

    // MARK: - 查询

    func result(gameId: String, level: Int) -> GameResult {
        results["\(gameId)_\(level)"] ?? GameResult(gameId: gameId, level: level,
                                                    completed: false, playCount: 0,
                                                    completedCount: 0, lastPlayedAt: nil,
                                                    lastCompletedAt: nil, lastContentId: nil)
    }

    func isCompleted(gameId: String, level: Int) -> Bool {
        result(gameId: gameId, level: level).completed
    }

    /// 最近探索：按时间倒序、按内容 id 去重（同一个对象只显示最近一次）
    func recentExplorations(limit: Int = 8) -> [RecentExploration] {
        var seen = Set<String>()
        var out: [RecentExploration] = []
        let sorted = results.values.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
        for r in sorted {
            guard let contentId = r.lastContentId, !seen.contains(contentId) else { continue }
            seen.insert(contentId)
            out.append(RecentExploration(contentId: contentId,
                                         gameId: r.gameId,
                                         date: r.lastPlayedAt ?? .distantPast))
            if out.count >= limit { break }
        }
        return out
    }

    // MARK: - 记录

    /// 每次进入游戏记录一次 play；完成时 completed=true（可由各游戏页在对应时机调用）
    func record(gameId: String, level: Int, completed: Bool, contentId: String? = nil) {
        var r = result(gameId: gameId, level: level)
        r.playCount += 1
        r.lastPlayedAt = Date()
        r.lastContentId = contentId ?? r.lastContentId
        if completed {
            r.completed = true
            r.completedCount += 1
            r.lastCompletedAt = Date()
        }
        results[r.storageKey] = r
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([String: GameResult].self, from: data) else { return }
        results = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
