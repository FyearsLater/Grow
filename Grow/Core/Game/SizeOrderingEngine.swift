import Foundation

// MARK: - 排一排（大小排序）引擎（Phase 6.1 Step 10）
//
// 玩法：同一个素材生成 大 / 中 / 小 三个（运行时缩放，不新增图片 —— §二十二），
//      打乱后让孩子依次点出「最大的 → 中间的 → 最小的」。
// 第一阶段只做 大 → 小；错误只轻微提示，不显示错误/失败（§十）。

final class SizeOrderingEngine: ObservableObject {

    struct Object: Identifiable, Equatable {
        let id: String
        let item: NatureItem
        let size: SizeDefinition

        init(item: NatureItem, size: SizeDefinition) {
            self.id = "\(item.id)-\(size.rawValue)"
            self.item = item
            self.size = size
        }
    }

    @Published private(set) var pending: [Object] = []   // 待排列
    @Published private(set) var placed: [Object] = []    // 已放入的顺序
    @Published private(set) var isCompleted = false
    @Published private(set) var solvedItem: NatureItem?

    var allObjects: [Object] { placed + pending }

    /// 下一个应该放的是「剩余里最大的」
    var expectedNext: SizeDefinition? {
        pending.map(\.size).max()
    }

    // MARK: - 构建

    /// - Parameters:
    ///   - item: 支持 sizeGameSupported 的自然内容
    ///   - count: 物体数量（第一阶段固定 3）
    func prepare(item: NatureItem, count: Int = 3) {
        let sizes = Array(SizeDefinition.descending.prefix(max(1, count)))
        let objects = sizes.map { Object(item: item, size: $0) }
        pending = RandomizationService.shared.shuffle(objects)
        placed = []
        solvedItem = item
        isCompleted = false
    }

    // MARK: - 交互

    /// 点选一个物体放入下一位；返回是否放对
    @discardableResult
    func place(_ objectId: String) -> Bool {
        guard let index = pending.firstIndex(where: { $0.id == objectId }),
              let expected = expectedNext else { return false }
        let object = pending[index]
        guard object.size == expected else { return false }

        pending.remove(at: index)
        placed.append(object)
        if pending.isEmpty { isCompleted = true }
        return true
    }

    // MARK: - GameEngineProtocol

    func reset() {
        guard let item = solvedItem else { return }
        prepare(item: item, count: max(placed.count + pending.count, 3))
    }
}

extension SizeOrderingEngine: GameEngineProtocol {}
