---
name: figma-transcode-svg-resolve
description: Skill for the figma-transcode Orchestrator — SVG resolution rules. Handles IMAGE-SVG nodes: EDS library matching, project asset reuse check, download, and .nosvgo suffix decision. Replaces the original svg-rules.md with stronger rules (no CSS unicode placeholder when componentId exists).
---

# SVG Resolution Rules

> **When to read this file**: Orchestrator reads this during Phase 4 of fetch-and-cache (SVG Resolution). Region Codegen Subagents do NOT read this — they only read the resolved paths in visual-spec.md.

---

## Decision Tree for IMAGE-SVG Nodes

```
For each IMAGE-SVG node in the Figma data:

Step 1: Read componentId from node data
  → No componentId? → Go to Step 4 (MANUAL-TODO)

Step 2: Look up componentId in metadata.components → get component name
  → Name matches @eds-vue/svg/ pattern (e.g. "2.操作性/16x16/close")?
    → YES → record: import XxxIcon from '@eds-vue/svg/{mapped-name}.svg'
             mark: EDS, no download needed → DONE

Step 3: Not in EDS. Check project-context.md existing_svgs
  → Does any existing filename semantically match the component name?
    → YES (REUSE) → record existing import path, no download → DONE
    → NO (NEW)   → call download_figma_images for this nodeId
                   → download succeeds?
                     → YES → inspect SVG content (see .nosvgo rule below)
                              → save to src/_shared/assets/svg/{name}[.nosvgo].svg
                              → record import path → DONE
                     → NO  → mark MANUAL-TODO (see below), no placeholder → DONE

Step 4 (no componentId): MANUAL-TODO
  → Do NOT generate a CSS unicode placeholder (▲ ↑ etc.)
  → Add a structured TODO comment in the visual spec:
      SVG MANUAL-TODO: node {id} — no componentId, download skipped
      Action required: export SVG manually from Figma and save to src/_shared/assets/svg/
```

---

## .nosvgo Suffix Rule

After downloading an SVG, read its content and check:

| SVG contains | File suffix |
|---|---|
| `<linearGradient>`, `<radialGradient>` in `<defs>` | `.nosvgo.svg` |
| `<clipPath>`, `<mask>`, `<filter>` in `<defs>` | `.nosvgo.svg` |
| Simple paths only, no `<defs>` | `.svg` |

**Why**: webpack's SVGO optimiser strips `<defs>` references, breaking gradient/mask fills. `.nosvgo.svg` tells webpack to skip SVGO for that file.

---

## EDS Icon Name Mapping

Figma component names follow the convention `{category}/{size}/{icon-name}`. Strip category and size, convert to kebab-case for the import path:

| Figma component name | Import path |
|---|---|
| `2.操作性/16x16/close` | `@eds-vue/svg/close.svg` |
| `2.操作性/16x16/question-mark` | `@eds-vue/svg/question-mark.svg` |
| `2.操作性/16x16/arrow-right` | `@eds-vue/svg/arrow-right.svg` |
| `1.说明型/16x16/image` | `@eds-vue/svg/image.svg` |
| `3.状态图标/16x16/notice-circle-s` | `@eds-vue/svg/notice-circle-s.svg` |

If the mapping is unclear, use: `kebab-case(icon-name-after-last-slash)` as a best-effort guess, and note it as "verify path" in the visual spec.

---

## Usage in Generated Code

```vue
<script setup lang="ts">
// EDS icon
import closeIcon from "@eds-vue/svg/close.svg";
// Project asset (normal)
import successCircleIcon from "src/_shared/assets/svg/success-circle.svg";
// Project asset (with gradient — nosvgo)
import arrowUpGreenIcon from "src/_shared/assets/svg/arrow-up-green.nosvgo.svg";

import { EdsIcon } from "pas-common/eds-vue";
</script>

<template>
  <EdsIcon :svg="closeIcon" />
  <EdsIcon :svg="successCircleIcon" />
  <EdsIcon :svg="arrowUpGreenIcon" />
</template>
```

**Forbidden patterns**:
- `<svg>...</svg>` inline in template
- `import url from "xxx.svg"` + `<img :src="url">` (SVG is a Vue component under webpack, not a URL)
- CSS unicode placeholders when componentId is known

---

## ⚠️ G9: nosvgo.svg Files Must Use CSS width/height (NOT :size prop)

**Rule**: For `.nosvgo.svg` files (those with `<linearGradient>`, `<clipPath>`, `<defs>`), the EdsIcon `:size` prop does NOT constrain the rendered dimensions. The SVG expands to fill its flex container.

**Always add a CSS class with explicit `width` and `height`:**

```vue
<!-- WRONG — :size has no effect on nosvgo files -->
<EdsIcon :svg="arrowUpGreenIcon" :size="12" />

<!-- CORRECT — explicit CSS class required -->
<EdsIcon class="arrow-up-icon" :svg="arrowUpGreenIcon" />
```

```scss
.arrow-up-icon {
  width: 16px;   /* from Figma layout dimensions */
  height: 10px;
  flex-shrink: 0;
}
```

**Detection**: Any `EdsIcon` using a `.nosvgo.svg` import without a CSS class that sets `width` and `height` is a violation.

**Simple `.svg` files** (no `<defs>`) may use `:size` prop as normal.

---

## Import Order Rule (ESLint import/order)

```ts
// 1. @eds-vue/svg/* imports
import closeIcon from "@eds-vue/svg/close.svg";
import questionIcon from "@eds-vue/svg/question-mark.svg";

// 2. pas-common/eds-vue component imports
import { EdsIcon, EdsButton } from "pas-common/eds-vue";

// 3. src/* local asset imports
import arrowUpGreenIcon from "src/_shared/assets/svg/arrow-up-green.nosvgo.svg";
```

This order satisfies the `import/order` ESLint rule enforced in mmc/mmf projects.

---

## G5: Complex Image Rule (unchanged)

If a Figma node is a large illustration/banner (not a simple icon):
- `<img src="@/assets/images/placeholder.png" />` with a TODO to replace
- Do NOT split into multiple `<img>` or `<svg>` elements
- Threshold: node is complex if it has mixed fill types (gradient + solid) across many sub-paths, or its dimensions exceed 48×48px with no componentId

---

## G8: Webpack SVG Loader (mmc/mmf projects)

SVG files imported in these projects are converted to Vue components by webpack, not URL strings. Always use them as `:svg` prop on `<EdsIcon>`, never as `src` on `<img>`.
