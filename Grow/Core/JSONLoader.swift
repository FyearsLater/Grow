import Foundation

/// 统一的 Bundle JSON 加载工具，避免各 Repository 重复实现解码逻辑。
enum JSONLoader {
    static func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            #if DEBUG
            print("[JSONLoader] 未找到内容文件: \(name).json")
            #endif
            return nil
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[JSONLoader] 解析 \(name).json 失败: \(error)")
            #endif
            return nil
        }
    }
}
