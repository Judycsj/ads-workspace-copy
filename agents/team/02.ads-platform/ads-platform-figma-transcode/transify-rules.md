---
name: figma-transcode-transify-rules
description: Reference document for figma-transcode agent — Transify key matching flow (Step 3b). Lookup existing translation keys, generate placeholder keys for new UI text, and produce a developer review report.
---

# Transify Key 匹配规范 / Transify Key Matching Rules

> Step 3b 的 reference doc。执行前须经用户确认，不自动触发。

---

## 触发条件 / Trigger

Step 3 代码生成完成后，询问用户：

```
是否需要匹配 Transify 翻译 key？
将自动查找目标项目现有 key，未找到的文字生成占位 key 供后续提交。(y/n)
```

- 用户确认（y）→ 执行本文件流程
- 用户拒绝（n）→ 跳过，UI 文字保留字面量，文件头保留 `<!-- eslint-disable transify/no-literal-string -->`

---

## 执行流程 / Workflow

### Step 1 — 提取 UI 文字

从生成的 `.vue` 文件 `<template>` 中提取所有字面量字符串：

**保留**（用户可见的 UI 文字）：
- 按钮文字、标签、标题、列头、提示语、空状态文字

**排除**（非展示用字符串）：
- CSS class 名、SVG 属性值（`viewBox`、`fill`、`stroke-linecap` 等）、代码注释
- 纯数字、URL、格式化占位符（`{xxx}`）

---

### Step 2 — 确定目标 collection

根据目标项目路径查表（来自 `ads-platform-transify-lookup` SKILL.md）：

| 项目路径关键词 | Collection ID |
|---|---|
| `pas-product` | `1341` |
| `pas-index` | `1419, 1423, 1424` |
| `pas-display` | `1318` |
| `ads-remote` | `1412` |
| 未知 / 未找到 | fallback: `1742` |

若无法从文件路径判断，询问用户确认项目名称。

---

### Step 3 — Reverse Lookup（文字 → Key）

调用 `ads-platform-transify-lookup` 的缓存+搜索流程：

```bash
# 1. 确保缓存存在
bash scripts/fetch-translations.sh {collection_id}

# 2. 对每条 UI 文字做 reverse lookup
rg -i "{ui_text}" .tmp/transify-cache/nonlive.en.col{id}.json

# 3. 未找到时尝试 fallback collection
rg -i "{ui_text}" .tmp/transify-cache/nonlive.en.col1742.json
```

---

### Step 4 — 分类处理

| 查找结果 | 处理方式 |
|---|---|
| ✅ 找到精确匹配 key | 代码中替换为 `$t('existing_key')` 或 `translate('existing_key')` |
| ⚠️ 找到相似但不完全一致 | 展示给用户确认是否复用，用户确认后替换 |
| 🆕 未找到 | 按命名规范生成占位 key，代码中使用，报告中标注"需提交" |

---

### Step 5 — 占位 Key 命名规范

新增占位 key 必须符合以下规范：

- **格式**：全小写 `snake_case`
- **前缀**：来自功能模块名，如 `ads_diagnosis_`、`ads_review_`、`ads_performance_`
- **语义**：英文描述，简洁清晰
- **长度**：不超过 50 字符
- **禁止**：拼音、缩写不明的词、纯数字后缀

```
✅ ads_diagnosis_title
✅ ads_diagnosis_well_done_text
✅ ads_optimization_record_label
❌ zhenduan_title
❌ ads_diag_1
❌ ads_diagnosis_button_for_closing_the_drawer_in_the_top_right
```

---

### Step 6 — 代码替换

将 `<template>` 中匹配的字面量替换为 key 调用：

```vue
<!-- 替换前 -->
<span class="drawer-title">Diagnosis</span>

<!-- 替换后（复用已有 key） -->
<span class="drawer-title">{{ $t('ads_diagnosis_title') }}</span>

<!-- 替换后（新增占位 key） -->
<span class="drawer-title">{{ $t('ads_diagnosis_drawer_title') }}</span>
```

> 注意：完成替换后，文件头的 `<!-- eslint-disable transify/no-literal-string -->` 可按需移除（若所有可见文字均已替换）。

---

## 输出：转码报告 Transify 节 / Report Section

在 `{ComponentName}-transcode-report.md` 中追加：

```markdown
### Transify Key 使用报告

| UI 文字 | Key | 状态 |
|---|---|---|
| "Diagnosis" | `ads_diagnosis_title` | ✅ 复用（collection 1341） |
| "Suggestion" | `ads_diagnosis_suggestion_label` | ✅ 复用（collection 1341） |
| "Well done, keep it up!" | `ads_diagnosis_well_done_text` | 🆕 占位（需提交到 collection 1341） |
| "Optimization Record" | `ads_diagnosis_optimization_record` | 🆕 占位（需提交到 collection 1341） |
| "Ads Optimized" | `ads_diagnosis_metric_ads_optimized` | 🆕 占位（需提交到 collection 1341） |

**开发者待办**：
- [ ] 将 🆕 占位 key 和对应英文文本提交到 Transify 后台 collection {id}
- [ ] 补充非英文语言的翻译（en 文本已由 agent 生成）
- [ ] 复查"⚠️ 相似"条目，确认是否复用现有 key
```
