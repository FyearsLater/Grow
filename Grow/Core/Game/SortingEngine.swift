import Foundation

/// 分类游戏引擎：待分类物品队列 + 2 个分类桶。
/// 吸附判定在视图层（宽松：落点距桶中心 < 桶宽 60% 即尝试入桶），
/// 引擎只负责"物品是否属于该桶"与完成判定。
final class SortingEngine: ObservableObject, GameEngineProtocol {

    struct SortItem: Identifiable, Equatable {
        let id = UUID()
        let item: NatureItem
    }

    struct Bucket: Identifiable, Equatable {
        let category: NatureCategory
        var placedCount: Int = 0
        var id: String { category.rawValue }
    }

    @Published private(set) var tray: [SortItem] = []
    @Published private(set) var buckets: [Bucket] = []
    @Published private(set) var isCompleted = false
    /// 已正确入桶的物品（按入桶顺序，供完成页展示）
    @Published private(set) var sortedItems: [NatureItem] = []

    var totalItems: Int { sortedItems.count + tray.count }
    var lastSortedItem: NatureItem? { sortedItems.last }

    // MARK: - 构建

    /// 从 items（关卡 contentIds 对应对象）中按桶分类抽取 perBucket 件/桶。
    func prepare(items: [NatureItem], pairs: [SortCategoryPair], perBucket: Int) {
        var tray: [SortItem] = []
        var buckets: [Bucket] = []
        for pair in pairs {
            guard let a = NatureCategory(rawValue: pair.categoryA),
                  let b = NatureCategory(rawValue: pair.categoryB) else { continue }
            for category in [a, b] {
                let pool = items.filter { $0.category == category }
                let picked = GameContentPicker.pick(perBucket, from: pool)
                tray.append(contentsOf: picked.map { SortItem(item: $0) })
                buckets.append(Bucket(category: category))
            }
        }
        self.tray = GameContentPicker.shuffle(tray)
        self.buckets = buckets
        sortedItems = []
        isCompleted = false
    }

    // MARK: - 交互

    /// 尝试把物品放进桶；返回是否放对（放对则入桶并更新进度）
    @discardableResult
    func drop(_ item: SortItem, into category: NatureCategory) -> Bool {
        guard !isCompleted, tray.contains(where: { $0.id == item.id }) else { return false }
        guard item.item.category == category else { return false }

        tray.removeAll { $0.id == item.id }
        sortedItems.append(item.item)
        if let bi = buckets.firstIndex(where: { $0.category == category }) {
            buckets[bi].placedCount += 1
        }
        isCompleted = tray.isEmpty
        return true
    }

    /// 再玩一次：同一批物品放回托盘
    func reset() {
        let all = sortedItems
        tray = GameContentPicker.shuffle(all.map { SortItem(item: $0) })
        for i in buckets.indices { buckets[i].placedCount = 0 }
        sortedItems = []
        isCompleted = false
    }
}
