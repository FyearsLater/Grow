# Phase 3 当前项目架构审计（Step 1）

> 审计范围：`Grow/` 全部 37 个 Swift 文件（约 5000 行）+ 5 个内容 JSON + 108 张 720×720 HEIC。只审计，不修改。

## 1. 代码结构

```
Grow/
├── GrowApp.swift            App 入口 + RootTabView（自定义液态玻璃风格 TabBar，4 Tab）
├── Core/                    13 个文件
│   ├── AudioManager         AVSpeechSynthesizer 封装（国/粤/英、古诗逐句、播放前 stop 防叠加）✅
│   ├── SettingsManager      UserDefaults 持久化（缩放/字号/按钮/年龄模式/语速/音效/动画/拼图辅助）✅
│   ├── ContentRepository    Bundle JSON 加载（nature/poems），单例 ✅
│   ├── LearningRepository   numbers/pinyin JSON ✅
│   ├── PuzzleRepository     puzzles JSON ✅
│   ├── PuzzleEngine         切割/打乱/判定/吸附/完成，纯逻辑 ✅
│   ├── ProgressManager      拼图进度 + 难度解锁（UserDefaults）✅
│   ├── UserLibrary          收藏 + 最近学习（UserDefaults）✅
│   ├── SoundEffects         SystemSoundID 简单音效 ✅
│   ├── Router               Tab 枚举 + showSettings ✅
│   ├── JSONLoader / DevLog  工具 ✅
├── Models/                  Models.swift（NatureItem/Poem/PoemLine/Annotation）+ LearningModels.swift（NumberItem/PinyinItem/PuzzleItem/PuzzleProgress）
├── DesignSystem/Theme.swift 色板 + PressableButtonStyle + growCard（仅 78 行，单薄）
├── Views/                   Home/Nature/Poem/Learning/Puzzle/Favorites/Settings/Explore/Components
└── Resources/Content/       5 个 JSON（nature 78 / poems 30 / numbers 10 / pinyin 47 / puzzles 3）
```

- 部署目标 iOS 17.0；Xcode 文件系统同步组（新文件自动参与编译）。
- 数据驱动 ✅：View → Repository → Bundle JSON，内容零硬编码。

## 2. 页面清单

首页（2×2 入口+最近学习）、探索页、自然（分类→卡片流→详情）、古诗（列表+筛选→详情）、看图识字（分类→数字/拼音翻页）、拼图（难度→关卡→游戏→完成页）、收藏、设置（含家长验证、开发日志）。

## 3. 主要问题

### P1 重复代码（重构重点）
| 问题 | 位置 |
|---|---|
| **5 套几乎相同的入口卡片** | `HomeEntryCard` / `HomeGridCard` / `ExploreEntryCard` / `LearningCategoryCard` / 拼图难度卡（内联），均为「图标+标题+副标题+渐变底」 |
| **按钮样式内联散落** | PoemDetailView 的播放/切换按钮、PoemRootView 的 categoryChip、PuzzleCompleteView 的 actionButton、NatureDetailView 的展开按钮，各自写 Capsule+fill+shadow |
| **两套玻璃风格** | RootTabView 的毛玻璃实现与 growCard 的实色卡并存，未统一成 DesignSystem |

### P2 高耦合 / 违反分层
- `PoemDetailView` 直接读 `ContentRepository.shared` 单例（绕过环境注入，§22 违规）。
- `UserLibrary.recordVisit` 默认参数取 `.shared`，View 层与单例隐式耦合。
- 资产缓存内嵌在 `Illustrations.swift`（`private static let cache`），无独立 AssetManager，PuzzleGameView 直接调用 `IllustrationView.bundleImage`。

### P3 数据模型缺失（Phase 3 新要求）
- 无统一 `Content` 基础抽象（kind/title/illustration 的公共协议不存在）。
- 无 `ageLevel`、`relatedContentIds` 字段。
- 收藏仅覆盖 nature/poem 两类，ID 集合按类型分裂（未来 number/pinyin 无法直接复用）。

### P4 动画/颜色缺乏系统
- 色板是具体命名（fruit/vegetable…），无语义层（Background/Surface/TextPrimary…）。
- 动画参数散落各页（response 0.28~0.5 不等），无 AnimationSystem；Reduce Motion 仅 PressableButtonStyle 覆盖。

## 4. 可复用部分（保留不动）
AudioManager（含防叠加、逐句高亮）、PuzzleEngine、各 Repository、SettingsManager、ProgressManager、SoundEffects、IllustrationView 三态插画（img:/emoji:/矢量）、PressableButtonStyle 的 Reduce Motion 逻辑、全部内容 JSON 与图片。

## 5. 建议重构（Step 4 执行）
1. 新建 `DesignSystem/`：Tokens（语义色/间距/圆角/阴影/动画）+ Glass 组件库（GlassButton/GlassIconButton/GlassChip/GlassCard/GlassIconButton），部署目标 iOS 17 用 `Material` 实现，接口预留 iOS 26 `glassEffect` 升级点。
2. 统一 5 套入口卡片为 `GlassEntryCard`；内联按钮全部替换为 Glass 组件。
3. `PoemDetailView` 改环境注入；新增 `AssetManager` 抽出图片缓存；`FavoriteManager` 作为统一收藏门面（typealias 映射 UserLibrary，避免破坏性改名）。
4. Models 增加 `ContentItem` 协议 + `AgeLevel` + `relatedContentIDs`（JSON 可选字段，缺省回退派生值）。
5. 现有 10 项功能全部保留，迁移只动「视觉层与接线层」。
