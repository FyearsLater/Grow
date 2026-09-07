# Phase 3 DesignSystem + Liquid Glass 方案（Step 2）

## 1. 技术选型

- 部署目标 iOS 17.0 → 以 SwiftUI `Material`（`.ultraThinMaterial`）为玻璃基材，叠加统一的高光描边、内阴影、柔和投影，构成项目自定义的 **Liquid Glass 材质**。
- 组件内部集中一处实现；未来升到 iOS 26 时只需把基材替换为系统 `glassEffect()`，调用方零改动。
- 全部组件兼容 Reduce Motion / 动画开关（按压反馈保留变色，去掉缩放）。

## 2. 组件规格

### GlassButton（主按钮，胶囊形）
| 属性 | Primary | Secondary |
|---|---|---|
| 用途 | 开始/播放整首/完成/下一张 | 返回/切换/认识一下/再玩一次 |
| 高度 | 56pt × buttonScale | 50pt × buttonScale |
| 底材 | tint 色玻璃（tint.opacity 0.85 + ultraThinMaterial 叠加） | ultraThinMaterial |
| 文字 | 白色 bold 17 | ink 16 semibold |
| 描边 | 无 | white.opacity(0.5) 1pt 内描边 |
| 阴影 | tint.opacity(0.35) r12 y6 | black.opacity(0.08) r10 y5 |
| 状态 | Normal / Pressed(scale 0.96) / Disabled(opacity 0.5) / Playing(波纹指示) |

### GlassIconButton（圆形图标按钮）
- 直径 52pt（≥44pt 硬性要求，实际命中区=整圆），ultraThinMaterial + 高光描边。
- 用于：播放小按钮、收藏、设置、重玩、返回箭头。

### GlassChip（胶囊选择器）
- 高 44pt，Normal=玻璃底，Selected=tint.opacity(0.25) 玻璃 + tint 文字 + tint 描边。
- 用于：古诗分类筛选、原文/拼音切换、语言按钮。

### GlassCard（玻璃卡片）
- 圆角 28（continuous）、ultraThinMaterial 底、white.opacity(0.4) 顶部高光渐变、
  white.opacity(0.55) 1pt 描边、black.opacity(0.08) r14 y7 阴影。
- `glassCard(radius:tint:)` View 修饰符；tint 用于分类色轻染（opacity ≤0.18，不遮内容）。

### GlassEntryCard（统一入口卡）
- 合并现有 5 套入口卡：竖版（首页 2×2）与横版（探索/识字/难度）两种布局，同一材质。
- 结构：emoji 圆窗 + 标题/副标题/计数 + 箭头；分类色只染在圆窗与描边上。

## 3. 玻璃使用规范（§29 落地）

| 必须使用 | 可使用 | 禁止使用 |
|---|---|---|
| 所有主要按钮、图标按钮、导航工具条、Chip、设置卡片 | 首页入口卡、详情简介卡、最近学习卡 | 内容插画本体、古诗正文区、拼图板与拼图块、大面积背景 |

## 4. 状态与动画（§18 / §19）

- `GrowAnimation`：press=spring(0.28/0.55)、appear=easeOut(0.35)、card=spring(0.35/0.8)、complete=spring(0.5/0.6)。全部经过 `settings.animationOn && !settings.reduceMotion` 门控。
- 按压反馈：scale 0.94→1.0（关闭动画时仅 opacity 0.9）。
- 禁止：巨大缩放、剧烈弹跳、闪光、长时过渡（上限 400ms）。

## 5. 颜色语义层（§20）

```
Theme.background = cream          Theme.surface    = white.opacity(0.7)
Theme.textPrimary = ink           Theme.textSecondary = inkSoft
Theme.accent(tint:)  分类色轻染    Theme.success = vegetable
Theme.destructive = heart         Theme.highlight = white.opacity(0.55)（玻璃描边/高光）
```
旧色名全部保留（零破坏），语义名作为新代码入口。分类色（果橙/蔬绿/动蓝/植紫/诗墨/诗棕）保留为 tint 源。

## 6. 尺寸与间距 Token

Spacing: xs4 / s8 / m16 / l20 / xl24；Radius: card28 / sheet32 / chip22 / icon26；
最小命中区 44pt，主要操作 ≥52pt。
