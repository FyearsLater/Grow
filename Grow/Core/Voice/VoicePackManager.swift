import Foundation
import SwiftUI

/// 语音包管理器：负责自然语音库（开源 TTS 模型）的下载、进度、删除与安装状态。
/// 模型文件存放于 Application Support/VoicePacks/<pack.id>/，下载完成后写 .complete 标记。
final class VoicePackManager: ObservableObject {
    static let shared = VoicePackManager()

    enum State: Equatable {
        case notInstalled
        case downloading(progress: Double, downloaded: Int64, total: Int64)
        case installed
        case failed(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.notInstalled, .notInstalled), (.installed, .installed): return true
            case let (.downloading(a, b, c), .downloading(d, e, f)): return a == d && b == e && c == f
            case let (.failed(a), .failed(b)): return a == b
            default: return false
            }
        }
    }

    struct HFTreeEntry: Decodable {
        let type: String
        let path: String
        let size: Int64
    }

    @Published private(set) var states: [String: State] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]
    private static let apiBase = "https://hf-mirror.com"

    var installRoot: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("VoicePacks", isDirectory: true)
    }

    func installDir(_ pack: VoicePack) -> URL {
        installRoot.appendingPathComponent(pack.id, isDirectory: true)
    }

    private var markerPath: String { ".complete" }

    private init() {
        for pack in VoicePack.all {
            states[pack.id] = isInstalled(pack) ? .installed : .notInstalled
        }
    }

    // MARK: - 状态查询

    func isInstalled(_ pack: VoicePack) -> Bool {
        FileManager.default.fileExists(atPath: installDir(pack).appendingPathComponent(markerPath).path)
    }

    func state(_ pack: VoicePack) -> State {
        states[pack.id] ?? .notInstalled
    }

    /// 返回已安装且覆盖指定语言的语音包
    func installedPack(for language: SpeechLanguage) -> VoicePack? {
        VoicePack.all.first { $0.languages.contains(language) && isInstalled($0) }
    }

    // MARK: - 下载

    func download(_ pack: VoicePack) {
        guard tasks[pack.id] == nil, state(pack) != .installed else { return }
        let known = pack.knownBytes
        states[pack.id] = .downloading(progress: 0, downloaded: 0, total: known)

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                try FileManager.default.createDirectory(at: self.installDir(pack), withIntermediateDirectories: true)

                // 1) 展开词典目录（如有；listDir 已过滤文件并转换类型）
                var files = pack.files
                if let dictDir = pack.dictDir {
                    files += try await Self.listDir(repo: pack.repo, dir: dictDir)
                }
                let total = max(files.reduce(0) { $0 + $1.size }, 1)
                var done: Int64 = 0

                // 2) 逐文件下载（带整体进度）
                for file in files {
                    try await self.downloadFile(file, pack: pack, baseOffset: done, total: total)
                    done += file.size
                }

                // 3) 写完成标记
                FileManager.default.createFile(
                    atPath: self.installDir(pack).appendingPathComponent(self.markerPath).path,
                    contents: Data("ok".utf8)
                )
                await MainActor.run {
                    self.states[pack.id] = .installed
                    NaturalTTSPlayer.shared.invalidate()
                }
            } catch is CancellationError {
                self.cleanupPartial(pack)
                await MainActor.run { self.states[pack.id] = .notInstalled }
            } catch {
                self.cleanupPartial(pack)
                await MainActor.run { self.states[pack.id] = .failed(Self.friendly(error)) }
            }
            tasks[pack.id] = nil
        }
        tasks[pack.id] = task
    }

    func cancel(_ pack: VoicePack) {
        tasks[pack.id]?.cancel()
        tasks[pack.id] = nil
    }

    func delete(_ pack: VoicePack) {
        cancel(pack)
        try? FileManager.default.removeItem(at: installDir(pack))
        states[pack.id] = .notInstalled
        NaturalTTSPlayer.shared.invalidate()
    }

    private func cleanupPartial(_ pack: VoicePack) {
        try? FileManager.default.removeItem(at: installDir(pack))
    }

    /// 列出 HF 仓库某目录下的全部文件（经镜像 API）
    private static func listDir(repo: String, dir: String) async throws -> [VoicePackFile] {
        let url = URL(string: "\(apiBase)/api/models/\(repo)/tree/main/\(dir)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let entries = try JSONDecoder().decode([HFTreeEntry].self, from: data)
        return entries.filter { $0.type == "file" }
            .map { VoicePackFile(path: $0.path, size: $0.size) }
    }

    /// 流式下载单个文件，实时更新整体进度
    private func downloadFile(_ file: VoicePackFile, pack: VoicePack, baseOffset: Int64, total: Int64) async throws {
        let url = file.url(repo: pack.repo)
        let (bytes, response) = try await URLSession.shared.bytes(from: url)
        let expected = Int64(response.expectedContentLength)
        var data = Data()
        data.reserveCapacity(expected > 0 ? Int(expected) : Int(file.size))
        var count: Int64 = 0
        var lastReport = Date.distantPast

        for try await byte in bytes {
            try Task.checkCancellation()
            data.append(byte)
            count += 1
            // 限频更新 UI（每 0.2s 一次）
            let now = Date()
            if now.timeIntervalSince(lastReport) > 0.2 {
                lastReport = now
                report(progress: baseOffset + count, total: total, pack: pack)
            }
        }
        try data.write(to: installDir(pack).appendingPathComponent(file.path), options: .atomic)
        report(progress: baseOffset + file.size, total: total, pack: pack)
    }

    private func report(progress downloaded: Int64, total: Int64, pack: VoicePack) {
        let p = min(Double(downloaded) / Double(max(total, 1)), 1)
        DispatchQueue.main.async {
            self.states[pack.id] = .downloading(progress: p, downloaded: downloaded, total: total)
        }
    }

    private static func friendly(_ error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .timedOut:
                return "网络不可用，请检查网络后重试"
            default:
                return "下载失败（\(urlError.code.rawValue)），请重试"
            }
        }
        return "下载失败，请重试"
    }
}

/// 未下载语音包时点朗读的弹窗请求（由根视图展示 alert）
final class VoicePackPromptCenter: ObservableObject {
    static let shared = VoicePackPromptCenter()

    struct Request: Identifiable {
        let id = UUID()
        let language: SpeechLanguage
        let sampleText: String
    }

    @Published var request: Request?

    /// 弹出引导（重复触发时只刷新内容，不叠加弹窗）
    func suggestDownload(language: SpeechLanguage, sampleText: String) {
        DispatchQueue.main.async {
            guard self.request == nil else { return }
            self.request = Request(language: language, sampleText: String(sampleText.prefix(12)))
        }
    }
}
