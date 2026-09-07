import Foundation

/// 内容仓库：负责从本地 JSON 加载内容，UI 不直接接触数据文件。
/// 未来扩展（云端更新、数据库）只需替换本层实现。
final class ContentRepository: ObservableObject {
    static let shared = ContentRepository()

    @Published private(set) var natureItems: [NatureItem] = []
    @Published private(set) var poems: [Poem] = []

    private init() {
        loadContent()
    }

    private func loadContent() {
        natureItems = Self.load("nature", as: NatureContentFile.self)?.items.sorted { $0.sortOrder < $1.sortOrder } ?? []
        poems = Self.load("poems", as: PoemContentFile.self)?.poems.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    private static func load<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            #if DEBUG
            print("[ContentRepository] 未找到内容文件: \(name).json")
            #endif
            return nil
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[ContentRepository] 解析 \(name).json 失败: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - 查询

    func items(in category: NatureCategory) -> [NatureItem] {
        natureItems.filter { $0.category == category }
    }

    func poem(id: String) -> Poem? {
        poems.first { $0.id == id }
    }
}
