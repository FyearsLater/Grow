import Foundation

/// 找相同游戏引擎：顶部目标 + 2~6 选项、点选判定、轮次推进。
final class FindSameEngine: ObservableObject {

    enum OptionState: Equatable {
        case normal
        case correct   // 打勾锁定
        case wrong     // 轻晃（视图反馈后可清除）
    }

    struct Option: Identifiable, Equatable {
        let id = UUID()
        let item: NatureItem
        let isCorrect: Bool
        var state: OptionState = .normal
    }

    struct Round: Identifiable, Equatable {
        let id: Int
        let target: NatureItem
        var options: [Option]
    }

    @Published private(set) var rounds: [Round] = []
    @Published private(set) var currentRound = 0
    @Published private(set) var isCompleted = false
    /// 找对的目标（按顺序记录，供完成页展示与名称朗读）
    @Published private(set) var solvedTargets: [NatureItem] = []

    var roundCount: Int { rounds.count }
    var currentRoundData: Round? {
        rounds.indices.contains(currentRound) ? rounds[currentRound] : nil
    }
    var lastSolvedTarget: NatureItem? { solvedTargets.last }

    // MARK: - 构建

    /// - Parameters:
    ///   - targets: 目标池（rounds 轮，每轮一个目标）；orderedTargets=true 时按传入顺序取（焦点对象当第一轮）
    ///   - pool: 干扰项来源池（全部自然对象或关卡池）
    ///   - optionCount: 选项数（含正确项，2~6）
    ///   - sameCategoryDistractors: 干扰项仅来自同类别（近似物）
    func prepare(targets: [NatureItem], pool: [NatureItem], rounds roundCount: Int,
                 optionCount: Int, sameCategoryDistractors: Bool = false,
                 orderedTargets: Bool = false) {
        let picked = orderedTargets
            ? Array(targets.prefix(roundCount))
            : GameContentPicker.pick(roundCount, from: targets)
        rounds = picked.enumerated().map { index, target in
            let distractors = GameContentPicker.distractors(for: target,
                                                            count: optionCount - 1,
                                                            pool: pool,
                                                            sameCategoryOnly: sameCategoryDistractors)
            let all = GameContentPicker.shuffle([true] + Array(repeating: false, count: distractors.count))
            var options: [Option] = []
            var dIndex = 0
            for isCorrect in all {
                if isCorrect {
                    options.append(Option(item: target, isCorrect: true))
                } else if dIndex < distractors.count {
                    options.append(Option(item: distractors[dIndex], isCorrect: false))
                    dIndex += 1
                }
            }
            return Round(id: index, target: target, options: options)
        }
        currentRound = 0
        solvedTargets = []
        isCompleted = false
    }

    // MARK: - 交互

    /// 点选一个选项；返回是否正确（正确时锁定该选项）
    @discardableResult
    func choose(_ optionId: UUID) -> Bool {
        guard !isCompleted, var round = currentRoundData,
              let oi = round.options.firstIndex(where: { $0.id == optionId }) else { return false }

        if round.options[oi].isCorrect {
            round.options[oi].state = .correct
            rounds[currentRound] = round
            solvedTargets.append(round.target)
            return true
        } else {
            round.options[oi].state = .wrong
            rounds[currentRound] = round
            return false
        }
    }

    /// 清除轻晃状态（视图动画结束后调用）
    func clearWrongStates() {
        guard var round = currentRoundData else { return }
        var changed = false
        for i in round.options.indices where round.options[i].state == .wrong {
            round.options[i].state = .normal
            changed = true
        }
        if changed { rounds[currentRound] = round }
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

    // MARK: - GameEngineProtocol（视图用 @StateObject 手动观察，isCompleted 已发布）

    /// 再玩一次：同一批轮次重置状态
    func reset() {
        for r in rounds.indices {
            for o in rounds[r].options.indices {
                rounds[r].options[o].state = .normal
            }
        }
        currentRound = 0
        solvedTargets = []
        isCompleted = false
    }
}

extension FindSameEngine: GameEngineProtocol {}
