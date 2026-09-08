import Foundation

// MARK: - 找颜色引擎（Phase 6.1 Step 8）
//
// 玩法（2-3 岁）：顶部给出目标颜色 → 下方 2~4 个自然内容 → 点出该颜色的那个。
// 内容全部来自 GameContentResolver（只取有 color 属性的内容），引擎不持有任何图片列表。

final class ColorGameEngine: ObservableObject {

    struct Option: Identifiable, Equatable {
        let id: String
        let item: NatureItem
        let isCorrect: Bool
    }

    struct Round: Identifiable, Equatable {
        let id: Int
        let color: ColorDefinition
        var options: [Option]
    }

    @Published private(set) var rounds: [Round] = []
    @Published private(set) var currentRound = 0
    @Published private(set) var isCompleted = false
    /// 已答对的内容（完成页展示用）
    @Published private(set) var solvedItems: [NatureItem] = []

    var currentRoundData: Round? {
        rounds.indices.contains(currentRound) ? rounds[currentRound] : nil
    }
    var lastSolvedItem: NatureItem? { solvedItems.last }

    // MARK: - 构建

    /// - Parameters:
    ///   - roundCount: 轮数
    ///   - optionCount: 每轮选项数（2~4）
    func prepare(rounds roundCount: Int, optionCount: Int) {
        let resolver = GameContentResolver.shared
        let colors = resolver.availableColors(minimum: 1)
        guard !colors.isEmpty, optionCount >= 2 else {
            rounds = []; currentRound = 0; isCompleted = false; solvedItems = []
            return
        }

        var built: [Round] = []
        for index in 0..<roundCount {
            let shuffledColors = RandomizationService.shared.shuffle(colors)
            guard let color = shuffledColors.first(where: { resolver.contents(withColor: $0).isEmpty == false })
                    ?? shuffledColors.first else { continue }
            let correctPool = resolver.contents(withColor: color)
            guard let target = RandomizationService.shared.shuffle(correctPool).first else { continue }

            // 干扰项：有颜色属性但颜色不同（保证"同色/异色"可辨识）
            let wrongPool = resolver.getContents(for: .color).filter { $0.color != color && $0.id != target.id }
            let distractors = Array(RandomizationService.shared.shuffle(wrongPool)
                .prefix(max(0, optionCount - 1)))

            var options = [Option(id: target.id, item: target, isCorrect: true)]
            options.append(contentsOf: distractors.map { Option(id: $0.id, item: $0, isCorrect: false) })
            options = RandomizationService.shared.shuffle(options)

            guard options.count >= 2 else { continue }
            built.append(Round(id: index, color: color, options: options))
        }

        rounds = built
        currentRound = 0
        solvedItems = []
        isCompleted = false
    }

    // MARK: - 交互

    /// 点选选项；返回是否正确
    @discardableResult
    func choose(_ optionId: String) -> Bool {
        guard let round = currentRoundData,
              let option = round.options.first(where: { $0.id == optionId }) else { return false }
        if option.isCorrect {
            solvedItems.append(option.item)
            return true
        }
        return false
    }

    /// 推进到下一轮 / 完成
    func advance() {
        guard currentRound < rounds.count else { return }
        if currentRound + 1 >= rounds.count {
            isCompleted = true
        } else {
            currentRound += 1
        }
    }

    // MARK: - GameEngineProtocol

    func reset() {
        currentRound = 0
        solvedItems = []
        isCompleted = false
    }
}

extension ColorGameEngine: GameEngineProtocol {}
