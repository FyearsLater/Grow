# Phase 5 完成报告

> Grow · 内容扩充 + 趣味游戏中心 + 认知小游戏体系
> 日期：2026-09-07 · 版本 v0.3.0（含 v0.3.1 音效修正）· 本地提交 `514e9cc`（未推送 GitHub）
> 团队：齐活林（主理人）· 高见远（架构）· 寇豆码（工程）· 严过关（QA）

---

## 1. 当前 App 最终结构

```
Grow
├── 🌿 自然世界      4 分类 · 78 对象 · 详情页新增「玩一玩」（拼一拼/找相同/找朋友）
├── 📖 古诗小世界    30 首 · 分类筛选 · 逐句朗读
├── 🔤 看图识字      数字 0–9 · 声母 23 · 韵母 24
└── 🧩 趣味游戏      ← 原「拼图世界」升级（首页第四入口/游戏 Tab 同步换新）
    ├── 🧩 拼图        4/9/16 片（原有功能，迁移至游戏中心）
    ├── 🔗 配对        L1 2组 / L2 3组 / L3 3组·同类别近似
    ├── 👀 找相同      L1 2选项 / L2 3选项 / L3 4选项·同类干扰
    └── 🗂 分类        L1/L2 水果·蔬菜 / L3 动物·植物
```

首页保持 4 个核心入口不变；颜色/形状/排序/找不同按裁决**本期不上、无占位卡**。

## 2. 趣味游戏架构

- 首页 `GameHomeView`：2×2 大卡（Soft 3D 矢量图标，零 Emoji）+「最近探索」横条（空态隐藏）+ 三级难度选择器（2-3 岁档带「推荐」徽标）
- 统一完成页 `GameCompleteOverlay`：成品大图 + 三语发音 + 再玩一次/下一项/认识一下（跳自然详情）
- 设计系统全复用：Theme 色板 / GrowFont / GlassComponents；Glass 只用于操作按钮，游戏主区域实底清晰

## 3. GameEngine 设计

| 组件 | 文件 | 职责 |
|---|---|---|
| GameModels | `Core/Game/GameModels.swift` | GameType / GameDefinition / GameLevel / GameLevelConfig / GameSession / GameResult |
| GameRepository | `Core/Game/GameRepository.swift` | 加载 games.json，natureIds 经 ContentRepository 解析，按年龄档给 defaultLevel |
| GameEngine 协议 + GameContentPicker | `Core/Game/GameEngine.swift` | 洗牌 / 干扰项选取 / 焦点包含（orderedTargets 保证 focus 第一轮必中） |
| MatchingEngine / FindSameEngine / SortingEngine | `Core/Game/` | 三个游戏的对局逻辑（纯逻辑，可与视图解耦） |
| GameFeedbackManager | `Core/Game/GameFeedbackManager.swift` | 正向短语池（找到了！/很棒！/对啦！；再看看～）+ 柔和音 + TTS 跟随默认语言（粤语模式自动粤语） |
| GameResultStore | `Core/Game/GameResultStore.swift` | UserDefaults `grow.game.results`，与拼图旧进度 `grow.puzzle.progress` 完全隔离；含最近探索 |
| GameIcons | `DesignSystem/GameIcons.swift` | GameModule 图标体系（拼块阵/配对卡/放大镜/分类筐/锁，全矢量） |

新增一个游戏 = 一份 games.json 定义 + 一个 Engine + 一个 View，无需再动系统层。

## 4-5. 已完成小游戏与难度

| 游戏 | L1 | L2 | L3 | 反馈 |
|---|---|---|---|---|
| 拼图 | 4 片 | 9 片（解锁） | 16 片（解锁） | 完成双写 GameResultStore，旧解锁进度零改动 |
| 配对 | 2 组 | 3 组 | 3 组（同类别近似：猫狗狼虎狮熊） | 翻对锁定+“找到了！苹果”连读；翻错 0.8s 合上+“再看看～”无错误音 |
| 找相同 | 2 选项 | 3 选项 | 4 选项（同类水果近似干扰） | focus 对象强制为第一轮目标 |
| 分类 | 水果/蔬菜每类 1 件 | 每类 2 件 | 动物/植物每类 3 件 | 宽松吸附（桶宽 60%/桶高 80%）+ 悬停放大 + 放错弹回无惩罚 |

无倒计时 · 无惩罚 · 无金币/积分/排名/宝箱（全代码 grep 复核）。

## 6. 当前内容数量

nature 78 · poems 30 · numbers 10 · pinyin 47 · **puzzles 3 → 15**（easy 6 / medium 5 / hard 4）· games 4 定义 + 9 关卡。

## 7. Content 复用情况

games.json 全部以 nature Content ID 引用（content_ids / category_pairs / focus），经 ContentRepository 解析，**零图片复制**；puzzles.json 扩充的 12 张全部复用已有 720×720 heic（脚本核对 108 张图 non720=0、missing=[]），旧 3 个 puzzle id 原样保留。

## 8. 游戏与自然世界关联

自然详情页「玩一玩」：拼一拼（关联拼图优先已解锁）/ 找相同 / 找朋友（配对直达对局）；`Router.openNatureGame` 跨 Tab 携带内容 ID；DEBUG 深链 `game:findsame:fruit_apple` 可直达指定对象的关卡。

## 9. 学习记录

GameResultStore 记录游玩/完成次数与最近探索；儿童端只展示「最近探索」横条，无复杂数据。

## 10. 性能

- 20 次冷启动深链循环（四游戏各 5 次）：0 失败、无崩溃日志
- 图片按需加载（AssetManager/heic）、游戏退出 onDisappear 停音频（沿用 PuzzleGameView 范式）；未跑 Instruments（模拟器环境无 UI 自动化能力，建议真机补充）

## 11. 已知问题

1. 交互链路（翻卡/拖拽/完成页按钮）为**代码静态审查 + 引擎逻辑核对**，模拟器无辅助功能权限无法自动点按——建议真机手工过一遍（尤以配对翻错合上时序、分类拖拽吸附、完成页三按钮）
2. 粤语指令语听感依赖真机 zh-HK 语音包（无包时按 zh-TW→zh-CN 兜底出声，v0.2.3 修复）
3. 设置页语音选择仍用国旗 emoji，模拟器显示「?」，下版换矢量
4. 模型里遗留无引用的 `*.symbol` emoji 属性，后续清理

## 12. 下一阶段推荐

1. 真机验证（重点：四游戏交互链路 + 粤语听感 + 波形动画）
2. 第二优先级游戏：颜色 / 形状 / 排序（SortingEngine 已有基建）/ 找不同
3. 自然内容扩充至目标量（水果 15-20 / 蔬菜 15 / 动物 20-30 / 植物 15-20），扩充后游戏自动受益（Content ID 复用）
4. 古诗-自然关联（咏鹅→鹅等）与古诗扩充
5. 设置页国旗 emoji 矢量化 + 遗留 symbol 清理
