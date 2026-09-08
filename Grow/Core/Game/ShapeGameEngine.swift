import Foundation

// MARK: - 找形状引擎（Phase 6.1 Step 9）
//
// 玩法：顶部给出目标形状（圆形 / 三角形 / 方形）→ 下方 2~4 个自然内容 → 点出该形状的那个。
// 只取有 shape 属性的内容；形状判断不了的内容（shape = nil）不进池（§十九）。

final class ShapeGameEngine: ObservableObject {

    struct Option: Identifiable, Equatable {
        let id: String
        let item: NatureItem
        let isCorrect: Bool
    }

    struct Round: Identifiable, Equatable {
        let id: Int
        let shape: ShapeDefinition
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

    func prepare(rounds roundCount: Int, optionCount: Int) {
        let resolver = GameContentResolver.shared
        let shapes = resolver.availableShapes(minimum: 1)
        guard !shapes.isEmpty, optionCount >= 2 else {
            rounds = []; currentRound = 0; isCompleted = false; solvedItems = []
            return
        }

        var built: [Round] = []
        for index in 0..<roundCount {
            let shuffledShapes = RandomizationService.shared.shuffle(shapes)
            guard let shape = shuffledShapes.first(where: { resolver.contents(withShape: $0).isEmpty == false })
                    ?? shuffledShapes.first else { continue }
            let correctPool = resolver.contents(withShape: shape)
            guard let target = RandomizationService.shared.shuffle(correctPool).first else { continue }

            let wrongPool = resolver.getContents(for: .shape).filter { $0.shape != shape && $0.id != target.id }
            let distractors = Array(RandomizationService.shared.shuffle(wrongPool)
                .prefix(max(0, optionCount - 1)))

            var options = [Option(id: target.id, item: target, isCorrect: true)]
            options.append(contentsOf: distractors.map { Option(id: $0.id, item: $0, isCorrect: false) })
            options = RandomizationService.shared.shuffle(options)

            guard options.count >= 2 else { continue }
            built.append(Round(id: index, shape: shape, options: options))
        }

        rounds = built
        currentRound = 0
        solvedItems = []
        isCompleted = false
    }

    // MARK: - 交互

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

extension ShapeGameEngine: GameEngineProtocol {}
