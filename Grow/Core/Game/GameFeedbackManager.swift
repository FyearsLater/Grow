import Foundation

/// 游戏统一反馈：正确短语池 + 错误引导语 + 柔和系统短音 + TTS（跟随默认语言，粤语模式下提示语同样粤语朗读）。
/// 反馈语唯一维护处（§跨文件约定 5）；错误操作无任何音效，只有语音引导（§47）。
final class GameFeedbackManager: ObservableObject {
    static let shared = GameFeedbackManager()

    /// 反馈种类：供视图做轻动画（配合 GrowAnimation 门控）
    enum Kind: Equatable {
        case none
        case correct
        case retry
    }

    /// 最近一次反馈（视图 @ObservedObject 观察）
    @Published private(set) var lastFeedback: Kind = .none
    /// 自增序号：同类反馈连续发生时也能再次触发轻动画
    @Published private(set) var feedbackToken = 0

    private static let correctPhrases = ["找到了！", "很棒！", "对啦！"]
    private static let retryPhrases = ["再看看～", "换个地方试试～"]

    private var lastPhrase: String?

    private init() {}

    // MARK: - 反馈

    /// 正确：柔和短音 + 正向短语（可附带对象名一起朗读，如 "找到了！苹果"）
    func correct(gameId: String, itemName: String? = nil) {
        let phrase = Self.randomPhrase(from: Self.correctPhrases)
        let text = itemName.map { "\(phrase)\($0)" } ?? phrase
        GameSound.correct.play()
        speak(text, gameId: gameId, purpose: "correct")
        publish(.correct)
    }

    /// 错误：仅语音引导（"再看看～"），无错误音、无红叉
    func retry(gameId: String) {
        let phrase = Self.randomPhrase(from: Self.retryPhrases)
        speak(phrase, gameId: gameId, purpose: "retry")
        publish(.retry)
    }

    /// 开局指令（大字说明同步自动朗读）
    func speakInstruction(_ text: String, gameId: String) {
        speak(text, gameId: gameId, purpose: "instruct")
    }

    /// 单独朗读对象名（如配对成功后的名称强化）
    func speakItemName(_ name: String, gameId: String) {
        speak(name, gameId: gameId, purpose: "item")
    }

    // MARK: - Helpers

    private func publish(_ kind: Kind) {
        lastFeedback = kind
        feedbackToken += 1
    }

    /// 所有游戏语音统一走 AudioManager.speak（语言跟随 SettingsManager.defaultLanguage，§音频唯一出口）。
    /// 游戏反馈是自动语音：未下载自然语音包时静默回退系统语音，不弹窗打断游戏。
    private func speak(_ text: String, gameId: String, purpose: String) {
        AudioManager.shared.speak(name: text,
                                  language: SettingsManager.shared.defaultLanguage,
                                  key: "game-\(gameId)-\(purpose)",
                                  promptIfMissing: false)
    }

    /// 随机取用、避免连续重复
    private static func randomPhrase(from pool: [String]) -> String {
        guard pool.count > 1 else { return pool.first ?? "" }
        var candidate = pool.randomElement() ?? pool[0]
        if candidate == shared.lastPhrase {
            candidate = pool.first(where: { $0 != shared.lastPhrase }) ?? candidate
        }
        shared.lastPhrase = candidate
        return candidate
    }
}
