import AVFoundation
import Foundation


/// 自然语音朗读器：用已下载的开源 TTS 模型（sherpa-onnx 离线推理）合成语音并播放。
/// 合成在后台线程进行，生成 WAV 后交给 AVAudioPlayer 播放，结束回调与 AVSpeechSynthesizer 对齐。
final class NaturalTTSPlayer: NSObject, ObservableObject {
    static let shared = NaturalTTSPlayer()

    /// 正在后台合成（用于 UI 显示轻微等待状态）
    @Published private(set) var isGenerating = false

    private var engines: [String: Any] = [:]
    private var player: AVAudioPlayer?
    private var onFinish: (() -> Void)?
    private var currentKey: String?
    private let queue = DispatchQueue(label: "grow.naturaltts", qos: .userInitiated)

    /// 指定语言是否有已安装的自然语音包
    func isReady(for language: SpeechLanguage) -> Bool {
        VoicePackManager.shared.installedPack(for: language) != nil
    }

    /// 删除/重装语音包后使引擎缓存失效
    func invalidate() {
        queue.async { [weak self] in
            self?.engines.removeAll()
        }
    }

    /// 朗读一段文本（结束回调在主线程）
    func speak(text: String, language: SpeechLanguage, speed: Float, key: String, onFinished: (() -> Void)?) {
        stop()
        onFinish = onFinished
        currentKey = key
        isGenerating = true
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.synthesize(text: text, language: language, speed: speed)
            DispatchQueue.main.async {
                self.isGenerating = false
                guard let url = result else {
                    // 合成失败：按结束处理，不阻塞 UI 状态
                    let cb = self.onFinish
                    self.stop()
                    cb?()
                    return
                }
                self.play(url: url)
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        onFinish = nil
        currentKey = nil
    }

    // MARK: - 合成

    /// 合成并返回临时 WAV 文件
    private func synthesize(text: String, language: SpeechLanguage, speed: Float) -> URL? {
        guard let pack = VoicePackManager.shared.installedPack(for: language) else { return nil }
        let engine = self.engine(for: pack)
        let generated = engine.generate(text: text, sid: pack.speakerID, speed: speed)
        guard generated.n > 0 else { return nil }
        let out = FileManager.default.temporaryDirectory
            .appendingPathComponent("grow-tts-\(UUID().uuidString).wav")
        guard generated.save(filename: out.path) != 0 else { return nil }
        return out
    }

    /// 按语音包构建（并缓存）离线 TTS 引擎
    private func engine(for pack: VoicePack) -> SherpaOnnxOfflineTtsWrapper {
        if let cached = engines[pack.id] as? SherpaOnnxOfflineTtsWrapper {
            return cached
        }
        let dir = VoicePackManager.shared.installDir(pack).path
        var vits = sherpaOnnxOfflineTtsVitsModelConfig(
            model: dir + "/" + pack.modelFile,
            lexicon: dir + "/" + pack.lexiconFile,
            tokens: dir + "/" + pack.tokensFile,
            dictDir: pack.dictDir.map { dir + "/" + $0 } ?? ""
        )
        var modelConfig = sherpaOnnxOfflineTtsModelConfig(vits: vits, numThreads: 2)
        let ruleFsts = pack.ruleFsts.map { dir + "/" + $0 }.joined(separator: ",")
        var config = sherpaOnnxOfflineTtsConfig(model: modelConfig, ruleFsts: ruleFsts)
        let engine = SherpaOnnxOfflineTtsWrapper(config: &config)
        engines[pack.id] = engine
        return engine
    }

    // MARK: - 播放

    private func play(url: URL) {
        guard let p = try? AVAudioPlayer(contentsOf: url) else {
            let cb = onFinish
            stop()
            cb?()
            return
        }
        player = p
        p.delegate = self
        p.play()
    }
}

extension NaturalTTSPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let cb = onFinish
        stop()
        cb?()
    }
}
