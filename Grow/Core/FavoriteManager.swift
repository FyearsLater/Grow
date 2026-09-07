import Combine
import Foundation

/// 统一收藏门面（§23 FavoriteManager）
///
/// 收藏与最近学习的实际实现位于 `UserLibrary`（收藏 + 最近浏览记录，UserDefaults 持久化）。
/// 为避免破坏性改名影响现有视图，这里以类型别名建立统一命名入口：
/// 新代码引用 `FavoriteManager.shared` 即可获得统一收藏能力；
/// 未来扩展 number / pinyin 收藏时在 UserLibrary 内增量扩展即可。
typealias FavoriteManager = UserLibrary
