# Ads OKR Epic TD (ads-okr-epic-td) Guide

> **Language**: [English](ads-okr-epic-td.md) | [中文](ads-okr-epic-td.zh-CN.md)

Generate or review Epic TD (Technical Design) documents for KP owners. Follows top-down reasoning through template sections: background → feasibility analysis (derives KA list) → solution design → timeline.

**Trigger keywords**: "epic td", "epic 文档", "td 文档", "ads-okr-epic-td", "生成 td", "写 epic", "check epic td", "审查 td", "拆解 KA", "KA 拆解", "分解 KP", "KP 拆解为 KA"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with generate/review workflows and KA quality rules |
| `templates/doc-template/epic-file-202xQx-Ox-KRx-KPx-epicTitle.md` | Epic TD template with 4-type conditional guidance |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| OKR GSheet | Data | Read KP metadata (title, Why Do, deliverable) |
| Google Drive MCP | Tool | Create Google Doc for the Epic TD |

---

## Usage

### Mode 1: Generate Epic TD (default)

```
/ads-okr-epic-td [--kp "Ox-KRy-KPz"]
```

Multi-round dialogue workflow:
1. **Step 1**: Collect KP metadata (ID, source, type, quarter, title)
2. **Step 2**: Discuss Chapter 1 — Background & Objectives (KB Summary → Background → Acceptance Criteria → Non-Goals)
3. **Step 3**: Discuss Chapter 2 — Feasibility Analysis (Analysis Approach → Implementation → Solution Ideas → **derive KA list**)
4. **Step 4**: Discuss Chapter 3 — Solution Design (Current State → Design → Example → Validation)
5. **Step 5**: Generate Chapter 4 — Timeline (assign owner & deadline per KA)
6. **Step 6-8**: Completeness check → Create Google Doc + local MD → Output next steps

### Mode 2: Review existing Epic TD

```
/ads-okr-epic-td --check <doc_url_or_path>
```

Checks chapter completeness, KA quality (rules 1/3/5/6), content quality by KP type, and naming convention.

### KP Types

| Type | Chinese | Use Case |
|------|---------|----------|
| greenfield | 从无到有 | Building capabilities that don't exist yet |
| problem-driven | 问题驱动 | Solving known problems or pain points |
| incremental | 精益求精 | Marginal optimization on running systems |
| refactor | 系统重构 | Unifying/migrating/decoupling scattered systems |

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `/ads-okr-planner` | Upstream: KR→KP planning (KR owner) |
