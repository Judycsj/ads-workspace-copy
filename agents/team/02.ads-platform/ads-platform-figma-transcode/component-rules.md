---
name: figma-transcode-component-rules
description: Reference document for figma-transcode — L1 pas-common components and L3 free layout rules. EDS L2 components are now handled via EDS API Snapshot in visual-spec (fetched from pas-common source during Phase 1) and eds-api-compact.md fallback. Read by Region Codegen Subagents.
---

# 组件优先级规则 / Component Selection Rules

> **三层优先级必须按序执行，不得跳过或倒序。**
> L2 EDS 组件列表已移出本文件——由 Orchestrator 在 Phase 1 从 pas-common 源码直接读取 API，写入 visual-spec 的 `[EDS API Reference]` 节。Region Codegen Subagent 从 visual-spec 读取，无需加载本文件中的 EDS 组件列表。

---

## 三层优先级 / Three-Tier Priority

```
L1: pas-common 业务组件（见下方速查表）
  └── 匹配 → import from 'pas-common/components'

L2: EDS 基础组件（从 visual-spec [EDS API Reference] 节读取 API）
  └── 匹配 → import from 'pas-common/eds-vue'  ← 绝不从 'eds-vue' 直接导入

L3: 自由布局（兜底）
  └── 无对应 → div + scoped CSS，禁止新建非必要自定义组件
```

---

## L1：pas-common 业务组件速查 / pas-common Components

| 组件名 | Import 路径 | 视觉识别特征 |
|---|---|---|
| `BlankModal` | `pas-common/components` | 遮罩层 + **居中**容器 + 标题 + 关闭按钮 + 底部操作区 |
| `CommonCard` | `pas-common/components` | 白色背景 + **1px border** + border-radius ≥ 4px |
| `Drawer` | `pas-common/components` | 右侧滑入面板，宽度 **360–480px**（>480px 改用 Teleport 自定义抽屉） |
| `EllipsisText` | `pas-common/components` | 单行/多行文字 + overflow 截断，有明确最大宽度 |
| `NumberInput` | `pas-common/components` | 数字 input + 货币符号 / 百分号 / 单位后缀 |
| `MetricChart` | `pas-common/components` | 折线图 / 柱状图 / 饼图（ECharts 封装，特殊路径见下） |
| `Avatar` | `pas-common/components` | 圆形图片，尺寸 24–48px |

### 大尺寸抽屉（>480px）的处理

Figma 节点是宽度 > 480px 的右侧滑入面板时，不使用 pas-common `Drawer`，改用自定义模式：

```vue
<Teleport to="body">
  <Transition name="{component-kebab}">
    <div v-if="props.visible" class="{component-kebab}-root">
      <div class="{component-kebab}-mask" @click="handleClose" />
      <aside class="{component-kebab}-panel">
        <!-- content -->
      </aside>
    </div>
  </Transition>
</Teleport>
```

CSS 根元素必须设置 `z-index: 9999`（G10 规则）。

---

## ECharts 图表特殊路径 / ECharts Special Path

图表类节点不走三层查找，直接输出 ECharts option 配置对象：

- 参考：`MetricChart` 组件（`pas-common/components`）已封装 ECharts，优先复用
- 折线 / 柱状 / 饼图 → 提取尺寸、颜色系、图表类型 → 输出 `option` 对象

---

## L3 自由布局规则 / Free Layout Rules

当节点不匹配 L1 或 L2 时：

- 使用 `div` + `scoped CSS`
- 禁止 Tailwind
- 禁止新建非必要的自定义子组件（除非该区域会在多处复用）
- CSS 值优先使用 `project-context.md` 中的变量（$text-primary 等），其次才用 hex

---

## G7：ESLint 规则（mmc/mmf 框架项目）

| 规则 | 正确处理 |
|---|---|
| `transify/no-literal-string` | 文件头加 `<!-- eslint-disable transify/no-literal-string -->` |
| `vue/no-v-model-argument` | 用 `:prop="val" @update:prop="handler"` 替代 `v-model:prop` |
| `vue/no-v-for-template-key` | 避免 `<template v-for>`，改用单元素 `v-for` |
| `max-len` (120) | 长注释另起一行；模板属性各占一行 |
| `import/order` | @eds-vue/svg → pas-common/eds-vue → pas-common/components → src/* |

---

## G10：UI 层级约定 / z-index

| 层级 | z-index |
|---|---|
| mmc 框架固定导航栏 | ~1000 |
| 自定义 Drawer / Modal | **9999**（必须高于导航栏） |
