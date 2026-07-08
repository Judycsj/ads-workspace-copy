# ads-ar-planner Skill Guide / ads-ar-planner 技能使用指南

> **Contributors**: chenjiawei ｜ **最后更新**：2026-05-21 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ar-planner.md)

`ads-ar-planner` is stage 1 of `ads-autoresearch`. Given an OKR/KP, a base model,
and a research direction, it generates 2-3 ablation code variants and writes the
canonical `plan.md` for the round.

---

## Prerequisites / 前提条件

- The `ego` block in `~/.config/sra/credentials.json` (used by `ads-ego-training`
  to download base model code)
- A KP directory with `epic-file.md`. If missing, run `/ads-okr-epic-td` first.
- For online research mode: `WebSearch` / `WebFetch` available

---

## When to use / 何时使用

- You want to start a new research round but only need the planning artifacts.
- The training stage will be run later (or by a colleague).
- You want to peer-review the plan before kicking off EGO training.

For the full plan→train→conclude loop, use `/ads-autoresearch` instead.

---

## Quick Start / 快速开始

```
/ads-ar-planner
```

When invoked **from `ads-autoresearch`**, baseline, direction, materials,
prior-round paths, and language preference all arrive pre-confirmed — the
planner just plans.

When invoked **standalone**, the skill asks for:

1. KP directory path
2. Base model — for round 1, `model_id + version_id` or `job_id`. For round
   `N >= 2`, defaults to the prior round's winning variant; you can override.
3. Research direction — read from `epic-file.md` 2.5 / KA descriptions /
   5.5 and confirmed with you.
4. Extra materials — papers (PDFs) / arxiv links / online search keywords /
   internal docs.
5. Language preference — `English` / `Chinese` / `Both` (single bilingual
   file, default).

It then downloads the baseline code to `/tmp/ads-ar/round-N/baseline/`, drafts
2-3 variants under `/tmp/ads-ar/round-N/variant-<x>/`, persists each variant's
entry file + diff into the durable `<KP-dir>/research/round-N/codes/`, and
writes `<KP-dir>/research/round-N/plan.md`. The plan links code via
KP-relative paths (`codes/variant-a/<entry_file>`) — never `/tmp/`.

---

## Output / 产出

**Durable (under the KP — what `plan.md` links to):**
- `<KP-dir>/research/round-N/plan.md`
- `<KP-dir>/research/round-N/codes/baseline/<entry_file>`
- `<KP-dir>/research/round-N/codes/variant-<x>/<entry_file>` per variant
- `<KP-dir>/research/round-N/codes/variant-<x>.diff` per variant
- One memory entry in `<KP-dir>/memory/YYYY-MM-DD-<user>.md`

**Ephemeral (working copies for `create_model_version.sh --model_path`):**
- `/tmp/ads-ar/round-N/baseline/`, `variant-{a,b,c}/`, `variant-<x>.diff` —
  never referenced from any checked-in doc.

---

## References / 参考资料

- [SKILL.md](../../skills/common/ads-ar-planner/SKILL.md)
- [ads-ego-training guide](ads-ego-training.md) — base model download semantics
- [ads-okr-epic-td](../../skills/common/ads-okr-epic-td/SKILL.md) — KP directory creation
