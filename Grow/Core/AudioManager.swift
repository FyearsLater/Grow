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

    /// 系统 TTS 匹配用的语言码候选（按优先级，全部为「精确匹配」）。
    /// ⚠️ iOS 17+ 起，内置粤语语音（Sinji）的 `language` 是 **yue-HK** 而不是 zh-HK
    /// （仅 identifier 里仍写作 com.apple.voice.*.zh-HK.Sinji）。
    /// 只认 zh-HK 会永远匹配不到内置粤语，表现为「粤语发不出声 / 听起来像国语」。
    var candidateCodes: [String] {
        switch self {
        case .mandarin: return ["zh-CN"]
        case .cantonese: return ["yue-HK", "zh-HK"]
        case .english: return ["en-US"]
        }
    }

    /// 同语系 fallback 顺序：精确匹配全部落空时才按这个顺序回退，保证按钮永远能出声
    /// 国语：zh-CN → zh-TW（台湾普通话，仍是国语腔）
    /// 粤语：yue-HK/zh-HK → zh-TW → zh-CN（内置粤语几乎总能命中，这里只是兜底）
    var fallbackLanguageCodes: [String] {
        switch self {
        case .mandarin: return ["zh-TW", "yue-HK"]
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
    /// 自然语音引擎（开源 TTS 模型，sherpa-onnx 离线推理）；已下载语音包的语言优先走这里
    private let naturalPlayer = NaturalTTSPlayer.shared
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
        print("[TTS] zh-HK exact voice installed:", Self.hasExactVoice(for: .cantonese))
        #endif
    }

    /// 重新检测 voice 可用性（可手动调用，例如用户回到前台时）
    func refreshAvailability() {
        var set: Set<SpeechLanguage> = []
        for lang in SpeechLanguage.allCases {
            if Self.bestVoice(for: lang) != nil { set.insert(lang) }
        }
        DispatchQueue.main.async {
            self.availableLanguages = set
            #if DEBUG
            print("[TTS] available:", set.map { $0.rawValue }.sorted())
            #endif
        }
    }

    /// 系统是否有该语言的精确语音（不含 fallback 回退）。
    /// 粤语需同时认 yue-HK（iOS 17+ 内置）与 zh-HK（旧系统）。
    static func hasExactVoice(for language: SpeechLanguage) -> Bool {
        let all = AVSpeechSynthesisVoice.speechVoices()
        return language.candidateCodes.contains { code in all.contains { $0.language == code } }
    }

    // MARK: - 自然对象发音

    /// 播放某个自然对象的指定语言发音（同样应用朗读音色设置）。
    /// 引擎选择：已下载自然语音包 → 开源 TTS；未下载 → 弹窗引导（或按 promptIfMissing=false 静默回退系统语音）。
    /// - promptIfMissing: 用户主动点击朗读=true；游戏反馈等自动语音=false（不打断游戏）
    func speak(name: String, language: SpeechLanguage, key: String, onFinished: (() -> Void)? = nil, promptIfMissing: Bool = true) {
        // 粤语独立处理：系统语音包常缺失，优先开源粤语模型，其次精确 zh-HK，都没有才引导下载
        if language == .cantonese {
            speakCantonese(text: name, key: key, onFinished: onFinished, promptIfMissing: promptIfMissing)
            return
        }
        // 引擎开关关闭时（默认）：走第一版系统 TTS，不查语音包、不弹下载引导
        guard SettingsManager.shared.useNaturalVoice else {
            speakWithSystem(text: name, language: language, key: key, onFinished: onFinished)
            return
        }
        if naturalPlayer.isReady(for: language) {
            stop()
            self.onFinished = onFinished
            playingKey = key
            naturalPlayer.speak(
                text: name,
                language: language,
                speed: Float(SettingsManager.shared.speechSpeed),
                key: key
            ) { [weak self] in
                guard let self else { return }
                if self.playingKey == key { self.playingKey = nil }
                let cb = self.onFinished
                self.onFinished = nil
                cb?()
            }
            return
        }
        if promptIfMissing {
            stop()
            VoicePackPromptCenter.shared.suggestDownload(language: language, sampleText: name)
            return
        }
        speakWithSystem(text: name, language: language, key: key, onFinished: onFinished)
    }

    /// 粤语发音优先级：
    /// 1) 开关开启 + 开源粤语模型（音质最好）
    /// 2) 系统内置粤语（iOS 17+ 为 yue-HK / Sinji，机器基本都有——此前匹配不到是标签 bug，已修）
    /// 3) 开关关闭但系统无粤语 → 仍用已下载的开源模型（好过国语近似回退）
    /// 4) 两者皆无：主动点击 → 引导下载；游戏内自动语音 → 近似回退，不打断
    private func speakCantonese(text: String, key: String, onFinished: (() -> Void)?, promptIfMissing: Bool) {
        let systemHasCantonese = Self.hasExactVoice(for: .cantonese)
        let useNatural = SettingsManager.shared.useNaturalVoice && naturalPlayer.isReady(for: .cantonese)

        if useNatural || (!systemHasCantonese && naturalPlayer.isReady(for: .cantonese)) {
            stop()
            self.onFinished = onFinished
            playingKey = key
            naturalPlayer.speak(
                text: text,
                language: .cantonese,
                speed: Float(SettingsManager.shared.speechSpeed),
                key: key
            ) { [weak self] in
                guard let self else { return }
                if self.playingKey == key { self.playingKey = nil }
                let cb = self.onFinished
                self.onFinished = nil
                cb?()
            }
            return
        }
        // 2) 系统内置粤语（yue-HK / zh-HK）
        if systemHasCantonese {
            speakWithSystem(text: text, language: .cantonese, key: key, onFinished: onFinished)
            return
        }
        // 4) 都没有：主动点击 → 引导下载；游戏内自动语音 → 近似回退，不打断
        if promptIfMissing {
            stop()
            VoicePackPromptCenter.shared.suggestDownload(language: .cantonese, sampleText: text)
            return
        }
        speakWithSystem(text: text, language: .cantonese, key: key, onFinished: onFinished)
    }

    /// 系统语音（AVSpeechSynthesizer）朗读——未安装自然语音包时的回退路径
    private func speakWithSystem(text: String, language: SpeechLanguage, key: String, onFinished: (() -> Void)?) {
        stop()
        self.onFinished = onFinished
        let settings = SettingsManager.shared
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(for: language, role: settings.poemVoice)
        utterance.rate = Self.rate(for: settings.speechSpeed)
        utterance.pitchMultiplier = settings.poemVoice.pitchMultiplier
        utterance.postUtteranceDelay = 0.2
        playingKey = key
        synthesizer.speak(utterance)
    }

    /// 播放古诗单句
    func speakPoemLine(_ text: String, key: String) {
        // 粤语单句同样走粤语专用链路
        if SettingsManager.shared.poemLanguage == .cantonese {
            speakCantonese(text: text, key: key, onFinished: nil, promptIfMissing: true)
            return
        }
        guard SettingsManager.shared.useNaturalVoice else {
            speakPoemLineSystem(text, key: key)
            return
        }
        let lang = SettingsManager.shared.poemLanguage
        if naturalPlayer.isReady(for: lang) {
            stop()
            playingKey = key
            naturalPlayer.speak(
                text: text,
                language: lang,
                speed: Float(SettingsManager.shared.speechSpeed),
                key: key
            ) { [weak self] in
                guard let self else { return }
                if self.playingKey == key { self.playingKey = nil }
            }
            return
        }
        speakPoemLineSystem(text, key: key)
    }

    private func speakPoemLineSystem(_ text: String, key: String) {
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
        // 粤语整首朗读：既无开源模型也无系统精确语音包 → 先引导下载，不用国语顶替
        if SettingsManager.shared.poemLanguage == .cantonese,
           !naturalPlayer.isReady(for: .cantonese),
           !Self.hasExactVoice(for: .cantonese) {
            VoicePackPromptCenter.shared.suggestDownload(language: .cantonese, sampleText: "《\(poem.title)》")
            return
        }
        // 引擎开关关闭时（默认）：走第一版系统 TTS 逐句朗读，不弹下载引导
        guard SettingsManager.shared.useNaturalVoice else {
            stop()
            guard !poem.lines.isEmpty else { return }
            currentPoem = poem
            poemLineQueue = poem.lines
            speakingLineIndex = 0
            playingKey = "poem-\(poem.id)"
            speakNextPoemLine()
            return
        }
        let lang = SettingsManager.shared.poemLanguage
        if !naturalPlayer.isReady(for: lang), lang != .cantonese {
            VoicePackPromptCenter.shared.suggestDownload(language: lang, sampleText: "《\(poem.title)》")
            return
        }
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
        let idx = (currentPoem?.lines.count ?? poemLineQueue.count) - poemLineQueue.count
        speakingLineIndex = idx

        // 自然语音链：仅在引擎开关打开且语音包就绪时启用（默认关闭 → 走系统语音链）
        if SettingsManager.shared.useNaturalVoice, naturalPlayer.isReady(for: settings.poemLanguage) {
            naturalPlayer.speak(
                text: line.text,
                language: settings.poemLanguage,
                speed: Float(settings.speechSpeed),
                key: "poem-\(currentPoem?.id ?? "x")-\(idx)"
            ) { [weak self] in
                guard let self else { return }
                self.poemLineQueue.removeFirst()
                if self.poemLineQueue.isEmpty {
                    self.currentPoem = nil
                    self.playingKey = nil
                    self.speakingLineIndex = nil
                    self.onFinished?()
                    self.onFinished = nil
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + settings.poemPause) {
                        self.speakNextPoemLine()
                    }
                }
            }
            return
        }

        // 系统语音链（回退）
        let utterance = AVSpeechUtterance(string: line.text)
        utterance.voice = voice(for: settings.poemLanguage, role: settings.poemVoice)
        utterance.rate = Self.rate(for: settings.speechSpeed)
        utterance.pitchMultiplier = settings.poemVoice.pitchMultiplier
        utterance.preUtteranceDelay = 0.05
        // 最后一句不需要停顿，其他句按设置停
        utterance.postUtteranceDelay = poemLineQueue.count == 1 ? 0 : settings.poemPause

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        naturalPlayer.stop()
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
    /// 1) 按候选语言码精确匹配（粤语认 yue-HK / zh-HK 两个标签）
    /// 2) 若指定了朗读角色，优先按性别/质量匹配
    /// 3) 优先 quality 最高的（enhanced > default）
    /// 4) 精确匹配落空，按 fallbackLanguageCodes 顺序回退（保证总能出声）
    /// 5) 完全找不到则返回 nil（由 UI 禁用按钮）
    static func bestVoice(for language: SpeechLanguage, role: PoemVoiceRole? = nil) -> AVSpeechSynthesisVoice? {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let exact = all.filter { language.candidateCodes.contains($0.language) }

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
