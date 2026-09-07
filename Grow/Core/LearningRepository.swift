import Foundation

/// 看图识字内容仓库：数字 0–9 + 拼音（声母 / 韵母）
/// UI 只通过本层取数据，不直接读 JSON。
final class LearningRepository: ObservableObject {
    static let shared = LearningRepository()

    @Published private(set) var numbers: [NumberItem] = []
    @Published private(set) var pinyins: [PinyinItem] = []

    private init() {
        numbers = (JSONLoader.load("numbers", as: NumberContentFile.self)?.items ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
        pinyins = (JSONLoader.load("pinyin", as: PinyinContentFile.self)?.items ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// 指定类型的拼音（声母 / 韵母）
    func pinyins(of type: PinyinType) -> [PinyinItem] {
        pinyins.filter { $0.type == type }.sorted { $0.sortOrder < $1.sortOrder }
    }

    func number(_ value: Int) -> NumberItem? {
        numbers.first { $0.number == value }
    }
}
