import Foundation

/// 配对游戏引擎：N 组卡片翻面配对、状态机、容错判定（2-3 岁无惩罚，错误仅轻合上）。
final class MatchingEngine: ObservableObject, GameEngineProtocol {

    struct Card: Identifiable, Equatable {
        let id: UUID
        let item: NatureItem
        var isFaceUp: Bool = false
        var isMatched: Bool = false
    }

    enum FlipOutcome: Equatable {
        case ignored               // 已翻开/已配对/局已结束，不响应
        case firstFlip(UUID)       // 翻开第一张
        case matched(UUID, UUID)   // 两张配对成功（已锁定）
        case mismatch(UUID, UUID)  // 不匹配（视图延时后调 close 慢合上）
    }

    @Published private(set) var cards: [Card] = []
    @Published private(set) var isCompleted = false
    /// 参与本局的对象（组内容，顺序即配对成功顺序的来源池）
    private(set) var pickedItems: [NatureItem] = []

    var totalPairs: Int { pickedItems.count }
    var matchedPairs: Int { cards.filter(\.isMatched).count / 2 }

    // MARK: - 构建

    /// 从对象池随机抽 groupCount 组生成卡面（复制两份洗牌）；forced 中的对象保证参与。
    func prepare(pool: [NatureItem], groupCount: Int, forced: [NatureItem] = []) {
        let picked = GameContentPicker.pick(groupCount, from: pool)
        pickedItems = GameContentPicker.including(forced: forced, in: picked, totalCount: groupCount)
        let doubled = (pickedItems + pickedItems).map { Card(id: UUID(), item: $0) }
        cards = GameContentPicker.shuffle(doubled)
        isCompleted = false
    }

    // MARK: - 交互

    /// 翻开一张卡，返回判定结果
    @discardableResult
    func flip(_ cardId: UUID) -> FlipOutcome {
        guard !isCompleted,
              let index = cards.firstIndex(where: { $0.id == cardId }),
              !cards[index].isFaceUp,
              !cards[index].isMatched else { return .ignored }

        cards[index].isFaceUp = true

        let faceUpUnmatched = cards.filter { $0.isFaceUp && !$0.isMatched }
        guard faceUpUnmatched.count == 2,
              let a = faceUpUnmatched.first, let b = faceUpUnmatched.last else {
            return .firstFlip(cardId)
        }

        if a.item.id == b.item.id {
            // 配对成功：锁定
            if let ia = cards.firstIndex(where: { $0.id == a.id }),
               let ib = cards.firstIndex(where: { $0.id == b.id }) {
                cards[ia].isMatched = true
                cards[ib].isMatched = true
            }
            isCompleted = cards.allSatisfy(\.isMatched)
            return .matched(a.id, b.id)
        } else {
            return .mismatch(a.id, b.id)
        }
    }

    /// 不匹配的两张轻合上（由视图延时调用）
    func close(ids: [UUID]) {
        for id in ids {
            if let i = cards.firstIndex(where: { $0.id == id }) {
                cards[i].isFaceUp = false
            }
        }
    }

    /// 再玩一次：同一批对象重新洗牌、全部翻回
    func reset() {
        let doubled = (pickedItems + pickedItems).map { Card(id: UUID(), item: $0) }
        cards = GameContentPicker.shuffle(doubled)
        isCompleted = false
    }

    func item(contentId: String) -> NatureItem? {
        pickedItems.first { $0.id == contentId }
    }
}
