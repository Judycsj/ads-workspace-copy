# Ads OKR Planner (ads-okr-planner) Guide

> **Language**: [English](ads-okr-planner.md) | [中文](ads-okr-planner.zh-CN.md)

Plan KR→KP decomposition or review KR/KP quality for KR owners. Does not handle KA decomposition (use `/ads-okr-epic-td` for KP→KA).

**Trigger keywords**: "okr planner", "okr 规划", "拆解 KR", "KP 拆解", "ads-okr-planner", "KP 质量", "check KP", "审查 KP", "审查 OKR"

---

## Skill Files

| File | Description |
|------|-------------|
| `SKILL.md` | Main skill definition with generate/review/refine modes and KP quality rules |

---

## Prerequisites

| Dependency | Type | Purpose |
|-----------|------|---------|
| OKR GSheet | Data | Read/write KR/KP data |
| Google Drive MCP | Tool | Read Epic File links for KA extraction |

---

## Usage

### Mode 1: Generate KPs from KR (default)

```
/ads-okr-planner
```

Multi-round dialogue to decompose a KR into KPs following SOP quality rules.

### Mode 2: Review KR/KP quality

```
/ads-okr-planner --check [rowX]
```

Reviews content quality of specified GSheet rows, extracts KAs from Epic File Link and writes them back to column D.

### Mode 3: Single KP refinement

```
/ads-okr-planner --refine <KP>
```

Quality review and knowledge-enhanced refinement for a single KP.

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `/ads-okr-epic-td` | Downstream: KP→KA decomposition via Epic TD (KP owner) |
