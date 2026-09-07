# 🌱 Grow — 2-6 岁儿童自然认知与古诗词启蒙 App

一款面向 **2–6 岁儿童** 的 iOS 原生 App（SwiftUI），包含 **自然认知**（水果/蔬菜/动物/植物）与 **古诗词启蒙** 两大板块。

> 设计定位：现代儿童绘本 + 自然博物馆质感。儿童友好，但不幼稚；卡通，但不低幼。

## 当前状态（Phase 1 · Demo 版）

按需求文档「先做 Demo 再扩充」的要求，本阶段已完成完整体验闭环：

| 模块 | 内容 |
|---|---|
| 首页 | 自然世界 / 古诗小世界 双入口 + 最近学习 + 设置 |
| 自然世界 | 4 分类（水果/蔬菜/动物/植物），52 个对象（水果12/蔬菜12/动物16/植物12），实物摄影配图 |
| 卡片浏览 | 大卡片左右滑动（露出下一张边缘）、页点指示、收藏 |
| 自然详情 | 大插画 + 中英文名 + 三语发音 + 折叠简介（按年龄模式显示短/长版） |
| 古诗 | 20 首必读古诗，含分类筛选，古风水墨插图（AI 生成，课本绘本风格） |
| 古诗详情 | 程序化插画 + 原文/拼音切换 + 整首朗读（逐句高亮）+ 单句点读 + 注释 + 儿童理解 |
| 收藏页 | 收藏的自然对象 + 古诗 |
| 设置 | 页面缩放 / 字体 / 按钮（小·标准·大·超大）、年龄模式（2-3 岁 / 4-6 岁）、家长长按 3 秒验证（默认语言 / 朗读速度 0.75x-1.25x / 音效 / 动画开关） |
| 音频 | 三语发音按钮（国语 / 粤语 / English）+ 系统 TTS：zh-CN / zh-HK / en-US，架构支持替换预置音频 |

### Phase 2 新增

| 模块 | 内容 |
|---|---|
| 首页 | 改为 2×2 四入口：自然世界 / 古诗小世界 / 看图识字 / 趣味拼图 |
| 底部导航 | 首页 / 探索 / 游戏 / 收藏（设置移到右上角 ⚙️） |
| 看图识字 · 数字 | 0–9：数量 → 阿拉伯数字 → 中文数字 → 发音，左右滑动 |
| 看图识字 · 拼音 | 23 个声母 + 24 个韵母：图片 → 示例词 → 拼音 → 发音 |
| 趣味拼图 | 4 / 9 / 16 块三档，逐级解锁，拖拽 + 自动吸附，运行时切片 |
| 拼图联动 | 完成后显示中英文 + 三语发音，「认识一下」跳回自然认知详情 |
| 设置 | 新增「拼图辅助」开关（2–3 岁默认开启，4–6 岁默认关闭） |

## 如何运行

```bash
open Grow.xcodeproj          # 用 Xcode 16+ 打开
# 选择 iPhone 模拟器，⌘R 运行
```

或命令行：

```bash
xcodebuild -project Grow.xcodeproj -scheme Grow \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

- 最低支持 iOS 17.0，iPhone / iPad 竖屏
- 无需任何第三方依赖、无需签名即可跑模拟器

**调试启动参数**（直接深跳到某个页面，方便截图/测试）：

```bash
xcrun simctl launch "iPhone 16 Pro" com.dyj.grow --tab=nature --page=deck:fruit
# --tab: home | nature | poem | favorites
# --page: deck:<分类> | item:<自然对象id> | poem:<古诗id>
```

## 如何增加自然对象

编辑 `Grow/Resources/Content/nature.json`，向 `items` 数组追加（无需改任何页面代码）：

```json
{
  "id": "fruit_banana",
  "category": "fruit",              // fruit | vegetable | animal | plant
  "name_zh": "香蕉",
  "name_en": "Banana",
  "description_short": "2-4 岁版本简介（1-3 句）",
  "description_long": "4-6 岁版本简介（3-5 句）",
  "mandarin_audio": null,           // 未来填音频文件名，如 "banana_zh.m4a"
  "cantonese_audio": null,
  "english_audio": null,
  "illustration": "banana",         // 插画标识
  "sort_order": 4
}
```

`illustration` 支持三种格式：

| 格式 | 说明 |
|---|---|
| `img:<名称>` | 加载 `Grow/Resources/Images/<名称>.jpg` 的真实图片（当前 52 个自然对象与 20 首古诗均为此格式） |
| 固定标识（`apple`/`panda`/`sunflower`） | SwiftUI 矢量插画 |
| `emoji:🌿` | 兜底占位 |

**更换图片**：直接替换 `Grow/Resources/Images/` 下的同名 jpg（建议 768×702 或 1:1）；**增加图片**：把新 jpg 放入该目录，JSON 里写 `"illustration": "img:文件名（不带扩展名）"` 即可。

## 如何增加古诗

编辑 `Grow/Resources/Content/poems.json`，向 `poems` 数组追加：

```json
{
  "id": "poem_chunxiao",
  "title": "春晓",
  "author": "孟浩然",
  "dynasty": "唐",
  "categories": ["spring"],         // spring/summer/autumn/winter/night/nature/family/daily
  "illustration": "poem_chunxiao",
  "lines": [
    { "poem_id": "poem_chunxiao", "order": 0, "text": "春眠不觉晓", "pinyin": "chūn mián bù jué xiǎo" }
  ],
  "annotations": [
    { "poem_id": "poem_chunxiao", "target": "闻", "explanation": "听见。" }
  ],
  "kid_summary": "小朋友可以这样理解的一段话",
  "sort_order": 3
}
```

注意：`lines.text` 拼接后用于整首朗读的逐句高亮，`order` 从 0 开始。

## 如何更换图片 / 音频

- **图片**：当前 Demo 全部为程序化矢量插画（零外部资源、天然离线）。替换为真实插画时，在 `IllustrationView` 中将对应 `case` 改为 `Image("资源名")` 即可，内容 JSON 不用动。
- **音频**：`AudioManager` 是唯一的语音出口（UI 不直接碰 AVFoundation）。把 JSON 中 `*_audio` 字段填上 bundle 内音频文件名（推荐 AAC/M4A），并在 `AudioManager.speak(...)` 里优先检查「有音频文件 → AVAudioPlayer 播放，否则回落 TTS」即可完成替换。

## 如何修改默认设置

默认值集中在 `Grow/Core/SettingsManager.swift` 的 `init()`（如 `fontSize` 默认 `.large`、`speechSpeed` 默认 `1.0`、背景音乐默认关闭）。运行时设置持久化在 UserDefaults（key 前缀 `grow.settings.`），删除 App 即恢复默认。

## 项目结构

```
Grow/
├── GrowApp.swift              # 入口 + Tab 结构 + Router
├── Models/Models.swift        # NatureItem / Poem / PoemLine / Annotation
├── Core/
│   ├── AudioManager.swift     # 三语 TTS（可替换为音频文件/云端 TTS）
│   ├── ContentRepository.swift# JSON 内容加载（UI 与数据解耦）
│   ├── SettingsManager.swift  # 设置持久化 + 字号/缩放系数
│   ├── UserLibrary.swift      # 收藏 + 最近学习
│   └── Router.swift           # Tab 路由 + 调试启动参数
├── DesignSystem/Theme.swift   # 统一色彩系统 / 按压反馈 / 卡片样式
├── Views/
│   ├── Home/                  # 首页（双入口卡片 + 最近学习）
│   ├── Nature/                # 分类页 / 卡片滑动 / 详情
│   ├── Poem/                  # 古诗列表 / 沉浸式详情
│   ├── Favorites/             # 收藏页
│   ├── Settings/              # 设置 + 家长长按验证
│   └── Components/            # 程序化插画 / 发音按钮 / 声波指示器
└── Resources/Content/         # nature.json / poems.json（内容数据）
```

## 下一步（Phase 2+）

1. ~~确认 Demo 视觉方向后，扩充至 50+ 自然对象、20 首古诗~~ ✅ 已完成（52 + 20）
2. 录制/接入专业儿童友好配音（国语/粤语/英语），替换系统 TTS
3. 个别水墨插图可按需重生成替换（对应 Images/poem_*.jpg）
4. iPad 大屏布局（非简单放大）
5. 交互测试：快速点击/连续滑动/声音叠加等儿童异常操作场景

---

## 如何添加内容（Phase 2）

所有内容都是**数据驱动**的：加内容只需改 JSON + 放图片/音频，**不需要改 SwiftUI 页面**。

### 图片标准

- **统一 720 × 720 px**、1:1，优先 JPEG / HEIF
- 放在 `Grow/Resources/Images/`，命名用有意义的英文（`apple` / `panda` / `sunflower`），**不要** `img001`、`final2`
- 只有需要透明背景的 UI 元素才用 PNG，内容图片不要全用 PNG
- 项目已启用 Xcode 文件系统同步，新文件会被自动打包，**无需手动改 pbxproj**
- ⚠️ 不要为了「高清」把内容图升级到 1024² / 2048²，这会显著增加包体积

### 添加数字（0–9）

编辑 `Grow/Resources/Content/numbers.json`：

```json
{
  "id": "number_10", "number": 10, "chinese_name": "十",
  "image_items": ["🍎"], "audio": null, "sort_order": 10
}
```

`image_items` 填展示「数量」用的 emoji，UI 会按 `number` 重复展示。

### 添加声母 / 韵母

编辑 `Grow/Resources/Content/pinyin.json`：

```json
{
  "id": "pinyin_initial_b", "type": "initial", "symbol": "b",
  "example_word": "斑马", "example_word_pinyin": "bān mǎ",
  "image": "img:animal_zebra", "speak_text": "玻", "audio": null, "sort_order": 1
}
```

- `type`：`initial` 声母 / `final` 韵母（`tone` 为未来声调预留，暂不使用）
- `image`：复用插画标识，`img:图片名` 或 `emoji:🐚`
- **`speak_text` 必填且要准确**：系统 TTS 念不出裸拼音符号（念 `b` 会变成英文字母），
  因此填该拼音的**呼读音汉字**（b→玻、a→啊、ao→熬、eng→鞥）
- 示例词的**首字**必须真的对应该声母/韵母；宁可只展示符号 + 发音，也不要用错示例

### 添加拼图

编辑 `Grow/Resources/Content/puzzles.json`：

```json
{
  "id": "puzzle_apple_9", "title": "苹果", "category": "水果",
  "image": "img:fruit_apple", "difficulty": "medium",
  "piece_count": 9, "source_nature_item_id": "fruit_apple", "sort_order": 1
}
```

- `difficulty`：`easy` 4 块 / `medium` 9 块 / `hard` 16 块
- **只需要一张 720×720 原图**，切片由 `PuzzleEngine` 在运行时计算；
  **禁止**预先保存 `apple_9_1` 这类切片图
- `source_nature_item_id` 填自然认知条目 id，完成后即可「认识一下」跳回详情

### 修改解锁规则

`Grow/Core/ProgressManager.swift` → `isUnlocked(_:repo:)`。
默认规则：**完成前一难度的任意一张**即解锁下一难度。

### 修改默认设置

`Grow/Core/SettingsManager.swift` → `init()` 中的 fallback 值
（年龄模式、拼图辅助、字号、按钮大小、朗读速度等）。

### 替换音频

- 数字 / 拼音 / 拼图发音统一走 `AudioManager.speak(name:language:key:)`，
  **不要每个页面自己建音频管理器**；播放前会自动 stop，天然避免声音叠加
- 想换成预录音频：把文件放进 Bundle，在模型 `audio` 字段填文件名，
  再让 `AudioManager` 优先播放 `audio`（当前为空时回退系统 TTS）
- 拼图音效在 `Grow/Core/SoundEffects.swift`；**错误放置刻意不发声**

### 新增分类

1. 在 `Grow/Models/` 对应枚举里加 case（`NatureCategory` / `PinyinType` / `PuzzleDifficulty`）
2. 补上 `displayName` / `symbol` 等展示属性
3. 在 JSON 里使用新 case 的 rawValue
4. 页面会自动出现新分类，无需改 View
