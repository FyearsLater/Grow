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

    /// 下载专用会话：长超时 + 等待联网，避免大文件下载中途被系统掐断
    private static let dlSession: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 60 * 60
        cfg.waitsForConnectivity = true
        cfg.httpMaximumConnectionsPerHost = 4
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: cfg)
    }()
    /// 单块大小：2MB，失败只需重下当前块
    private static let chunkSize: Int64 = 2 * 1024 * 1024
    private static let maxRetry = 5

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
                // 保留 .part 分片：下次点「继续」从断点续传，不丢弃已下载部分
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
        var req = URLRequest(url: url)
        req.timeoutInterval = 60
        let (data, _) = try await dlSession.data(for: req)
        let entries = try JSONDecoder().decode([HFTreeEntry].self, from: data)
        return entries.filter { $0.type == "file" }
            .map { VoicePackFile(path: $0.path, size: $0.size) }
    }

    /// 分块下载单个文件：支持断点续传（.part 续写）、单块失败自动重试、实时整体进度。
    /// 旧实现用 `URLSession.bytes` 逐字节 await，大文件极易在 70~90% 处被连接重置且无法续传。
    private func downloadFile(_ file: VoicePackFile, pack: VoicePack, baseOffset: Int64, total: Int64) async throws {
        let fm = FileManager.default
        let dest = installDir(pack).appendingPathComponent(file.path)
        try fm.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        let part = URL(fileURLWithPath: dest.path + ".part")
        let url = file.url(repo: pack.repo)

        // 1) 目标文件已存在且大小吻合 → 直接跳过
        let remoteSize = (try? await Self.remoteSize(url)) ?? 0
        let target = remoteSize > 0 ? remoteSize : file.size
        if let attrs = try? fm.attributesOfItem(atPath: dest.path),
           let local = attrs[.size] as? Int64, local > 0,
           (target <= 0 || local == target) {
            report(progress: baseOffset + file.size, total: total, pack: pack)
            return
        }

        // 2) 断点续传起点：以 .part 已写入的字节数为准
        var offset: Int64 = 0
        if let attrs = try? fm.attributesOfItem(atPath: part.path), let s = attrs[.size] as? Int64 {
            offset = max(0, min(s, target > 0 ? target : s))
        }
        if target > 0, offset >= target {
            try? fm.removeItem(at: dest)
            try fm.moveItem(at: part, to: dest)
            report(progress: baseOffset + file.size, total: total, pack: pack)
            return
        }
        if !fm.fileExists(atPath: part.path) { fm.createFile(atPath: part.path, contents: nil) }

        let handle = try FileHandle(forWritingTo: part)
        defer { try? handle.close() }
        if offset > 0 { try handle.seek(toOffset: UInt64(offset)) }

        // 3) 分块下载
        while target <= 0 || offset < target {
            try Task.checkCancellation()
            let end = target > 0 ? min(offset + Self.chunkSize, target) - 1 : offset + Self.chunkSize - 1
            let startAt = offset
            let requested = end - startAt + 1
            var attempt = 0
            var chunk: Data?
            var status = 0
            while attempt < Self.maxRetry {
                do {
                    let r = try await Self.fetchRange(url: url, from: offset, to: end)
                    chunk = r.data
                    status = r.status
                    break
                } catch {
                    attempt += 1
                    if attempt >= Self.maxRetry { throw error }
                    // 退避重试：1s / 2s / 3s / 4s
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
            guard let data = chunk else { throw URLError(.cannotLoadFromNetwork) }

            // 服务器忽略 Range（返回 200 全量）→ 不支持续传，从头写
            if status == 200, offset > 0 {
                try handle.truncateFile(atOffset: 0)
                offset = 0
            }
            try handle.write(contentsOf: data)
            offset += Int64(data.count)

            // 返回块小于请求块 → 已到文件末尾（target 未知时的结束条件）
            if target <= 0, Int64(data.count) < requested { break }

            let done = target > 0 ? Double(offset) / Double(target) * Double(file.size) : Double(offset)
            report(progress: baseOffset + Int64(done), total: total, pack: pack)
        }

        try handle.synchronize()
        try? fm.removeItem(at: dest)
        try fm.moveItem(at: part, to: dest)
        report(progress: baseOffset + file.size, total: total, pack: pack)
    }

    /// 取远端文件大小（HEAD）；失败返回 0，由调用方回退到清单里的 size
    private static func remoteSize(_ url: URL) async throws -> Int64 {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 30
        let (_, resp) = try await dlSession.data(for: req)
        return resp.expectedContentLength
    }

    /// 下载指定字节区间；返回数据与状态码（206 = 支持 Range，200 = 服务器忽略 Range）
    private static func fetchRange(url: URL, from: Int64, to: Int64) async throws -> (data: Data, status: Int) {
        var req = URLRequest(url: url)
        req.setValue("bytes=\(from)-\(to)", forHTTPHeaderField: "Range")
        req.timeoutInterval = 60
        let (data, resp) = try await dlSession.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard code == 206 || code == 200 else { throw URLError(.badServerResponse) }
        return (data, code)
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
