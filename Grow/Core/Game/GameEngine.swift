import Foundation

// MARK: - 引擎协议

/// 所有游戏引擎的统一协议：从关卡构建 → 重置 → 完成判定。
/// 引擎是纯逻辑（无 UI、无视图层引用），由各 XxxGameView 以 @StateObject 持有，
/// 离开页面随视图释放（§内存约定）。
protocol GameEngineProtocol: AnyObject {
    /// 本局是否已完成
    var isCompleted: Bool { get }
    /// 重置本局（保留同一批内容，翻回/清空进度）
    func reset()
}

// MARK: - 共用选题工具

/// 共用选题工具：按关卡取内容、洗牌、生成干扰项。
/// 配对/找相同/分类共用，避免三套随机逻辑（§Step 2）。
enum GameContentPicker {

    /// 从池中随机取 count 个（不足则全取）
    static func pick(_ count: Int, from items: [NatureItem]) -> [NatureItem] {
        guard count < items.count else { return items.shuffled() }
        return Array(items.shuffled().prefix(count))
    }

    /// 为目标从 pool 中挑 count 个干扰项（不与目标重复）。
    /// - Parameters:
    ///   - sameCategoryOnly: true 时只从同类别近似物中选（找相同 L3，差异更小）
    static func distractors(for target: NatureItem,
                            count: Int,
                            pool: [NatureItem],
                            sameCategoryOnly: Bool = false) -> [NatureItem] {
        var candidates = pool.filter { $0.id != target.id }
        if sameCategoryOnly {
            let same = candidates.filter { $0.category == target.category }
            if same.count >= count { candidates = same }
        }
        return pick(count, from: candidates)
    }

    /// 确保指定对象（详情页「玩一玩」focus）出现在本局内容里
    static func including(forced: [NatureItem], in picked: [NatureItem], totalCount: Int) -> [NatureItem] {
        var result = picked
        for f in forced where !result.contains(where: { $0.id == f.id }) {
            result.append(f)
        }
        // 超出总数时把非强制项挤掉
        if result.count > totalCount {
            var kept = forced
            for item in result where !kept.contains(where: { $0.id == item.id }) {
                if kept.count < totalCount { kept.append(item) }
            }
            result = kept
        }
        return result
    }

    /// Fisher–Yates 洗牌（数组扩展别名）
    static func shuffle<T>(_ items: [T]) -> [T] {
        items.shuffled()
    }
}
