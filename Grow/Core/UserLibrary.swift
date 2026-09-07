import Combine
import Foundation

/// 收藏与最近学习记录（本地持久化）
final class UserLibrary: ObservableObject {
    static let shared = UserLibrary()

    @Published private(set) var favoriteNatureIDs: Set<String> { didSet { save() } }
    @Published private(set) var favoritePoemIDs: Set<String> { didSet { save() } }
    @Published private(set) var recentNatureIDs: [String] { didSet { save() } }
    @Published private(set) var recentPoemIDs: [String] { didSet { save() } }

    private let defaults = UserDefaults.standard
    private let prefix = "grow.library."

    private init() {
        favoriteNatureIDs = Set(defaults.stringArray(forKey: prefix + "fav.nature") ?? [])
        favoritePoemIDs = Set(defaults.stringArray(forKey: prefix + "fav.poem") ?? [])
        recentNatureIDs = defaults.stringArray(forKey: prefix + "recent.nature") ?? []
        recentPoemIDs = defaults.stringArray(forKey: prefix + "recent.poem") ?? []
    }

    // MARK: - 收藏

    func toggleNatureFavorite(_ id: String) {
        if favoriteNatureIDs.contains(id) { favoriteNatureIDs.remove(id) } else { favoriteNatureIDs.insert(id) }
    }

    func togglePoemFavorite(_ id: String) {
        if favoritePoemIDs.contains(id) { favoritePoemIDs.remove(id) } else { favoritePoemIDs.insert(id) }
    }

    // MARK: - 最近学习（最多 8 条）

    func recordNatureVisit(_ id: String, repo: ContentRepository = .shared) {
        guard repo.natureItems.contains(where: { $0.id == id }) else { return }
        var list = recentNatureIDs.filter { $0 != id }
        list.insert(id, at: 0)
        recentNatureIDs = Array(list.prefix(8))
    }

    func recordPoemVisit(_ id: String, repo: ContentRepository = .shared) {
        guard repo.poems.contains(where: { $0.id == id }) else { return }
        var list = recentPoemIDs.filter { $0 != id }
        list.insert(id, at: 0)
        recentPoemIDs = Array(list.prefix(8))
    }

    // MARK: - Persistence

    private func save() {
        defaults.set(Array(favoriteNatureIDs), forKey: prefix + "fav.nature")
        defaults.set(Array(favoritePoemIDs), forKey: prefix + "fav.poem")
        defaults.set(recentNatureIDs, forKey: prefix + "recent.nature")
        defaults.set(recentPoemIDs, forKey: prefix + "recent.poem")
    }
}
