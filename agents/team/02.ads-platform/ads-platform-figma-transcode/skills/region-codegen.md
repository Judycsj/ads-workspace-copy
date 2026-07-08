---
name: figma-transcode-region-codegen
description: Skill for a Region Codegen Subagent. Receives a visual-spec-regionX.md and generates a self-contained Vue 3 SFC fragment for that region. Reads EDS component API directly from the visual spec (pre-extracted by Orchestrator). Does NOT fetch Figma data or scan the project.
---

# Region Code Generation

> **Context isolation rule**: This subagent starts with a clean context window. It reads ONLY:
> 1. The visual spec for its assigned region (`visual-spec-regionX.md`)
> 2. This skill file (`region-codegen.md`)
> 3. `agents/team/02.ads-platform/ads-platform-figma-transcode/component-rules.md` (L1 + L3 rules)
>
> It does NOT load svg-rules.md, fetch-and-cache.md, or any other region's spec.

---

## Input Contract

The Orchestrator provides:
- `visual_spec_path`: path to `visual-spec-regionX.md`
- `project_context_path`: path to `project-context.md` (contains Working Patterns)
- `output_path`: path to write `fragment-regionX.vue`
- `handoff_path`: path to write `codegen-handoff-X.md`

Read both the visual spec and project-context.md **before writing any code**.

**Priority for EDS component usage:**
1. `project-context.md ## Working Patterns` — copy the exact wrapper/CSS from real working project code
2. `visual-spec ## EDS API Reference` — API snapshot extracted from source
3. `eds-api-compact.md` — fallback reference only

This order prevents framework-level rendering bugs (e.g. EdsTabs invisible on gradient, EdsTableColumn header rendering as "#Name") that API documentation alone cannot capture.

---

## Step 1 — Read and Parse Visual Spec

From the visual spec, extract:

1. **Node Accounting list** — all nodes that must appear in generated code
2. **Structural Patterns** — EDS components to use (with API snapshots already in spec)
3. **SVG Assets** — import paths (already resolved: EDS / REUSE / NEW)
4. **Text Color Runs** — multi-color text segments requiring separate `<span>`
5. **Layout Tokens** — flex-direction, gap, padding for each container
6. **CSS Variables** — project-specific variables to use instead of hex literals

---

## Step 2 — Component Priority (from component-rules.md)

```
L1 (pas-common): Check visual spec Structural Patterns first
  → Drawer pattern (1000px+ wide panel, Teleport to body) → NOT pas-common Drawer (too narrow)
                                                           → use custom Teleport + Transition
  → BlankModal (centred + mask + title + footer) → pas-common BlankModal
  → CommonCard (white bg + 1px border + border-radius) → pas-common CommonCard
  → EllipsisText, NumberInput, MetricChart, Avatar → pas-common

L2 (EDS from pas-common/eds-vue): Use EDS API snapshot from visual spec
  → EdsTabs (tab bar with active state underline)
  → EdsTable (thead + tbody data rows)
  → EdsButton (text + bg color + height 28-40px + onClick)
  → EdsIcon (any SVG icon — NEVER inline svg)
  → EdsTooltip (hover hint, wrap around EdsIcon question-mark)
  → Other EDS components per API snapshot in visual spec

L3 (free layout): div + scoped CSS for everything else
```

---

## Step 3 — Code Generation Rules

### 3A — Multi-color Text Runs

When visual spec lists Text Color Runs for a node, generate multiple `<span>` elements, NOT a single string:

```vue
<!-- WRONG: single string loses color split -->
<span class="effect">GMV+10%, Order +15%</span>

<!-- CORRECT: separate spans per color run -->
<span class="effect-label">GMV</span>
<span class="effect-value">+10%</span>
<span class="effect-label">, Order</span>
<span class="effect-value">+15%</span>
```

CSS for each span must use the fill color from the visual spec (or the project CSS variable if available).

### 3B — Absolute-Positioned Nodes

Visual spec marks absolute nodes with `**position: absolute**`. These MUST appear in the generated code even if they are decorative:

```vue
<!-- Decorative illustration: absolute positioned in top-right of parent -->
<img
  class="region-decoration"
  src="@/assets/images/placeholder.png"
  alt=""
/>
<!-- TODO: replace placeholder src with actual decoration asset path -->
```

CSS must include `position: absolute` with coordinates from the visual spec.

### 3C — ESLint Pre-compliance (G7)

Apply these rules during generation, not after:

| Rule | Fix |
|---|---|
| `transify/no-literal-string` | Add `<!-- eslint-disable transify/no-literal-string -->` at file top |
| `vue/no-v-model-argument` | Use `:prop="val" @update:prop="handler"` instead of `v-model:prop` |
| `vue/no-v-for-template-key` | Avoid `<template v-for>`, use single-element `v-for` |
| `max-len` (120 chars) | Break long comment lines; keep template attributes on separate lines |

### 3D — z-index Convention (G10)

Drawer/Modal root element: `z-index: 9999`.

### 3E — CSS Variable Usage

Replace hardcoded hex values with project CSS variables when they appear in project-context.md:

```scss
// WRONG
color: #333333;
// CORRECT (if $text-primary is defined)
color: $text-primary;
```

### 3F — EDS Component Usage

Use the API snapshot from the visual spec. General patterns:

```vue
<!-- EdsTabs — use actual props from visual spec API snapshot -->
<EdsTabs :active-key="activeTab" @update:active-key="activeTab = $event">
  <EdsTabPane v-for="tab in tabs" :key="tab.key" :tab="tab.label" />
</EdsTabs>

<!-- EdsTable — use columns config pattern -->
<EdsTable :columns="columns" :data-source="rows" />

<!-- EdsTooltip wrapping question icon -->
<EdsTooltip :content="tooltipText">
  <EdsIcon :svg="questionIcon" class="question-icon" />
</EdsTooltip>
```

If the API snapshot shows different prop names, always use the snapshot as ground truth.

---

## Step 4 — Node Accounting Self-Check (before writing file)

After drafting the template, go through the visual spec Node Accounting list:

```
For each [ ] node in visual spec:
  - Find a corresponding DOM element in the draft template
  - If found → mentally mark as ✅
  - If not found → add the missing element before proceeding

All nodes must be ✅ before writing the fragment file.
Special attention: nodes marked **position: absolute** are most commonly missed.
```

---

## Step 5 — Write Fragment File

Write `fragment-regionX.vue` as a self-contained Vue 3 SFC:

```vue
<!-- eslint-disable transify/no-literal-string -->
<template>
  <!-- region content -->
</template>

<script setup lang="ts">
import { ref } from "vue";
// SVG imports (in correct order per import/order rule):
// 1. @eds-vue/svg/*
// 2. pas-common/eds-vue components
// 3. src/* local assets
</script>

<style lang="scss" scoped>
// All styles scoped. No Tailwind.
// Use CSS variables from project-context when available.
</style>
```

Fragment props/emits: declare only what is needed for this region. The Orchestrator will wire them during assembly.

---

## Step 6 — Write Codegen Handoff

Write `codegen-handoff-X.md` immediately after writing the fragment:

```markdown
---
stage: region-codegen
region: {X}
gate_status: ready
node_accounting_status: complete / missing: [{nodeId}, ...]
eds_components_used: [EdsTabs, EdsTable, EdsTooltip]
svgs_imported: [arrow-up-green.nosvgo.svg, success-circle.svg]
deviations: []
---

## Summary
Region {X} ({RegionName}) generated. {n} nodes accounted for.

## Node Accounting
- ✅ {nodeId} {nodeName}
- ✅ {nodeId} {nodeName} (absolute positioned)
- ...

## EDS Components
- ✅ EdsTabs used at {nodeId}
- ✅ EdsTable used at {nodeId}
- ✅ EdsTooltip used at {n} tooltip instances

## Manual TODOs
- [ ] Replace decoration placeholder: src/assets/images/placeholder.png → actual path
```

If any Node Accounting item is missing or any EDS component from the Structural Patterns was not used, set `gate_status: corrections-needed` and list specifics.
