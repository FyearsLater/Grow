# Phase 3 最终架构（Step 3）

```
Grow/
├── GrowApp.swift                 入口 + RootTabView（Glass TabBar）
├── DesignSystem/
│   ├── Theme.swift               语义色 + 色板 + 字号缩放（扩展）
│   ├── Tokens.swift              [新] Spacing / Radius / Shadow / GrowAnimation
│   └── GlassComponents.swift     [新] GlassButton / GlassIconButton / GlassChip / GlassCard / GlassEntryCard
├── Core/
│   ├── AudioManager.swift        音频（不变）
│   ├── AssetManager.swift        [新] 图片/音频资产缓存门面（NSCache + LRU 语义 + bundle 加载）
│   ├── ContentRepository.swift   数据源（不变）
│   ├── LearningRepository.swift  数据源（不变）
│   ├── PuzzleRepository.swift    数据源（不变）
│   ├── FavoriteManager.swift     [新] 统一收藏门面（协议 + UserLibrary 适配，零破坏）
│   ├── ProgressManager.swift     拼图进度（不变）
│   ├── SettingsManager.swift     设置（不变）
│   ├── PuzzleEngine.swift        拼图逻辑（不变）
│   ├── SoundEffects.swift        音效（不变）
│   ├── Router.swift              导航（不变）
│   └── JSONLoader.swift / DevLog.swift
├── Models/
│   ├── Content.swift             [新] ContentKind / AgeLevel / ContentItem 统一协议
│   ├── Models.swift              NatureItem/Poem（实现 ContentItem）
│   └── LearningModels.swift      NumberItem/PinyinItem/PuzzleItem（实现 ContentItem）
├── Views/                        全部页面（视觉层迁移到 Glass，业务不动）
│   ├── Home / Explore / Nature / Poem / Learning / Puzzle / Favorites / Settings / Components
└── Resources/
    ├── Content/                  5 个 JSON（age_level / related_content_ids 为可选字段，缺省回退）
    └── Images/                   108 张 720×720 HEIC（不增尺寸）
```

## 分层规则（§22）

```
View ──@EnvironmentObject──> Repository/Manager ──> Bundle JSON / UserDefaults
```
- View 禁止单例直读（本轮修复 PoemDetailView）。
- 收藏统一走 `FavoriteManager`；资产统一走 `AssetManager`；进度走 `ProgressManager`。

## Content 统一模型（§21 / §24 / §25）

```swift
enum ContentKind { case nature, poem, number, pinyin, puzzle }
enum AgeLevel { case age23, age34, age45, age56 }          // JSON 可选 age_level，缺省 .age34
protocol ContentItem: Identifiable {
    var id: String { get }
    var kind: ContentKind { get }
    var displayTitle: String { get }
    var illustrationID: String { get }
    var ageLevel: AgeLevel { get }
    var relatedContentIDs: [String] { get }                 // JSON 可选，缺省由 Repository 派生
}
```
- NatureItem/Poem/NumberItem/PinyinItem/PuzzleItem 全部实现协议。
- relatedContentIDs 派生规则：拼图→sourceNatureItemId；自然对象→同名拼图（Repository 反查）；数字/拼音→自身。

## AgeLevel（§24）

数据结构就绪，不做推荐算法；设置页现有 AgeMode（2–3/4–6）继续生效，AgeLevel 供未来 Phase 7 细分。

## 性能（§27，本轮落地项）

- AssetManager：NSCache 统一图片缓存（countLimit 120），页面离开靠 SwiftUI 释放 + cache 淘汰。
- 拼图：运行时切片仅内存缓存，离开页面释放（已有），重置时清 cropCache。
- 启动：仅加载 JSON 索引，不预载位图（已有 Lazy 加载）。

## 迁移保证（§32）

功能不减少清单：自然世界 / 古诗 / 识字 / 数字 / 拼音 / 拼图 / 收藏 / 最近学习 / 设置 / 音频 —— 全部保留，迁移仅替换视觉层。
