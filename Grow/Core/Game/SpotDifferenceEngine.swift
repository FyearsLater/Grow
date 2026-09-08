import Foundation

// MARK: - 找不同引擎（Phase 6.1 Step 12）
//
// 玩法：4~6 个物体，其中 1 个不同，点出不同的那个。
//   L1：4 个，差异明显（跨类别取"异类"）
//   L2：5 个
//   L3：6 个（可同类近似）
// 不做成人式细节找茬（§十二）。

final class SpotDifferenceEngine: ObservableObject {

    struct Option: Identifiable, Equatable {
        let id: Int          // 位置下标（同一内容会重复出现，不能用内容 id 做标识）
        let item: NatureItem
        let isOdd: Bool
    }

    struct Round: Identifiable, Equatable {
        let id: Int
        let baseItem: NatureItem
        let oddItem: NatureItem
        var options: [Option]
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
    ///   - optionCount: 物体总数（4/5/6）
    ///   - sameCategory: true = 异类来自同类别（差异更小，L3）
    ///   - focus: 详情页焦点内容（作为"异类"优先）
    func prepare(rounds roundCount: Int, optionCount: Int,
                 sameCategory: Bool = false, focus: NatureItem? = nil) {
        let pool = GameContentResolver.shared.getContents(for: .spotDifference)
        guard pool.count >= 2, optionCount >= 3 else {
            rounds = []; currentRound = 0; isCompleted = false; solvedItems = []
            return
        }

        var built: [Round] = []
        for index in 0..<roundCount {
            guard let round = makeRound(id: index, pool: pool, optionCount: optionCount,
                                        sameCategory: sameCategory, focus: index == 0 ? focus : nil) else { continue }
            built.append(round)
        }

        rounds = built
        currentRound = 0
        solvedItems = []
        isCompleted = false
    }

    private func makeRound(id: Int, pool: [NatureItem], optionCount: Int,
                           sameCategory: Bool, focus: NatureItem?) -> Round? {
        // 焦点对象优先当"异类"
        var oddItem: NatureItem?
        if let focus, pool.contains(where: { $0.id == focus.id }) { oddItem = focus }

        if oddItem == nil {
            let shuffled = RandomizationService.shared.shuffle(pool)
            guard let candidate = shuffled.first else { return nil }
            oddItem = candidate
        }
        guard let odd = oddItem else { return nil }

        // 基准（重复出现的那些）：sameCategory 时同类别，否则跨类别更明显
        var basePool = pool.filter { $0.id != odd.id }
        if sameCategory {
            let sameCat = basePool.filter { $0.category == odd.category }
            if sameCat.count >= 1 { basePool = sameCat }
        } else {
            let diffCat = basePool.filter { $0.category != odd.category }
            if diffCat.count >= 1 { basePool = diffCat }
        }
        guard let base = RandomizationService.shared.shuffle(basePool).first else { return nil }

        var options: [Option] = Array(repeating: Option(id: 0, item: base, isOdd: false), count: optionCount - 1)
        options.append(Option(id: optionCount - 1, item: odd, isOdd: true))
        options = RandomizationService.shared.shuffle(options)
        // 重新编号，保证标识唯一且稳定
        options = options.enumerated().map { idx, option in
            Option(id: idx, item: option.item, isOdd: option.isOdd)
        }

        return Round(id: id, baseItem: base, oddItem: odd, options: options)
    }

    // MARK: - 交互

    @discardableResult
    func choose(_ optionId: Int) -> Bool {
        guard let round = currentRoundData,
              let option = round.options.first(where: { $0.id == optionId }) else { return false }
        if option.isOdd {
            solvedItems.append(option.item)
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

extension SpotDifferenceEngine: GameEngineProtocol {}
