import AudioToolbox
import Foundation

/// 拼图音效（§65）：抓起 pop / 正确 snap / 完成 chime。
/// 错误放置**不播放任何声音**（§47：禁止刺耳错误音）。
///
/// 说明：这里使用 iOS 系统内置短音效，零资源体积。
/// 若后续需要更贴合的配音，可在 Resources 放入音频文件后改为 AVAudioPlayer 播放，
/// 调用方（PuzzleGameView）无需改动。
enum PuzzleSound {
    case pick
    case place
    case complete

    func play() {
        AudioServicesPlaySystemSound(soundID)
    }

    private var soundID: SystemSoundID {
        switch self {
        case .pick:     return 1104   // 轻微
        case .place:    return 1057   // 清脆短促
        case .complete: return 1025   // 柔和提示
        }
    }
}

// MARK: - 游戏音效（Phase 5：配对/找相同/分类共用，与拼图同一批柔和系统短音）
//
// 错误操作**无任何音效**（§47 / §跨文件约定 4），只有 GameFeedbackManager 的语音引导。

enum GameSound {
    case pick       // 抓起 / 翻面
    case correct    // 正确
    case complete   // 整局完成

    func play() {
        AudioServicesPlaySystemSound(soundID)
    }

    private var soundID: SystemSoundID {
        switch self {
        case .pick:     return 1104   // 轻微
        case .correct:  return 1057   // 清脆短促
        case .complete: return 1025   // 柔和提示
        }
    }
}
