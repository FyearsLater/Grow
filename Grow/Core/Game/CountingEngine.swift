import Foundation

// MARK: - 数一数引擎（Phase 6.1 Step 11）
//
// 玩法1：显示 N 个物品 → 下方 1/2/3 选项 → 选出正确数量。
// 与「看图识字 0-9」区分开：本阶段只训练 1–3（§四），区间来自内容 countingRange。

final class CountingEngine: ObservableObject {

    struct Round: Identifiable, Equatable {
        let id: Int
        let item: NatureItem
        /// 正确数量
        let count: Int
        /// 可选数量（升序展示，方便儿童找）
        let options: [Int]
    }

    @Published private(set) var rounds: [Round] = []
    @Published private(set) var currentRound = 0
    @Published private(set) var isCompleted = false
    @Published private(set) var solvedItems: [NatureItem] = []

    var currentRoundData: Round? {
        rounds.indices.contains(currentRound) ? rounds[currentRound] : nil
    }
    var lastSolvedItem: NatureItem? { solvedItems.last }

    // MARK: - 构建

    /// - Parameters:
    ///   - roundCount: 轮数
    ///   - optionCount: 选项数（2~3）
    ///   - focus: 详情页带入的焦点内容（第一轮强制用它）
    func prepare(rounds roundCount: Int, optionCount: Int, focus: NatureItem? = nil) {
        let pool = GameContentResolver.shared.getContents(for: .counting)
        guard !pool.isEmpty else {
            rounds = []; currentRound = 0; isCompleted = false; solvedItems = []
            return
        }

        var ordered = RandomizationService.shared.shuffle(pool)
        if let focus, pool.contains(where: { $0.id == focus.id }) {
            ordered.removeAll { $0.id == focus.id }
            ordered.insert(focus, at: 0)
        }

        var built: [Round] = []
        for (index, item) in ordered.prefix(roundCount).enumerated() {
            let bounds = item.countingBounds
            let upper = max(bounds.lowerBound, min(bounds.upperBound, 3))   // 第一阶段封顶 3
            let lower = min(bounds.lowerBound, upper)
            guard let answer = (lower...upper).randomElement() else { continue }
            guard let round = makeRound(id: index, item: item, answer: answer,
                                        lower: lower, upper: upper, optionCount: optionCount) else { continue }
            built.append(round)
        }

        rounds = built
        currentRound = 0
        solvedItems = []
        isCompleted = false
    }

    private func makeRound(id: Int, item: NatureItem, answer: Int,
                           lower: Int, upper: Int, optionCount: Int) -> Round? {
        var options = Set<Int>([answer])
        let others = RandomizationService.shared.shuffle(Array(lower...upper).filter { $0 != answer })
        for value in others where options.count < optionCount { options.insert(value) }
        // 区间内凑不够选项时，向 1...upper 补齐（仍保持 1–3 内）
        if options.count < optionCount {
            for value in RandomizationService.shared.shuffle(Array(1...upper)) where options.count < optionCount {
                options.insert(value)
            }
        }
        guard options.count >= 2 else { return nil }
        return Round(id: id, item: item, count: answer, options: options.sorted())
    }

    // MARK: - 交互

    @discardableResult
    func choose(_ value: Int) -> Bool {
        guard let round = currentRoundData else { return false }
        if round.count == value {
            solvedItems.append(round.item)
            return true
        }
        return false
    }

    func advance() {
        guard currentRound < rounds.count else { return }
        if currentRound + 1 >= rounds.count {
            isCompleted = true
        } else {
            currentRound += 1
        }
    }

    func reset() {
        currentRound = 0
        solvedItems = []
        isCompleted = false
    }
}

extension CountingEngine: GameEngineProtocol {}
