---
name: figma-transcode-verify-region
description: Skill for a Verify Subagent. Compares a generated fragment-regionX.vue against its visual-spec-regionX.md ground truth. Checks node accounting, color correctness, EDS component usage, and SVG imports. Outputs a structured verify-handoff with pass/corrections-needed status.
---

# Region Verification

> **Context isolation rule**: This subagent starts with a clean context window. It reads ONLY:
> 1. `visual-spec-regionX.md` (ground truth)
> 2. `fragment-regionX.vue` (code to verify)
> 3. `codegen-handoff-X.md` (prior subagent's self-report)
> 4. This skill file
>
> It does NOT load Figma data, component-rules.md, or any other skill.

---

## Input Contract

The Orchestrator provides:
- `visual_spec_path`
- `fragment_path`
- `codegen_handoff_path`
- `verify_handoff_path` (output)

---

## Verification Checklist

Run each check in order. Record result as ✅ pass or ❌ fail with line numbers.

---

### Check 1 — Node Accounting

For each node in the visual spec `## Node Accounting` section:

1. Find the corresponding DOM element in the fragment template
2. For nodes marked `**position: absolute**`: verify `position: absolute` appears in the scoped CSS for that element
3. Record: ✅ found / ❌ missing (with node ID and name)

**Common failure**: absolute-positioned decoration layers have no corresponding element in the template.

---

### Check 2 — Multi-Color Text Runs

For each entry in the visual spec `## Text Color Runs` section:

1. Find the text content in the fragment template
2. Verify it is split into separate `<span>` elements (not a single string)
3. For each span, check that the CSS `color` value matches the fill from the visual spec
   - Accept both hex value and CSS variable (if the CSS variable resolves to the same color per project-context.md)

Example check:
```
Visual spec: Node 6365:28191 "+20%": fill #30B566, font-weight 500
Fragment:    <span class="metric-green">+20%</span>
CSS:         .metric-green { color: #30b566; font-weight: 500; }  ← case-insensitive ✅
```

**Common failure**: text merged into a single string with one color class, losing the split.

---

### Check 3 — EDS Structural Components

For each item in the visual spec `## Structural Patterns` section:

1. Check the corresponding EDS component tag appears in the fragment template:
   - `EdsTabs` → look for `<EdsTabs` in template
   - `EdsTable` → look for `<EdsTable` in template
   - `EdsTooltip` → look for `<EdsTooltip` wrapping an `<EdsIcon`
2. Check the component is imported from `pas-common/eds-vue` (not from `eds-vue` directly)
3. Check key props match the API snapshot in the visual spec (e.g. correct prop name for active tab key)

**Common failure**: custom div tabs replacing EdsTabs; raw `<table>` replacing EdsTable.

---

### Check 3b — nosvgo.svg Icons Must Have CSS width/height

For each `EdsIcon` in the fragment that uses a `.nosvgo.svg` import:

1. Check the element has a CSS class (not just `:size` prop)
2. Check that class has explicit `width` and `height` in the scoped CSS

```
// FAIL — nosvgo with only :size
<EdsIcon :svg="arrowUpGreenIcon" :size="12" />         ← ❌

// PASS — nosvgo with CSS class
<EdsIcon class="arrow-up-icon" :svg="arrowUpGreenIcon" /> ← ✅
.arrow-up-icon { width: 16px; height: 10px; flex-shrink: 0; }
```

**Common failure**: `:size` prop silently ignored on `.nosvgo.svg` — icon expands to fill flex container.

---

### Check 4 — SVG Asset Imports

For each item in the visual spec `## SVG Assets` section:

1. **EDS** assets: verify `import XxxIcon from '@eds-vue/svg/{name}.svg'` exists in `<script setup>`
2. **REUSE** assets: verify the existing path is imported (matching what's in the spec)
3. **NEW** assets: verify the downloaded path (`.svg` or `.nosvgo.svg`) is imported
4. **MANUAL-TODO** assets: verify a structured TODO comment exists in the template (no CSS unicode placeholder)
5. All SVG imports are used via `<EdsIcon :svg="XxxIcon" />` (not inline `<svg>`)

---

### Check 5 — ESLint Pre-compliance

Scan the fragment for known violations:

| Check | Pass condition |
|---|---|
| `<!-- eslint-disable transify/no-literal-string -->` | Present at file top (line 1) |
| `v-model:propName` syntax | Not present; uses `:prop + @update:prop` instead |
| `<template v-for>` with `:key` on child | Not present |
| Lines exceeding 120 characters | None |
| Inline `<svg>` tags | None |
| `import ... from 'eds-vue'` (direct import) | None — must use `pas-common/eds-vue` |

---

### Check 6 — z-index (for Drawer/Modal regions only)

If the region is a drawer root (uses `Teleport to="body"`): verify `z-index: 9999` in CSS.

---

## Output: Verify Handoff

Write `verify-handoff-X.md`:

```markdown
---
stage: verify
region: {X}
gate_status: pass | corrections-needed
retry_count: 0
---

## Check Results

| Check | Status | Details |
|---|---|---|
| Node Accounting | ✅ / ❌ | Missing: [{nodeId} {name}] |
| Text Color Runs | ✅ / ❌ | Node {id}: text merged into single span, missing color split |
| EDS: EdsTabs | ✅ / ❌ | Found custom div tabs instead of <EdsTabs> |
| EDS: EdsTable | ✅ / ❌ | Found raw <table> instead of <EdsTable> |
| EDS: EdsTooltip | ✅ / ❌ | Question icon not wrapped in <EdsTooltip> |
| SVG Imports | ✅ / ❌ | arrow-up-green.nosvgo.svg imported but used inline |
| ESLint Pre-compliance | ✅ / ❌ | Line 42 exceeds 120 chars |
| z-index (drawer) | ✅ / N/A | |

## Corrections Required (if gate_status: corrections-needed)

### C1 — Add missing absolute-positioned decoration node
Node 6226:29761 (Group 1940671270) has position: absolute at x:714, y:-50, 286×286px.
Add:
```vue
<img class="suggestion-decoration" src="@/assets/images/placeholder.png" alt="" />
```
```scss
.suggestion-decoration {
  position: absolute;
  top: -50px;
  right: 0;
  width: 286px;
  height: 286px;
  pointer-events: none;
}
```

### C2 — Split multi-color text in WoW Effect column
Node 6226:30009 "+10%" (fill #30B566) is merged with surrounding text.
Replace:
```vue
<span class="effect-green">GMV+10%, Order +15%</span>
```
With:
```vue
<span class="effect-label">GMV</span>
<span class="effect-value">+10%</span>
<span class="effect-label">, Order</span>
<span class="effect-value">+15%</span>
```
Add CSS: `.effect-value { color: #30b566; font-weight: 500; }`

### C3 — Replace custom tabs with EdsTabs
...
```

---

## Correction Dispatch Rule

If `gate_status: corrections-needed`, the Orchestrator re-dispatches the Region Codegen Subagent with:
- Original `visual-spec-regionX.md` (unchanged)
- `verify-handoff-X.md` (the correction list above)
- Instruction: "Apply all corrections listed in verify-handoff, then recheck."

Maximum 2 retry attempts. If still `corrections-needed` after 2 retries, set `gate_status: manual-review-needed` and include the correction list in the final transcode report as unresolved items.
