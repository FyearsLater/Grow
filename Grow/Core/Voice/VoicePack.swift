import Foundation

/// 可下载的自然语音包（开源 TTS 模型，经 sherpa-onnx 离线推理）。
/// 模型来源（均为开源可商用研究模型）：
/// - 普通话+英语：vits-melo-tts-zh_en（MeloTTS，int8 量化 ~53MB）
/// - 粤语：vits-cantonese-hf-xiaomaiiwn（Cantonese VITS ~114MB）
/// 下载走 hf-mirror.com 镜像，国内网络友好；下载一次后离线可用，不再需要网络。
struct VoicePackFile {
    let path: String     // 相对模型目录
    let size: Int64      // 字节（用于进度与预估）

    func url(repo: String, base: String = "https://hf-mirror.com") -> URL {
        URL(string: "\(base)/\(repo)/resolve/main/\(path)")!
    }
}

struct VoicePack: Identifiable {
    let id: String
    let displayName: String
    let subtitle: String
    let repo: String                       // HF 模型仓库名
    let languages: [SpeechLanguage]        // 覆盖的朗读语言
    let modelFile: String
    let lexiconFile: String
    let tokensFile: String
    let ruleFsts: [String]                 // 文本正则化 FST（数字/日期等转读法）
    let dictDir: String?                   // 需按目录展开下载的词典（下载时经 API 列出）
    let files: [VoicePackFile]             // 固定文件清单
    let speakerID: Int

    static let meloZhEn = VoicePack(
        id: "vits-melo-tts-zh_en",
        displayName: "普通话 · 英语",
        subtitle: "自然女声（MeloTTS 开源模型）",
        repo: "csukuangfj/vits-melo-tts-zh_en",
        languages: [.mandarin, .english],
        modelFile: "model.int8.onnx",
        lexiconFile: "lexicon.txt",
        tokensFile: "tokens.txt",
        ruleFsts: ["date.fst", "new_heteronym.fst", "number.fst", "phone.fst"],
        dictDir: "dict",
        files: [
            VoicePackFile(path: "model.int8.onnx", size: 53_517_430),
            VoicePackFile(path: "lexicon.txt", size: 6_837_671),
            VoicePackFile(path: "tokens.txt", size: 655),
            VoicePackFile(path: "date.fst", size: 59_154),
            VoicePackFile(path: "new_heteronym.fst", size: 21_974),
            VoicePackFile(path: "number.fst", size: 64_482),
            VoicePackFile(path: "phone.fst", size: 88_630)
        ],
        speakerID: 0
    )

    static let cantoneseXiaomaiiwn = VoicePack(
        id: "vits-cantonese-hf-xiaomaiiwn",
        displayName: "粤语",
        subtitle: "标准粤语女声（开源 VITS 模型）",
        repo: "csukuangfj/vits-cantonese-hf-xiaomaiiwn",
        languages: [.cantonese],
        modelFile: "vits-cantonese-hf-xiaomaiiwn.onnx",
        lexiconFile: "lexicon.txt",
        tokensFile: "tokens.txt",
        ruleFsts: ["rule.fst"],
        dictDir: nil,
        files: [
            VoicePackFile(path: "vits-cantonese-hf-xiaomaiiwn.onnx", size: 114_059_955),
            VoicePackFile(path: "lexicon.txt", size: 294_061),
            VoicePackFile(path: "tokens.txt", size: 529),
            VoicePackFile(path: "rule.fst", size: 64_482)
        ],
        speakerID: 0
    )

    static let all: [VoicePack] = [meloZhEn, cantoneseXiaomaiiwn]

    /// 固定文件总大小（不含 dict 目录展开后的文件，下载时动态补充）
    var knownBytes: Int64 { files.reduce(0) { $0 + $1.size } }

    /// 展示用预估大小（dict 目录按经验 ~8MB 估）
    var estimatedBytes: Int64 { knownBytes + (dictDir == nil ? 0 : 8_000_000) }

    var estimatedMB: String {
        let mb = Double(estimatedBytes) / 1_048_576
        return String(format: "%.0f MB", mb)
    }
}
