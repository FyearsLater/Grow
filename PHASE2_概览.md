# Grow · Phase 2 开发说明（看图识字 + 趣味拼图）

> 目标：在不推翻 Phase 1 的前提下，新增「看图识字」与「趣味拼图」两大模块，并按需求文档「先 Demo 后批量」的原则落地。

---

## ⚠️ 首先必读：验证状态

本次开发在 **Windows 沙箱**中完成，**该环境没有 Xcode，无法编译、无法跑模拟器**。

- 所有代码已按现有架构严格对齐编写，并做了人工静态复核
- **但尚未经过一次真实编译**，请在本机 macOS + Xcode 16+ 打开 `Grow.xcodeproj` 后 ⌘B 编译验证
- 若编译报错，大概率是环境/拼写类小问题，把报错贴回来即可快速修

---

## 一、本次完成的内容

### 模块 A：看图识字

| 项目 | 状态 |
|---|---|
| 数字 0–9 | ✅ 全量（数量 → 阿拉伯数字 → 中文数字 → 发音），左右滑动 |
| 声母 | ✅ 23 个（含 y / w） |
| 韵母 | ✅ 24 个 |
| 发音 | ✅ 统一走 AudioManager，播放前自动 stop，不会声音叠加 |
| 认知链路 | ✅ 图片 → 示例词 → 拼音 → 发音 |

### 模块 B：趣味拼图

| 项目 | 状态 |
|---|---|
| 难度 | ✅ 4 块（入门）/ 9 块（进阶）/ 16 块（挑战） |
| Demo 内容 | ✅ 苹果 4 块、熊猫 9 块、向日葵 16 块（按 §35） |
| 逐级解锁 | ✅ 完成前一难度任意一张即解锁下一难度 |
| 拖拽 + 吸附 | ✅ DragGesture，格子即判定范围（儿童容错，不要求像素级） |
| 错误放置 | ✅ 轻柔回位，**无红色提示、无错误音**（§47） |
| 完成反馈 | ✅ 「✨ 拼好了！」+ 柔和音效，**无金币/无通关**（§49） |
| 进度记录 | ✅ 完成状态 + 次数 + 最佳用时，本地持久化 |
| 辅助模式 | ✅ 闲置 6 秒后正确格子轻闪一次（2–3 岁默认开） |
| 自然认知联动 | ✅ 完成后显示中英文 + 三语发音，「认识一下」跳回自然详情 |

### 首页与导航

- 首页改为 **2×2 四入口**：自然世界 / 古诗小世界 / 看图识字 / 趣味拼图（§6/§7）
- 底部导航改为 **首页 / 探索 / 游戏 / 收藏**，设置移到右上角 ⚙️（§8）
- 新增「探索」页：自然世界 / 古诗小世界 / 看图识字（§9）
- 「游戏」页：趣味拼图（§10）
- 设置新增「拼图辅助」开关（§56）

---

## 二、关键设计决策

### 1. 拼图不新增任何图片资源 ⭐

Phase 1 已有 **108 张 720×720 HEIC 图片**（共 5.8 MB），命名规范统一。

拼图**直接复用同一张原图**（`fruit_apple.heic` 等），由 `PuzzleEngine` 在**运行时**计算切片：

- ✅ 完全符合 §84/§85（只存原图、禁止预存切片）
- ✅ 包体积零增长
- ✅ Demo 三张原图（苹果/熊猫/向日葵）实测均为 720×720，可直接切割

### 2. 拼音发音用「呼读音」汉字

系统 TTS **念不出裸拼音符号**——给 zh-CN 念 `b` 会念成英文字母。

因此数据里增加了 `speak_text` 字段，填该拼音的呼读音汉字：

| 拼音 | 呼读音 | 拼音 | 呼读音 |
|---|---|---|---|
| b | 玻 | a | 啊 |
| p | 坡 | o | 喔 |
| m | 摸 | e | 鹅 |
| x | 希 | ao | 熬 |
| zh | 知 | eng | 鞥 |

> 后续若要换成预录音频，只需在 `audio` 字段填文件名，UI 层无需改动。

### 3. PuzzleEngine 与 UI 完全分离

`PuzzleEngine` 负责切格 / 打乱 / 判定 / 吸附 / 完成 / 重置，不引用任何 SwiftUI；
`PuzzleGameView` 只负责手势与呈现（§40/§126）。

---

## 三、纠正了需求文档中的 4 处错误

按 §21「准确性优先于图片数量」执行：

| 位置 | 文档原文 | 问题 | 已修正为 |
|---|---|---|---|
| §二十 | `b → 熊` | 熊的拼音是 xióng，声母是 **x** 不是 b | **x → 熊** |
| — | `k → 贝壳` | 首字「贝」bèi，声母是 b | **k → 口 kǒu** |
| — | `r → 太阳` | 首字「太」tài，声母是 t | **r → 日 rì** |
| — | `eng → 蜜蜂` | 韵母在第二个字 | **eng → 灯 dēng** |

另外：文档 §19 标题写「23 个声母」但只列了 21 个（缺 y、w）。已按通行标准补齐 **y、w** 凑齐 23 个。

---

## 四、新增 / 修改的文件

**新增（14 个）**

```
Grow/Models/LearningModels.swift          数字 / 拼音 / 拼图 数据模型
Grow/Resources/Content/numbers.json       数字 0–9
Grow/Resources/Content/pinyin.json        23 声母 + 24 韵母
Grow/Resources/Content/puzzles.json       拼图（Demo 3 张）
Grow/Core/JSONLoader.swift                统一 JSON 解码（避免重复代码）
Grow/Core/LearningRepository.swift        看图识字数据仓库
Grow/Core/PuzzleRepository.swift          拼图数据仓库
Grow/Core/ProgressManager.swift           进度 + 解锁
Grow/Core/PuzzleEngine.swift              拼图引擎（纯逻辑，无 UI）
Grow/Core/SoundEffects.swift              拼图音效（错误刻意不发声）
Grow/Views/Learning/LearningViews.swift   看图识字首页 / 数字 / 拼音
Grow/Views/Puzzle/PuzzleViews.swift       拼图首页 / 关卡 / 完成页
Grow/Views/Puzzle/PuzzleGameView.swift    拼图游戏（拖拽 + 吸附）
Grow/Views/Explore/ExploreRootView.swift  探索页
```

**修改（5 个）**

```
Grow/Core/Router.swift                    Tab 改为 home/explore/games/favorites
Grow/GrowApp.swift                        底部导航 + 注入新环境对象 + 新 Tab 根视图
Grow/Views/Home/HomeView.swift            首页改 2×2 四入口
Grow/Core/SettingsManager.swift           新增 puzzleAssist
Grow/Views/Settings/SettingsView.swift    新增「拼图辅助」开关
Grow/Views/Components/SharedComponents.swift  新增普通话发音按钮 SpeakButton
```

> 项目已启用 Xcode 文件系统同步（PBXFileSystemSynchronized），**新文件会被自动打包，无需手动改 pbxproj**。

---

## 五、待办 / 已知限制

1. **未编译验证**（Windows 无 Xcode）— 需在本机 ⌘B 验证
2. 拼图内容目前是 Demo 的 3 张，验收通过后需扩充到 36 张（每难度 12 张）
3. `eng`（鞥）、`ong`（嗡）为生僻/近似字，TTS 效果待真机试听，不合适可换预录音频
4. 拼图系统音效用的是 iOS 内置 ID（1104/1057/1025），手感待真机确认后可替换
5. iPad 布局已做最大宽度约束（非简单放大），但拼图区在大屏下的最优尺寸待实测调整
