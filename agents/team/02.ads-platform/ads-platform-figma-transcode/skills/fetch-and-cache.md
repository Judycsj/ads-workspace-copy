---
name: figma-transcode-fetch-and-cache
description: Skill for the figma-transcode Orchestrator — Phase 1 & 2. Fetches Figma data, scans the target project for existing assets, extracts visual specs per region, and resolves SVGs. Produces the artifact files that all downstream Region Codegen Subagents consume.
---

# Fetch, Cache & Visual Spec Generation

> **When to read this file**: Orchestrator reads this skill at the start of Phase 1 (Project Context Scan + Figma Fetch). Do NOT load this into the same context window as region-codegen.md or verify-region.md.

---

## Phase 1 — Project Context Scan

**Execute before touching Figma.** Avoids redundant downloads and grounds codegen in real project conventions.

### 1A — Scan existing SVG assets

```bash
find {output_project}/src/_shared/assets/svg/ -name "*.svg" -o -name "*.nosvgo.svg" | sort
```

Record result as `existing_svgs: [filename, ...]` in the artifact `project-context.md`.

### 1B — Scan existing components + extract working patterns

**Step 1: Name collision check**

```bash
find {output_project}/src/_shared/components/ -name "*.vue" | head -80
```

Check whether any component name matches the target Figma node name. If a match exists, note it and ask the user before generating a new file.

**Step 2: Working pattern extraction (run after Structural Classification in Phase 3)**

Once the Structural Classification identifies which EDS components will be needed (e.g. `EdsTabs`, `EdsTable`, `EdsPopover`), grep the project for real working usages:

```bash
# For each identified EDS component, find a real working file
grep -rln "EdsTabs" {output_project}/src --include="*.vue" | head -3
grep -rln "EdsTable" {output_project}/src --include="*.vue" | head -3
grep -rln "EdsPopover" {output_project}/src --include="*.vue" | head -3
```

For each file found, read the **first 80 lines** (covers imports + component usage). Extract:

- Exact import statement
- Exact template usage (props, slots, wrappers)
- Any wrapper divs or CSS classes the component relies on

Record as **Working Patterns** in `project-context.md`. Region Codegen Subagents use these as their primary code template — not the eds-api-compact.md descriptions, which are secondary fallbacks.

**Known patterns to always capture:**

| Component | What to look for | Why |
|---|---|---|
| `EdsTabs` | Is it wrapped in a container div? What class? What background? | EdsTabs renders transparent; needs white bg on gradient |
| `EdsTable` | Does column header use `label=` or `#header` slot? Are they mixed? | Mixing causes "#ColumnName" rendering bug |
| `EdsIcon` (nosvgo) | Does it have a CSS class with `width/height`? | `:size` prop ignored on `.nosvgo.svg` files |
| `EdsPopover` | What is `trigger=` value? Is content a string or slot? | `trigger="hover"` vs `trigger="click"` differs per use case |

### 1C — Read project lint config

```bash
cat {output_project}/.eslintrc.js 2>/dev/null || cat {output_project}/.eslintrc.cjs 2>/dev/null | head -60
```

Extract active ESLint rules relevant to Vue/template. Record in `project-context.md`.

### 1D — Read CSS design tokens (optional, if styles/ exists)

```bash
find {output_project}/src/_shared/styles/ -name "*.scss" | head -5
# read the first variables file found
```

Extract colour variables and spacing tokens. These take precedence over hardcoded hex values in generated CSS.

### Output

Write `{artifact_dir}/project-context.md`:

```markdown
# Project Context

## Existing SVG Assets
- close.svg (src/_shared/assets/svg/)
- arrow-up-green.nosvgo.svg (src/_shared/assets/svg/)
- ...

## Existing Components (matching Figma node name)
- none / DiagnosisTwoDrawer.vue (possible reuse candidate)

## ESLint Rules (active)
- transify/no-literal-string: error
- vue/no-v-model-argument: error
- import/order: warn

## CSS Variables
- $text-primary: #333333
- $text-secondary: #666666
- $text-light: #999999
- $color-orange: #EE4D2D
- $color-green: #30B566

## Working Patterns (extracted from existing project components)

### EdsTabs — source: src/_shared/components/detail-header/review-and-upgrade-ads-drawer/index.vue
```vue
<!-- ⚠️ Must wrap in white-background div when parent has gradient bg -->
<div class="tabs-section">
  <EdsTabs v-model="activeTab" :tabs="tabs" />
</div>
```
```scss
.tabs-section { background: #ffffff; }
```

### EdsTable — source: src/_shared/components/increase-bid-price-modal/index.vue
```vue
<!-- ⚠️ Do NOT mix label= and #header slot on the same EdsTableColumn -->
<EdsTable sticky-header :data="rows" height="400">
  <EdsTableColumn prop="name" label="Ads Info" :width="300" />
  <EdsTableColumn prop="opt">
    <template #header><span>Optimization</span></template>
    <template #default="{ row }">...</template>
  </EdsTableColumn>
</EdsTable>
```

### EdsPopover — source: src/_shared/components/detail-header/diagnosis-two-drawer/index.vue
```vue
<EdsPopover trigger="hover" :content="tooltipText">
  <EdsIcon :svg="questionIcon" class="question-icon" />
</EdsPopover>
```

### EdsIcon (.nosvgo.svg) — source: src/_shared/assets/svg/
```vue
<!-- ⚠️ .nosvgo.svg files IGNORE :size prop — always use CSS width/height -->
<EdsIcon class="arrow-up-icon" :svg="arrowUpGreenIcon" />
```
```scss
.arrow-up-icon { width: 16px; height: 10px; flex-shrink: 0; }
```
```

---

## Phase 2 — Figma Fetch

### 2A — Try Official MCP first

```
mcp__claude_ai_Figma__get_design_context(fileKey, nodeId)
mcp__claude_ai_Figma__get_metadata(fileKey, nodeId)
```

If successful: response includes pre-resolved layout + screenshot + reference code → go to Phase 3.

### 2B — Framelink fallback (if Official MCP unavailable)

**Step 1 — Screenshot** (always required as visual ground truth):

```
mcp__figma-framelink__download_figma_images(
  fileKey,
  nodes: [{ nodeId, fileName: "{nodeId}.png" }],
  localPath: "{artifact_dir}/"
)
```

**Step 2 — Skeleton scan** (depth=2):

```
mcp__figma-framelink__get_figma_data(fileKey, nodeId, depth=2)
```

Extract top-level regions:
```
Regions:
  [A] Title bar     id=...  layout=layout_XXX  type=FRAME
  [B] Main content  id=...  layout=layout_YYY  type=FRAME
  [C] Footer        id=...  layout=layout_ZZZ  type=FRAME
```

**Step 3 — Layout token resolution** (read last 1200 lines of saved response if file was written):

```bash
wc -l {saved_response_file}
# Read tool: offset = (total_lines - 1200)
```

Build layout token map: `layout_token_id → { direction, gap, padding, align, width, height }`

**Step 4 — Sub-region drill-down** (one call per top-level region, can run sequentially):

```
mcp__figma-framelink__get_figma_data(fileKey, regionNodeId)  // no depth limit
```

**Step 5 — Write raw data cache**:

```bash
# Write Figma JSON response to artifact dir
```

File: `{artifact_dir}/figma-data-{nodeId}.json` (or .md if JSON not practical)

---

## Phase 3 — Structural Classification

For each top-level region, identify structural patterns **before** per-node classification:

### Structural Pattern Detection Rules

| Pattern Signal | Target Component | Confidence Signal |
|---|---|---|
| Sibling nodes each containing text label + underline/highlight indicator, with one active state | `EdsTabs` | ≥ 2 tab siblings with ink/underline children |
| Node group with one header row + multiple repeating data rows (same layout) | `EdsTable` | thead-like node + ≥ 2 identical-layout tbody nodes |
| Question-mark IMAGE-SVG next to a label, no click handler | `EdsTooltip` wrapping `EdsIcon` | componentId matches `question-mark` component |
| IMAGE-SVG node (any) | → svg-resolve queue | type == IMAGE-SVG |
| Overlay node with `position: absolute` | **MUST be in Node Accounting** | layout has `locationRelativeToParent` |

Record patterns in `preflightChecklist` (written to visual spec).

### EDS API Snapshot

For each identified EDS structural component (`EdsTabs`, `EdsTable`, etc.):

```bash
# Locate component file in pas-common
grep -r "defineProps" {pas_common_path}/src/ --include="*.vue" -l | grep -i "{ComponentName}" | head -1
# Read first 80 lines of that file
```

Append the props/emits to the visual spec under `[EDS API Reference]`. This eliminates the need for downstream subagents to search pas-common.

**Fallback**: if grep finds nothing, read `agents/team/02.ads-platform/ads-platform-figma-transcode/eds-api-compact.md` and extract the relevant component section.

---

## Phase 4 — Visual Spec Generation (one file per region)

Write `{artifact_dir}/visual-spec-region{X}.md` for each top-level region:

```markdown
# Visual Spec — Region {X}: {RegionName}

**Figma Node**: {nodeId} | {w}×{h}px | {childCount} children
**Screenshot**: {artifact_dir}/{nodeId}.png

## Node Accounting (all nodes must appear in generated code)
- [ ] {nodeId} {nodeName} — {brief layout description}
- [ ] {nodeId} {nodeName} — **position: absolute** x:{x} y:{y} ← decoration, do NOT skip
  > For absolute-positioned decorations without a downloadable asset: use `<div class="...decoration">` (not `<img src="@/...">` — static @/ paths cause webpack build errors)
- [ ] ...

## Structural Patterns (EDS components to use — verified against real API)
- [ ] {nodeId} → EdsTabs
      Props: (from EDS API snapshot below)
- [ ] {nodeId} → EdsTable
      Columns: [{title, key}, ...]
- [ ] {nodeId} → EdsTooltip wrapping EdsIcon (question-mark)

## SVG Assets
- [ ] {nodeId} {svgName} → **REUSE** `src/_shared/assets/svg/{existing}.svg` ← already exists
- [ ] {nodeId} {svgName} → **NEW** downloaded to `src/_shared/assets/svg/{name}.nosvgo.svg`
- [ ] {nodeId} {svgName} → **EDS** `@eds-vue/svg/{name}.svg`

## Text Color Runs (multi-color text — each run needs its own <span>)
- Node {id} "{text}": fill {hex}, font-weight {w}, font-size {px}
- Node {id} "{text}": fill {hex}, font-weight {w}, font-size {px}
- ...

## Layout Tokens
- {className}: flex-direction {row|column}, gap {n}px, padding {n}px
- ...

## CSS Variables to Use (from project-context.md)
- Use $text-primary instead of #333333
- Use $color-orange instead of #EE4D2D

## EDS API Reference
### EdsTabs
```vue
<!-- props extracted from pas-common source -->
```
### EdsTable
```vue
<!-- props extracted from pas-common source -->
```
```

---

## Phase 5 — SVG Resolution

For each IMAGE-SVG node in the svg-resolve queue:

```
1. Read componentId from Figma data cache
2. Look up componentId in metadata.components → component name
3. Check: does name match @eds-vue/svg/ pattern?
   → YES: record import path as @eds-vue/svg/{name}.svg, mark as EDS
   → NO: check project-context.md existing_svgs for exact filename match
         → EXISTS: mark as REUSE with existing path (no download needed)
         → NEW: call download_figma_images → save to src/_shared/assets/svg/
                if SVG contains <defs>/<clipPath>/<linearGradient> → use .nosvgo.svg suffix
                mark as NEW in visual spec
4. download fails AND no componentId:
   → mark as MANUAL-TODO in visual spec (no placeholder code generated)
```

**Hard rule**: Never generate a CSS unicode placeholder (▲ ↑ etc.) when a componentId exists. A componentId means the icon is resolvable; attempt download before giving up.

Update visual spec SVG Assets section with resolved paths after this step.
