---
name: figma-transcode-eds-api-compact
description: Fallback EDS component API reference for the figma-transcode pipeline. Used when grep cannot locate a component's source file in pas-common. Contains real usage patterns extracted from pas-product source (not documentation). Update when EDS major version changes.
---

# EDS API Compact Reference

> **When to use**: The Orchestrator reads this file during Phase 3 (Structural Classification + EDS API Snapshot) ONLY when `grep` fails to locate a component's `.vue` file in pas-common. Otherwise prefer reading the real source.
>
> **Source**: Patterns extracted from `/src/_shared/components/` in pas-product (verified 2026-06-02, EDS 5.0.36).
>
> All components imported from `pas-common/eds-vue`.

---

## EdsTabs

```vue
<script setup lang="ts">
import { ref } from "vue";
import { EdsTabs } from "pas-common/eds-vue";

const activeTab = ref("tab1");
const tabs = [
  { key: "tab1", label: "Tab One" },
  { key: "tab2", label: "Tab Two" },
];
</script>

<template>
  <!-- v-model binds to the active tab key (string) -->
  <EdsTabs v-model="activeTab" :tabs="tabs" />
</template>
```

**Props**:
- `v-model` (string): active tab key — uses default model, NOT `v-model:modelValue`
- `:tabs` (Array<{ key: string; label: string }>): tab items

**⚠️ Background requirement**: EdsTabs renders with transparent background. On gradient or colored parent, tab text becomes invisible. Always wrap in a white background div:

```vue
<div class="tabs-section">
  <EdsTabs v-model="activeTab" :tabs="tabs" />
</div>
```
```scss
.tabs-section { background: #ffffff; }
```

**Note**: `vue/no-v-model-argument` ESLint rule is active — use plain `v-model`, not `v-model:activeKey`.

---

## EdsTable + EdsTableColumn

```vue
<script setup lang="ts">
import { EdsTable, EdsTableColumn } from "pas-common/eds-vue";
</script>

<template>
  <EdsTable :data="rows" sticky-header :loading="isLoading">
    <EdsTableColumn prop="name" label="Name" :width="200" fixed="left" />
    <EdsTableColumn prop="optimization" label="Optimization">
      <template #default="{ row }">
        <!-- custom cell renderer -->
        <div v-for="opt in row.optimizations" :key="opt">{{ opt }}</div>
      </template>
    </EdsTableColumn>
    <EdsTableColumn prop="effect" label="WoW Effect" :width="160" />
  </EdsTable>
</template>
```

**Props on EdsTable**:
- `:data` (Array): row data
- `sticky-header` (boolean): freeze header on scroll
- `:loading` (boolean): show loading state
- `height` (string | number): fixed table height for scroll

**Props on EdsTableColumn**:
- `prop` (string): key in row data object
- `label` (string): column header text
- `:width` (number): column width in px
- `fixed` ("left" | "right"): sticky column

**Custom cell**: use `#default="{ row }"` slot for multi-element cells (e.g. multi-color text, icons).

---

## EdsButton

```vue
<template>
  <!-- Primary (orange fill) -->
  <EdsButton type="primary" @click="handleClick">Top Up Now</EdsButton>

  <!-- Ghost / secondary -->
  <EdsButton @click="handleClick">Cancel</EdsButton>

  <!-- Small size -->
  <EdsButton size="small" type="primary" @click="handleClick">Adopt</EdsButton>

  <!-- Disabled -->
  <EdsButton type="primary" :disabled="isDisabled" @click="handleClick">Submit</EdsButton>

  <!-- Loading -->
  <EdsButton type="primary" :loading="isLoading" @click="handleClick">Save</EdsButton>
</template>
```

**Props**: `type` ("primary" | ""), `size` ("small" | ""), `:disabled`, `:loading`

---

## EdsIcon

```vue
<script setup lang="ts">
import closeIcon from "@eds-vue/svg/close.svg";
import { EdsIcon } from "pas-common/eds-vue";
</script>

<template>
  <EdsIcon :svg="closeIcon" />
  <EdsIcon :svg="closeIcon" :size="16" />
  <EdsIcon :svg="closeIcon" class="icon-grey" />
</template>

<style scoped>
.icon-grey { color: #b7b7b7; }
</style>
```

**Props**: `:svg` (Vue component from SVG import), `:size` (number, optional)
**Color**: controlled via CSS `color` (uses `currentColor` internally)

---

## EdsPopover (used for hover tooltips — NOT EdsTooltip)

> **Important**: pas-product uses `EdsPopover` with `trigger="hover"` for question-mark tooltips, not `EdsTooltip`.

```vue
<script setup lang="ts">
import questionIcon from "@eds-vue/svg/question-mark.svg";
import { EdsIcon, EdsPopover } from "pas-common/eds-vue";
</script>

<template>
  <!-- Simple text tooltip on hover -->
  <EdsPopover trigger="hover" content="Total ads optimized since last month">
    <EdsIcon :svg="questionIcon" class="question-icon" />
  </EdsPopover>

  <!-- Dynamic content tooltip -->
  <EdsPopover trigger="hover" :content="tooltipText">
    <EdsIcon :svg="questionIcon" class="question-icon" />
  </EdsPopover>
</template>
```

**Props**: `trigger` ("hover" | "click"), `content` (string)
**Slot**: default slot is the trigger element

---

## EdsCheckbox

```vue
<template>
  <EdsCheckbox v-model="isChecked" />
  <EdsCheckbox v-model="row.selected" />
</template>
```

**Props**: `v-model` (boolean)

---

## EdsInput

```vue
<template>
  <EdsInput v-model="inputValue" placeholder="Enter value" :disabled="isDisabled" />
</template>
```

**Props**: `v-model` (string), `placeholder`, `:disabled`

---

## EdsSwitch

```vue
<template>
  <EdsSwitch v-model="isEnabled" />
</template>
```

**Props**: `v-model` (boolean)

---

## Avatar (pas-common, not EDS)

```vue
<script setup lang="ts">
import { Avatar } from "pas-common/components";
</script>

<template>
  <Avatar :src="productImageUrl" :size="32" />
</template>
```

**Import**: `pas-common/components` (not `pas-common/eds-vue`)
**Props**: `:src` (string URL), `:size` (number)

---

## Import Order Rule (ESLint import/order)

```ts
// 1. @eds-vue/svg/* SVG assets
import closeIcon from "@eds-vue/svg/close.svg";
import questionIcon from "@eds-vue/svg/question-mark.svg";

// 2. pas-common/eds-vue components
import { EdsButton, EdsIcon, EdsPopover, EdsTabs, EdsTable, EdsTableColumn } from "pas-common/eds-vue";

// 3. pas-common/components (L1 pas-common business components)
import { Avatar } from "pas-common/components";

// 4. src/* local assets
import arrowUpGreenIcon from "src/_shared/assets/svg/arrow-up-green.nosvgo.svg";
```
