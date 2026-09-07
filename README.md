# 🌱 Grow — 2–6 岁儿童探索式启蒙 App

一款面向 **2–6 岁儿童**（当前主打 **2–3 岁**）的 iOS 原生 App（SwiftUI，零第三方依赖）。
产品定位不是「早教机」，而是一个属于孩子的、轻松现代的**数字探索空间**：
自然认知 · 古诗启蒙 · 看图识字 · 趣味拼图。

> 设计语言：**iOS 26 Liquid Glass** + 柔和低饱和色板 + 统一 Soft 3D 图标系统。
> 现代、干净、呼吸感；儿童友好，但不幼稚。

**当前版本：v0.2.2**（开发日志见 App 内「设置 → 开发日志」）

---

## ✨ 功能总览

| 模块 | 内容 |
|---|---|
| 首页 | Liquid Glass 统一卡片体系，四入口：自然世界 / 古诗小世界 / 看图识字 / 拼图世界；最近看过（点击直达详情）；右上角玻璃设置按钮 |
| 自然世界 | 4 分类（水果/蔬菜/动物/植物）共 **78 个对象**，720×720 实物摄影配图（HEIF）；整页翻页卡片流 |
| 自然详情 | 大图 + 中英文名 + 三语发音（国/粤/En）+ 按年龄模式折叠简介 |
| 古诗小世界 | **30 首古诗**（含江河/湖泊/山川/节日/历史等 9 分类），古风水墨插图；原文/拼音切换、逐句朗读、单句点读、注释、儿童理解 |
| 看图识字 | 数字 0–9 + 拼音 **23 声母 + 24 韵母**（47 张卡片）：图片放大 + 字母/例词左右并排 |
| 拼图世界 | 4/9/16 块三档逐级解锁，`PuzzleEngine` 运行时切割原图；完成后「认识一下」跳回自然详情 |
| 底部导航 | 首页 / 探索 / 游戏 / 收藏；iOS 26+ 原生 TabView 自动获得系统 Liquid Glass 标签条，iOS 17/18 回退自定义玻璃胶囊 |
| 收藏 | 自然对象 + 古诗统一收藏 |
| 设置 | 年龄模式（2-3 / 4-6 岁）、页面缩放 / 字号 / 按钮（小·标准·大·超大）、拼图辅助、朗读语言与音色（小男孩/小女孩/男大/女大）、停顿时长、动画开关、**开发日志** |

### 音频能力

- 系统粒子 TTS：`AVSpeechSynthesizer`，国语回退链 zh-CN → zh-TW → zh-HK（真机缺语音包也能出声）
- 粤语 zh-HK、英语 en-US；古诗逐句队列朗读，句间停顿可调（短/适中/长）
- 四档朗读音色（音高 + 性别偏好），作用于全部朗读场景
- 拼图音效 `SoundEffects`；错误放置刻意不发声

---

## 🎨 设计系统（DesignSystem）

所有 UI 统一调用设计系统组件，**禁止页面自造颜色/字体/玻璃效果**。

| 文件 | 内容 |
|---|---|
| `DesignSystem/Theme.swift` | 色彩系统：米白底色、语义色（`textPrimary`/`textSecondary`…）、模块柔和色板（`softGreen/softSand/softBlue/softLilac` + `deep*`）、首页背景渐变；**GrowFont 四级字体**（Title / Heading / Body / Subtitle / Caption，rounded 中轻字重，跟随设置档位缩放）；`PressableButtonStyle` 按压反馈 |
| `DesignSystem/Tokens.swift` | 间距 `GrowSpacing`、圆角 `GrowRadius`、动画 `GrowAnimation`（全部经 Reduce Motion / 动画开关门控） |
| `DesignSystem/GlassComponents.swift` | 玻璃组件唯一入口：`glassSurface` / `glassCard`（iOS 26 走系统 `glassEffect`，iOS 17/18 回退 `ultraThinMaterial` + 高光描边）、`GlassButton` / `GlassIconButton` / `GlassChip` / `GlassEntryCard`（module 驱动）/ `GlassPageHeader` |
| `DesignSystem/ModuleIdentity.swift` | 四模块统一视觉符号：`GrowModule` 枚举（标题/副标题/主题色/深色）+ `ModuleIconView` Soft 3D 矢量图标（嫩芽 / 诗卷 / 汉字卡 / 双拼图），不使用 Emoji |

### 设计原则

1. Glass 是材质不是内容：卡片轻染模块色，图标 → 标题 → 一句话说明的现代层级
2. 中文标题圆润中轻字重，标题与说明层级分明；儿童 App ≠ 粗黑体
3. 背景极轻渐变 + 模糊光斑，营造空间感，不抢内容
4. 动画短、轻、自然；开启「减弱动态效果」自动降级
5. 固定浅色外观（`preferredColorScheme(.light)`）保证玻璃质感一致

---

## 🚀 如何运行

```bash
open Grow.xcodeproj   # 用 Xcode 26+ 打开（Liquid Glass 需 iOS 26 SDK）
# 选择 iPhone 模拟器，⌘R 运行
```

或命令行：

```bash
xcodebuild -project Grow.xcodeproj -scheme Grow \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

- 最低支持 **iOS 17.0**，iPhone / iPad 竖屏；无第三方依赖
- 无需签名即可跑模拟器；真机安装用未签名 IPA（xcodebuild archive → Payload → zip）
- 开发环境：Xcode 26.3 (17C529) + iOS 26.3.1 SDK

**调试启动参数**（直接深跳到某个页面，方便截图/测试）：

```bash
xcrun simctl launch "iPhone 17 Pro" com.dyj.grow --tab=explore --page=deck:fruit
# --tab: home | explore | games | favorites
# --page: deck:<分类> | item:<自然对象id> | poem:<古诗id> | pinyin:<initial|final> | numbers | settings
```

---

## 📁 项目结构

```
Grow/
├── GrowApp.swift                 # 入口 + RootTabView（iOS26 原生 TabView / 老系统玻璃胶囊）+ 各 Tab 栈
├── Models/
│   ├── Models.swift              # NatureItem / Poem（含容错解码）/ PoemCategory
│   ├── LearningModels.swift      # ContentItem 统一协议 / NumberItem / PinyinItem / PuzzleItem
│   └── Content.swift
├── Core/
│   ├── AudioManager.swift        # 唯一语音出口：TTS / 音色 / 回退链 / 逐句朗读
│   ├── ContentRepository.swift   # JSON 内容加载（UI 与数据解耦）
│   ├── LearningRepository.swift  # 数字 / 拼音仓库
│   ├── PuzzleRepository.swift    # 拼图仓库
│   ├── PuzzleEngine.swift        # 运行时图片切片
│   ├── ProgressManager.swift     # 拼图解锁进度
│   ├── SettingsManager.swift     # 设置持久化 + 字号/缩放/按钮系数
│   ├── UserLibrary.swift         # 收藏 + 最近看过
│   ├── Router.swift              # Tab 路由 + 深链启动参数
│   ├── DevLog.swift              # 开发日志数据（版本号唯一真源）
│   ├── AssetManager.swift        # 图片资产加载（HEIF 优先）
│   └── SoundEffects.swift        # 拼图音效
├── DesignSystem/
│   ├── Theme.swift               # 色彩 / GrowFont 字体 / 按压反馈
│   ├── Tokens.swift              # 间距 / 圆角 / 动画
│   ├── GlassComponents.swift     # Liquid Glass 组件库（唯一玻璃入口）
│   └── ModuleIdentity.swift      # 四模块 Soft 3D 图标 + GrowModule
├── Views/
│   ├── Home/                     # 首页（玻璃卡片 + 最近看过 + 柔光背景）
│   ├── Explore/                  # 探索 Tab
│   ├── Nature/                   # 自然分类 / 整页翻页卡组 / 详情
│   ├── Poem/                     # 古诗列表 / 沉浸式详情
│   ├── Learning/                 # 看图识字（数字 / 拼音）
│   ├── Puzzle/                   # 拼图首页 / 游戏
│   ├── Favorites/                # 收藏
│   ├── Settings/                 # 设置 + 开发日志
│   └── Components/               # 插画 / 共享组件
└── Resources/
    ├── Content/                  # nature / poems / numbers / pinyin / puzzles JSON
    └── Images/                   # 108 张 720×720 HEIF 配图
```

---

## 📝 内容扩充指南（数据驱动，加内容不改页面）

所有内容 JSON 驱动：**改 JSON + 放图即生效**（Xcode 文件系统同步组，新文件自动打包，无需改 pbxproj）。

### 图片标准

- **720 × 720 px**、1:1，优先 HEIF（`magick in.jpg -resize 720x720^ -gravity center -extent 720x720 -format heic out.heic`）
- 放 `Grow/Resources/Images/`，命名用有意义的英文；不要为了「高清」升到 1024²/2048²
- `illustration` 格式：`img:<名称>`（实物图）/ 固定标识（apple/panda 等矢量插画）/ `emoji:🌿`（兜底）

### 各内容文件

| 文件 | 追加方式 |
|---|---|
| `nature.json` | `items[]`：id / category（fruit·vegetable·animal·plant）/ name_zh / name_en / 双语简介 / illustration / sort_order |
| `poems.json` | `poems[]`：lines.text 拼接用于逐句高亮（order 从 0 起）；分类 rawValue 必须在 `PoemCategory` 枚举中已有（未知分类会被容错跳过） |
| `numbers.json` | `image_items` 填展示数量用的 emoji，UI 按 `number` 重复 |
| `pinyin.json` | **`speak_text` 必填呼读音汉字**（b→玻、a→啊）；示例词首字必须真对应 |
| `puzzles.json` | 只需一张 720×720 原图，切片运行时计算，**禁止预存切片**；`source_nature_item_id` 联动自然详情 |

### 修改规则与默认值

- 拼图解锁规则：`ProgressManager.isUnlocked`（完成前一难度任意一张解锁下一档）
- 默认设置：`SettingsManager.init()`（持久化 key 前缀 `grow.settings.`，删 App 恢复默认）
- 替换预录音频：文件入 Bundle → JSON `audio` 字段填文件名 → `AudioManager` 优先播放（当前为空回退 TTS）；**不要绕过 AudioManager 自建音频管理器**

---

## 🧭 开发约定（踩坑沉淀）

1. **枚举先行**：给 JSON 加新分类前，先在 `Models` 补枚举 case，否则整文件解码失败（已对古诗分类做容错跳过）
2. **扩充内容后必须模拟器启动对应页面截图验证**
3. **版本号以 `DevLog.swift` 为唯一真源**：更新后工程 `MARKETING_VERSION` 同步 DevLog 版本
4. **GitHub 推送等用户指令**，不自动推送
5. iOS 26 `glassEffect` 的 tint 渲染偏重，柔和效果传 `color.opacity()` 压低
6. `AnyShape` 描边用 `.stroke`（无 `strokeBorder`）；裸形状加 `.shadow` 前必须先有 fill（否则黑色前景）
7. iOS 26.3.1 模拟器缺 emoji 字体显示「？」，真机不受影响

## 🗺️ Roadmap

1. ~~自然 52 + 古诗 20~~ ✅ → **78 + 30**
2. ~~看图识字 + 拼图（Phase 2）~~ ✅
3. ~~Liquid Glass 设计语言 + 首页重设计（Phase 3 / v0.2.2）~~ ✅
4. 录制/接入专业儿童配音，替换系统 TTS
5. 更多自然对象、更多古诗、更多拼图源
6. iPad 大屏布局（非简单放大）
7. 暂不新增模块（数学/创意/故事/音乐/英语留待后续规划）
