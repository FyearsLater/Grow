import AVFoundation
import Foundation

/// 语音语言
enum SpeechLanguage: String, Codable, CaseIterable, Identifiable {
    case mandarin = "zh-CN"   // 普通话
    case cantonese = "zh-HK"  // 粤语
    case english = "en-US"    // 英语

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mandarin: return "国"
        case .cantonese: return "粤"
        case .english: return "En"
        }
    }

    var fullName: String {
        switch self {
        case .mandarin: return "国语"
        case .cantonese: return "粤语"
        case .english: return "英语"
        }
    }

    var symbol: String {
        switch self {
        case .mandarin: return "🇨🇳"
        case .cantonese: return "🇭🇰"
        case .english: return "🇬🇧"
        }
    }

    /// 同语系 fallback 顺序：找不到精确匹配时按这个顺序回退
    /// 国语：zh-CN → zh-TW（台湾普通话，仍是国语腔）→ zh-HK（最后兜底，保证能出声）
    /// 粤语：zh-HK → zh-TW → zh-CN（尽力发声：没有粤语语音包时，
    /// 优先借用台湾普通话，再退到任意中文语音，保证按钮永远可用、总能出声）
    var fallbackLanguageCodes: [String] {
        switch self {
        case .mandarin: return ["zh-TW", "zh-HK"]
        case .cantonese: return ["zh-TW", "zh-CN"]
        case .english: return ["en-GB", "en-AU", "en-US"]
        }
    }

    /// iOS 设置中显示的语音名称（用于引导用户去设置下载）
    var iosSettingsVoiceName: String {
        switch self {
        case .mandarin: return "中文（中国大陆）"
        case .cantonese: return "中文（香港）"
        case .english: return "English (United States)"
        }
    }
}

/// 古诗词朗读音色角色
enum PoemVoiceRole: String, Codable, CaseIterable, Identifiable {
    case boyKid     = "boy_kid"      // 小男孩
    case girlKid    = "girl_kid"     // 小女孩
    case manAdult   = "man_adult"    // 男大
    case womanAdult = "woman_adult"  // 女大

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .boyKid: return "小男孩"
        case .girlKid: return "小女孩"
        case .manAdult: return "男大"
        case .womanAdult: return "女大"
        }
    }

    var icon: String {
        switch self {
        case .boyKid: return "👦🏻"
        case .girlKid: return "👧🏻"
        case .manAdult: return "👨🏻"
        case .womanAdult: return "👩🏻"
        }
    }

    /// 用于调整音高，让小朋友/大人的音色更有区分度
    var pitchMultiplier: Float {
        switch self {
        case .boyKid: return 1.22
        case .girlKid: return 1.08
        case .manAdult: return 0.88
        case .womanAdult: return 1.00
        }
    }

    /// 偏好的系统 voice gender（iOS 不保证所有 voice 都有性别标记，仅作参考）
    var preferredGender: AVSpeechSynthesisVoiceGender {
        switch self {
        case .boyKid, .manAdult: return .male
        case .girlKid, .womanAdult: return .female
        }
    }
}

/// AudioManager：统一管理所有语音播放。
/// MVP 使用系统 TTS（AVSpeechSynthesizer）；
/// 未来可替换为预置音频（AVAudioPlayer）、专业配音或云端 TTS，
/// 只需保持本接口不变，UI 层无需改动。
final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    /// 当前正在播放的标识（用于 UI 显示波纹/高亮，如 "fruit_apple-mandarin"、"poem_jingyesi-line-1"）
    @Published var playingKey: String?
    /// 整首朗读时当前高亮的诗句下标
    @Published var speakingLineIndex: Int?
    /// 系统是否装了该语言的 voice（用于 UI 显示按钮可用性）
    @Published private(set) var availableLanguages: Set<SpeechLanguage> = []

    private let synthesizer = AVSpeechSynthesizer()
    private var lineRangeMap: [(range: NSRange, index: Int)] = []
    private var onFinished: (() -> Void)?
    /// 整首古诗逐句朗读队列
    private var currentPoem: Poem?
    private var poemLineQueue: [PoemLine] = []

    override private init() {
        super.init()
        synthesizer.delegate = self
        // 混音模式：让语音在其他音频（如背景音乐）之上播放，且遵循静音键
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
        refreshAvailability()
        #if DEBUG
        // 调试：列出系统所有中文+英文 voice，帮助排查国粤同音问题
        let all = AVSpeechSynthesisVoice.speechVoices()
        let wanted = all.filter { $0.language.hasPrefix("zh") || $0.language.hasPrefix("en") }
        for v in wanted.sorted(by: { $0.language < $1.language }) {
            print("[TTS] \(v.language)\t\(v.name)\tquality=\(v.quality.rawValue)")
        }
        print("[TTS] zh-CN picked:", Self.bestVoice(for: .mandarin)?.name ?? "nil")
        print("[TTS] zh-HK picked:", Self.bestVoice(for: .cantonese)?.name ?? "nil")
        print("[TTS] en-US picked:", Self.bestVoice(for: .english)?.name ?? "nil")
        print("[TTS] available:", availableLanguages.map { $0.rawValue }.sorted())
        #endif
    }

    /// 重新检测 voice 可用性（可手动调用，例如用户回到前台时）
    func refreshAvailability() {
        var set: Set<SpeechLanguage> = []
        for lang in SpeechLanguage.allCases {
            if Self.bestVoice(for: lang) != nil { set.insert(lang) }
        }
        DispatchQueue.main.async { self.availableLanguages = set }
    }

    // MARK: - 自然对象发音

    /// 播放某个自然对象的指定语言发音（同样应用朗读音色设置）
    func speak(name: String, language: SpeechLanguage, key: String, onFinished: (() -> Void)? = nil) {
        stop()
        self.onFinished = onFinished
        let settings = SettingsManager.shared
        let utterance = AVSpeechUtterance(string: name)
        utterance.voice = voice(for: language, role: settings.poemVoice)
        utterance.rate = Self.rate(for: settings.speechSpeed)
        utterance.pitchMultiplier = settings.poemVoice.pitchMultiplier
        utterance.postUtteranceDelay = 0.2
        playingKey = key
        synthesizer.speak(utterance)
    }

    /// 播放古诗单句
    func speakPoemLine(_ text: String, key: String) {
        stop()
        let settings = SettingsManager.shared
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: settings.poemLanguage, role: settings.poemVoice)
        utterance.rate = Self.rate(for: settings.speechSpeed)
        utterance.pitchMultiplier = settings.poemVoice.pitchMultiplier
        utterance.postUtteranceDelay = 0.3
        playingKey = key
        synthesizer.speak(utterance)
    }

    /// 朗读整首古诗：逐句加入队列，句间按设置停顿，高亮当前句
    func speakPoem(_ poem: Poem) {
        stop()
        guard !poem.lines.isEmpty else { return }
        currentPoem = poem
        poemLineQueue = poem.lines
        speakingLineIndex = 0
        playingKey = "poem-\(poem.id)"
        speakNextPoemLine()
    }

    private func speakNextPoemLine() {
        guard let line = poemLineQueue.first else { return }
        let settings = SettingsManager.shared
        let utterance = AVSpeechUtterance(string: line.text)
        utterance.voice = voice(for: settings.poemLanguage, role: settings.poemVoice)
        utterance.rate = Self.rate(for: settings.speechSpeed)
        utterance.pitchMultiplier = settings.poemVoice.pitchMultiplier
        utterance.preUtteranceDelay = 0.05
        // 最后一句不需要停顿，其他句按设置停
        utterance.postUtteranceDelay = poemLineQueue.count == 1 ? 0 : settings.poemPause

        let idx = (currentPoem?.lines.count ?? poemLineQueue.count) - poemLineQueue.count
        speakingLineIndex = idx
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        playingKey = nil
        speakingLineIndex = nil
        lineRangeMap = []
        currentPoem = nil
        poemLineQueue = []
        onFinished = nil
    }

    // MARK: - Helpers

    private func voice(for language: SpeechLanguage, role: PoemVoiceRole? = nil) -> AVSpeechSynthesisVoice? {
        Self.bestVoice(for: language, role: role)
    }

    /// 在系统所有 voice 中为指定语言选一个最匹配的：
    /// 1) 若指定了朗读角色，优先按性别/质量匹配
    /// 2) 优先 quality 最高的（enhanced > default）
    /// 3) 若该语言完全无 voice，按 SpeechLanguage.fallbackLanguageCodes 顺序回退（同语系，不跨方言）
    /// 4) 完全找不到则返回 nil（由 UI 禁用按钮）
    static func bestVoice(for language: SpeechLanguage, role: PoemVoiceRole? = nil) -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let exact = all.filter { $0.language == language.rawValue }

        if let role, !exact.isEmpty {
            let gendered = exact.filter { $0.gender == role.preferredGender }
            let pool = gendered.isEmpty ? exact : gendered
            if let best = pool.max(by: { $0.quality.rawValue < $1.quality.rawValue }) {
                return best
            }
        }

        if let best = exact.max(by: { $0.quality.rawValue < $1.quality.rawValue }) {
            return best
        }

        // 同语系 fallback（普通话 → 台湾普通话 → 粤语；粤语 → 台湾普通话 → 国语，保证总能出声）
        for code in language.fallbackLanguageCodes {
            let candidates = all.filter { $0.language == code }
            if let best = candidates.max(by: { $0.quality.rawValue < $1.quality.rawValue }) {
                return best
            }
        }
        return nil
    }

    /// 将设置档位（0.75 / 1.0 / 1.25）映射到 TTS 语速
    static func rate(for speed: Double) -> Float {
        // AVSpeechUtteranceDefaultSpeechRate ≈ 0.5
        Float(0.42 * speed)
    }

    /// 给定朗读角色对应的音高倍数
    static func pitch(for role: PoemVoiceRole) -> Float {
        role.pitchMultiplier
    }
}

extension AudioManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        // 整首朗读时高亮当前句（兼容旧版整段文本模式，实际现在使用逐句队列）
        if let hit = lineRangeMap.first(where: { NSLocationInRange(characterRange.location, $0.range) }) {
            DispatchQueue.main.async { self.speakingLineIndex = hit.index }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            // 若正在整首古诗逐句朗读，自动播放下一句
            if !self.poemLineQueue.isEmpty {
                self.poemLineQueue.removeFirst()
                if self.poemLineQueue.isEmpty {
                    self.currentPoem = nil
                    self.playingKey = nil
                    self.speakingLineIndex = nil
                    self.onFinished?()
                    self.onFinished = nil
                } else {
                    self.speakNextPoemLine()
                }
            } else {
                self.playingKey = nil
                self.speakingLineIndex = nil
                self.onFinished?()
                self.onFinished = nil
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.playingKey = nil
            self.speakingLineIndex = nil
            self.currentPoem = nil
            self.poemLineQueue = []
        }
    }
}
