---
name: figma-transcode-svg-rules
description: Reference document for figma-transcode agent — SVG/icon/image handling rules (G3 inline SVG ban, G5 complex image handling)
---

# SVG / 图标 / 图片处理规范

> G3（SVG 内联）和 G5（复杂图片拆散）的解法文档。

---

## G3：SVG / 图标规范

### 规则

**❌ 禁止**：任何形式的 inline SVG（即在 `.vue` 模板中直接写 `<svg>...</svg>`）

**原因**：团队规范要求所有图标通过 `EdsIcon` 组件加载，SVG 文件存放于 `src/assets/icons/`，便于统一管理和缓存。

---

### 情况 1：图标已存在于 `src/assets/icons/`

```vue
<script setup lang="ts">
import ChevronRightIcon from '@/assets/icons/chevron-right.svg'
</script>

<template>
  <EdsIcon :svg="ChevronRightIcon" />
</template>
```

---

### 情况 2：图标为新图标（Figma 设计稿中出现但代码库没有）

生成占位注释，**不内联**：

```vue
<template>
  <!-- TODO: 新图标需手动处理：
       1. 从 Figma 导出 SVG 文件
       2. 保存至 src/assets/icons/icon-name.svg
       3. 在 <script setup> 中添加：import IconName from '@/assets/icons/icon-name.svg'
       4. 将此注释替换为：<EdsIcon :svg="IconName" />
  -->
</template>
```

转码报告中列出所有"新图标待处理"条目，供工程师统一处理。

---

### 情况 3：EdsIcon 用法参考

```vue
<script setup lang="ts">
import { EdsIcon } from 'pas-common/eds-vue'
import StarFilledIcon from '@/assets/icons/star-filled.svg'
import ChevronRightIcon from '@/assets/icons/chevron-right.svg'
</script>

<template>
  <!-- 基本用法 -->
  <EdsIcon :svg="StarFilledIcon" />

  <!-- 指定尺寸 -->
  <EdsIcon :svg="ChevronRightIcon" :size="16" />

  <!-- 指定颜色（通过 CSS） -->
  <EdsIcon :svg="StarFilledIcon" class="icon-primary" />
</template>

<style scoped>
.icon-primary {
  color: #f53f3f;
}
</style>
```

---

## G5：复杂图片 / 插图处理规范

### 规则

**❌ 禁止**：将复杂图片、插图、背景图拆分为多个 `<svg>` 或多个 `<img>` 标签

**原因**：Figma 中的复杂图片节点（illustration、banner、background image）是一个整体，拆散后视觉上会显得混乱，且无法正确还原设计（xueyan 反馈，2026-05-25）。

---

### 处理方式

```vue
<template>
  <!-- ✅ 复杂图片/插图：使用单一 img 标签 -->
  <img
    src="@/assets/images/placeholder.png"
    alt="插图描述"
    class="illustration"
  />
  <!-- TODO: 替换 src 为实际图片路径，从 Figma 导出对应图片资源 -->
</template>

<style scoped>
.illustration {
  width: 200px;  /* 从 Figma design token 中提取 */
  height: 160px;
}
</style>
```

---

### 判断标准

| 节点类型 | 处理方式 |
|---------|---------|
| 简单图标（单色/双色，`<24px`）| `EdsIcon`（见 G3 规范） |
| 复杂图标（多色、渐变、≥24px）| 单一 `EdsIcon` 或 `<img>` |
| 插图 / 背景图 / banner 图片 | 单一 `<img>` |
| 多个独立小图标的集合 | 各自独立用 `EdsIcon`（一图标一 EdsIcon） |
| 将一张完整图切成多块的情况 | ❌ 禁止，合并为单一 `<img>` |

---

---

## G8：Webpack SVG Loader 行为（mmc/mmf 框架项目通用）

> 适用于所有基于 mmc/mmf 框架构建的项目（pas-product、pas-index、pas-display 等）。

### SVG Import → Vue Component（EdsIcon 可用）

以下路径下的 `.svg` 文件被 webpack 转换为 Vue component，可直接传入 `EdsIcon :svg`：

```ts
import closeIcon from "@eds-vue/svg/close.svg";          // EDS 图标库
import myIcon from "src/_shared/assets/svg/my-icon.svg"; // 项目本地 assets

// <EdsIcon :svg="myIcon" />
```

❌ 禁止：`import url from "xxx.svg"` + `<img :src="url">` — SVG 被 webpack 转为 component，不是 URL，`<img>` 无法加载。

### 含 SVGO 优化 — 复杂插图需用 `.nosvgo.svg`

SVGO 会破坏含以下元素的 SVG：`<mask>`、`<filter>`、`<clipPath>`、`<defs>` 中引用的复杂元素。

**解法**：文件名后缀改为 `.nosvgo.svg`，webpack 识别后跳过 SVGO。

| SVG 内容 | 文件后缀 |
|---|---|
| 简单路径、单色图标（无 mask/filter） | `.svg` |
| 含 `<mask>`、`<filter>`、`<clipPath>` | `.nosvgo.svg` |

### EdsIcon currentColor 颜色覆盖

EdsIcon 通过 CSS `currentColor` 控制颜色。stroke-based SVG（如 thumbs-up）需在父级或 EdsIcon 自身设置 `color`：

```vue
<EdsIcon :svg="thumbsUpIcon" class="thumbs-up-icon" />

<style scoped>
.thumbs-up-icon {
  color: #00b26d;
}
</style>
```

---

## 后处理检测逻辑（供 agent Step 4 参考）

**G3 检测**：
- 扫描生成代码中 `<svg` 标签
- 排除 `<EdsIcon` 内部（EdsIcon 内部可能渲染 svg，不算违规）
- 发现直接 `<svg>` → 输出 `❌ 第 {n} 行发现 inline SVG，请替换为 EdsIcon + TODO 注释`

**G5 检测**：
- 统计非 EdsIcon 的独立 `<img>` + `<svg>` 数量
- 若 ≥ 3 个且节点名称/尺寸相近 → 输出 `⚠️ 发现 {n} 个相似图像元素，疑似将复杂图片拆散，建议合并为单一 <img>`
