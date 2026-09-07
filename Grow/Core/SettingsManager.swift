import Combine
import Foundation
import SwiftUI

/// 页面缩放 / 字号 / 按钮档位
enum SizeLevel: String, Codable, CaseIterable, Identifiable {
    case small, standard, large, extraLarge

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "小"
        case .standard: return "标准"
        case .large: return "大"
        case .extraLarge: return "超大"
        }
    }
}

/// 年龄模式
enum AgeMode: String, Codable, CaseIterable, Identifiable {
    case toddler   // 2-3 岁
    case preschool // 4-6 岁

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .toddler: return "2–3 岁"
        case .preschool: return "4–6 岁"
        }
    }
}

/// 全局设置：持久化到 UserDefaults。
/// UI 通过 EnvironmentObject 读取，统一驱动字号、缩放、按钮大小。
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var pageScale: SizeLevel { didSet { persist() } }
    @Published var fontSize: SizeLevel { didSet { persist() } }
    @Published var buttonSize: SizeLevel { didSet { persist() } }
    @Published var defaultLanguage: SpeechLanguage { didSet { persist() } }
    /// 古诗词朗读语言（可独立于自然认知默认语言）
    @Published var poemLanguage: SpeechLanguage { didSet { persist() } }
    /// 古诗词朗读音色角色
    @Published var poemVoice: PoemVoiceRole { didSet { persist() } }
    /// 古诗词句间停顿（秒）
    @Published var poemPause: Double { didSet { persist() } }
    /// 朗读速度档位：0.75 / 1.0 / 1.25
    @Published var speechSpeed: Double { didSet { persist() } }
    @Published var buttonSoundOn: Bool { didSet { persist() } }
    @Published var animationOn: Bool { didSet { persist() } }
    @Published var reduceMotion: Bool { didSet { persist() } }
    @Published var ageMode: AgeMode { didSet { persist() } }

    private let defaults = UserDefaults.standard
    private static let prefix = "grow.settings."

    private init() {
        let defaults = UserDefaults.standard
        pageScale = Self.decode(SizeLevel.self, key: "pageScale", fallback: .large)
        fontSize = Self.decode(SizeLevel.self, key: "fontSize", fallback: .large)
        buttonSize = Self.decode(SizeLevel.self, key: "buttonSize", fallback: .large)
        defaultLanguage = Self.decode(SpeechLanguage.self, key: "defaultLanguage", fallback: .mandarin)
        poemLanguage = Self.decode(SpeechLanguage.self, key: "poemLanguage", fallback: .mandarin)
        poemVoice = Self.decode(PoemVoiceRole.self, key: "poemVoice", fallback: .womanAdult)
        poemPause = defaults.object(forKey: Self.prefix + "poemPause") as? Double ?? 0.55
        speechSpeed = defaults.object(forKey: Self.prefix + "speechSpeed") as? Double ?? 1.0
        buttonSoundOn = defaults.object(forKey: Self.prefix + "buttonSoundOn") as? Bool ?? true
        animationOn = defaults.object(forKey: Self.prefix + "animationOn") as? Bool ?? true
        reduceMotion = defaults.object(forKey: Self.prefix + "reduceMotion") as? Bool ?? false
        ageMode = Self.decode(AgeMode.self, key: "ageMode", fallback: .preschool)
    }

    // MARK: - 派生系数（供 Theme 使用）

    /// 页面缩放系数
    var pageScaleFactor: CGFloat {
        switch pageScale {
        case .small: return 0.9
        case .standard: return 1.0
        case .large: return 1.1
        case .extraLarge: return 1.2
        }
    }

    var fontScaleFactor: CGFloat {
        switch fontSize {
        case .small: return 0.9
        case .standard: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }

    var buttonScaleFactor: CGFloat {
        switch buttonSize {
        case .small: return 1.0
        case .standard: return 1.1
        case .large: return 1.2
        case .extraLarge: return 1.35
        }
    }

    /// 当前年龄模式下的简介字段
    var prefersLongDescription: Bool { ageMode == .preschool }

    // MARK: - Persistence

    private static func decode<T: RawRepresentable>(_ type: T.Type, key: String, fallback: T) -> T where T.RawValue == String {
        guard let raw = UserDefaults.standard.string(forKey: prefix + key), let v = T(rawValue: raw) else { return fallback }
        return v
    }

    private func persist() {
        let p = Self.prefix
        defaults.set(pageScale.rawValue, forKey: p + "pageScale")
        defaults.set(fontSize.rawValue, forKey: p + "fontSize")
        defaults.set(buttonSize.rawValue, forKey: p + "buttonSize")
        defaults.set(defaultLanguage.rawValue, forKey: p + "defaultLanguage")
        defaults.set(poemLanguage.rawValue, forKey: p + "poemLanguage")
        defaults.set(poemVoice.rawValue, forKey: p + "poemVoice")
        defaults.set(poemPause, forKey: p + "poemPause")
        defaults.set(speechSpeed, forKey: p + "speechSpeed")
        defaults.set(buttonSoundOn, forKey: p + "buttonSoundOn")
        defaults.set(animationOn, forKey: p + "animationOn")
        defaults.set(reduceMotion, forKey: p + "reduceMotion")
        defaults.set(ageMode.rawValue, forKey: p + "ageMode")
    }

    /// 统一在值变化后调用
    func saveNow() { persist() }
}
