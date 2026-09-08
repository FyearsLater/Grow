import Foundation

// MARK: - 统一随机服务（Phase 6.1 Step 1）
//
// 整个 App 只允许通过本服务产生随机：自然世界智能随机、探索页全局随机、
// 各小游戏选题，都走这里。禁止各模块自己 random() / shuffled()。
//
// 对外能力（§二）：
//   shuffle          基础洗牌
//   weightedRandom   带权重随机
//   avoidRecent      最近出现的内容降权
//   avoidDuplicate   同批去重（保持顺序）
//   sessionRandom    会话级随机（同一会话内不重复，取尽后自动重开）
//   categoryRandom   分类内智能随机（SmartShuffle：同轮不重复 + 避免连续重复 + 最近避重）

final class RandomizationService {
    static let shared = RandomizationService()

    private let smart = SmartShuffle()
    private var sessions: [String: RandomSession] = [:]
    private let lock = NSLock()

    private init() {}

    // MARK: - 1. shuffle

    func shuffle<T>(_ items: [T]) -> [T] { items.shuffled() }

    // MARK: - 2. weightedRandom

    /// 按权重取一个；权重 <= 0 的条目不参与
    func weightedRandom<T>(_ entries: [(item: T, weight: Double)]) -> T? {
        let valid = entries.filter { $0.weight > 0 && $0.weight.isFinite }
        guard !valid.isEmpty else { return entries.first?.item }
        let total = valid.reduce(0.0) { $0 + $1.weight }
        guard total > 0 else { return valid.first?.item }
        var roll = Double.random(in: 0..<total)
        for entry in valid {
            roll -= entry.weight
            if roll <= 0 { return entry.item }
        }
        return valid.last?.item
    }

    // MARK: - 3. avoidRecent

    /// 把「最近出现过」的内容往后排（降权重排，不是硬排除 —— §一.4「不要完全禁止」）
    /// - Parameter recentIDs: 由近到远排列（下标越大越近）
    func avoidRecent<T>(_ items: [T],
                        id: (T) -> String,
                        recentIDs: [String],
                        penalty: Double = 0.7) -> [T] {
        guard !recentIDs.isEmpty else { return items.shuffled() }
        let p = min(max(penalty, 0), 0.95)
        var remaining = items
        var result: [T] = []
        result.reserveCapacity(remaining.count)

        while !remaining.isEmpty {
            let entries: [(item: T, weight: Double)] = remaining.map { item in
                var weight = 1.0
                if let idx = recentIDs.lastIndex(of: id(item)) {
                    let recency = Double(idx + 1) / Double(recentIDs.count)   // 0~1，越大越近
                    weight *= max(0.05, 1.0 - recency * p)
                }
                return (item, weight)
            }
            guard let picked = weightedRandom(entries),
                  let removeAt = remaining.firstIndex(where: { id($0) == id(picked) }) else { break }
            result.append(remaining.remove(at: removeAt))
        }
        return result
    }

    // MARK: - 4. avoidDuplicate

    /// 同批去重（保留首次出现顺序）
    func avoidDuplicate<T>(_ items: [T], id: (T) -> String) -> [T] {
        var seen = Set<String>()
        var result: [T] = []
        for item in items {
            let key = id(item)
            if seen.insert(key).inserted { result.append(item) }
        }
        return result
    }

    // MARK: - 5. sessionRandom

    /// 会话级随机：同一 sessionKey 内取过的内容不再出现，取尽后自动重开一轮。
    func sessionRandom<T>(_ items: [T],
                          id: (T) -> String,
                          sessionKey: String,
                          count: Int = 1) -> [T] {
        guard !items.isEmpty, count > 0 else { return [] }
        lock.lock(); defer { lock.unlock() }
        let session = sessions[sessionKey] ?? RandomSession(key: sessionKey)
        sessions[sessionKey] = session
        var picked: [T] = []
        for _ in 0..<count {
            let candidates = items.filter { !session.used.contains(id($0)) }
            let pool = candidates.isEmpty ? items : candidates
            if candidates.isEmpty { session.used.removeAll() }
            guard let chosen = pool.randomElement() else { break }
            session.used.insert(id(chosen))
            picked.append(chosen)
        }
        return picked
    }

    /// 重置某个会话（退出页面 / 换一关时调用）
    func resetSession(_ sessionKey: String) {
        lock.lock(); defer { lock.unlock() }
        sessions.removeValue(forKey: sessionKey)
    }

    // MARK: - 6. categoryRandom（SmartShuffle）

    /// 分类内智能随机：返回本轮浏览顺序（全排列，同轮不重复）。
    /// - 进入分类时给出一轮顺序；一轮走完再进入会重开新一轮。
    /// - 新一轮首项尽量不等于上一次最后看到的内容（避免连续重复）。
    /// - 最近看过的内容降权（不是禁止）。
    func categoryRandom(poolKey: String, allIDs: [String]) -> [String] {
        smart.orderedIDs(poolKey: poolKey, allIDs: allIDs)
    }

    /// 标记某内容被看到（驱动「最近避重」与「避免连续重复」）
    func markSeen(poolKey: String, id: String) {
        smart.markShown(poolKey: poolKey, id: id)
    }

    /// 一轮结束，下次进入重开新一轮
    func finishRound(poolKey: String) {
        smart.finishRound(poolKey: poolKey)
    }
}

// MARK: - 随机会话

/// 会话内去重记录（不持久化，随进程/重置释放）
final class RandomSession {
    let key: String
    fileprivate var used: Set<String> = []

    init(key: String) { self.key = key }
}

// MARK: - SmartShuffle（§一）

/// 自然世界智能随机：
///   · 同轮不重复（一轮 = 全排列，走完才重开）
///   · 避免连续重复（新一轮首项 != 上一轮末项）
///   · 最近内容避重（降权，非禁止）
///   · 与「最近浏览」完全分离：这里只记自己的短期缓存，
///     不读写 UserLibrary，因此不改变最近浏览的时间排序（§一.5）
final class SmartShuffle {

    private struct Pool {
        var queue: [String] = []
        var roundFinished = true
    }

    private var pools: [String: Pool] = [:]
    /// 每个池最近看过的 id（由远到近，末尾最新）
    private var recent: [String: [String]] = [:]
    /// 每个池上一次最后看到的内容
    private var lastShown: [String: String] = [:]

    private let recentCapacity = 8
    private let store = UserDefaults.standard
    private let recentKeyPrefix = "grow.smartshuffle.recent."
    private let lastKeyPrefix = "grow.smartshuffle.last."

    // MARK: 主入口

    func orderedIDs(poolKey: String, allIDs: [String]) -> [String] {
        let unique = Array(NSOrderedSet(array: allIDs)) as? [String] ?? allIDs
        guard !unique.isEmpty else { return [] }

        var pool = pools[poolKey] ?? Pool()
        // 队列无效（内容有增删 / 一轮已走完）→ 重开一轮
        if pool.roundFinished || !isQueueValid(pool.queue, allIDs: unique) {
            pool.queue = makeRound(allIDs: unique, poolKey: poolKey)
            pool.roundFinished = false
        }
        pools[poolKey] = pool
        return pool.queue
    }

    func markShown(poolKey: String, id: String) {
        lastShown[poolKey] = id
        store.set(id, forKey: lastKeyPrefix + poolKey)

        var list = recent[poolKey] ?? loadRecent(poolKey)
        list.removeAll { $0 == id }
        list.append(id)
        if list.count > recentCapacity { list = Array(list.suffix(recentCapacity)) }
        recent[poolKey] = list
        store.set(list, forKey: recentKeyPrefix + poolKey)
    }

    func finishRound(poolKey: String) {
        var pool = pools[poolKey] ?? Pool()
        pool.roundFinished = true
        pool.queue = []
        pools[poolKey] = pool
    }

    // MARK: 内部

    private func isQueueValid(_ queue: [String], allIDs: [String]) -> Bool {
        guard queue.count == allIDs.count else { return false }
        let set = Set(allIDs)
        return queue.allSatisfy { set.contains($0) }
    }

    /// 生成新一轮顺序：加权洗牌 + 首项避重
    private func makeRound(allIDs: [String], poolKey: String) -> [String] {
        let recentList = recent[poolKey] ?? loadRecent(poolKey)
        var ordered = weightedShuffle(allIDs, recent: recentList)

        // 避免连续重复：首项若等于上一轮最后一项，则与后面某一项交换
        if let last = lastShown[poolKey] ?? store.string(forKey: lastKeyPrefix + poolKey),
           ordered.count > 1,
           ordered.first == last {
            let swapIndex = Int.random(in: 1..<ordered.count)
            ordered.swapAt(0, swapIndex)
        }
        return ordered
    }

    /// 加权洗牌：越近出现的内容权重越低（仍可能被选中，只是更靠后）
    private func weightedShuffle(_ ids: [String], recent: [String]) -> [String] {
        guard !recent.isEmpty else { return ids.shuffled() }
        var remaining = ids
        var result: [String] = []
        result.reserveCapacity(remaining.count)

        while !remaining.isEmpty {
            let entries: [(item: String, weight: Double)] = remaining.map { id in
                var weight = 1.0
                if let idx = recent.lastIndex(of: id) {
                    let recency = Double(idx + 1) / Double(recent.count)  // 0~1，越大越近
                    weight *= max(0.08, 1.0 - recency * 0.7)
                }
                return (id, weight)
            }
            guard let picked = RandomizationService.shared.weightedRandom(entries) else { break }
            result.append(picked)
            remaining.removeAll { $0 == picked }
        }
        return result
    }

    private func loadRecent(_ poolKey: String) -> [String] {
        (store.array(forKey: recentKeyPrefix + poolKey) as? [String]) ?? []
    }
}
