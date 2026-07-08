# ads-ar-conclusion Skill Guide / ads-ar-conclusion 技能使用指南

> **Contributors**: chenjiawei ｜ **最后更新**：2026-05-21 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ar-conclusion.md)

`ads-ar-conclusion` is stage 3 of `ads-autoresearch`. Given a finished training
round, it pulls offline metrics from EGO, applies the user-confirmed target
metrics (e.g. `shop_broad_cr`, `pCTR`, `shop_ctr`), writes `metrics.md`, and
appends to the KP's memory files.

---

## Prerequisites / 前提条件

- `<KP-dir>/research/round-N/training.md` already produced by `ads-ar-ego`
- All variant jobs (or multi-day pipelines) have finished training
- The `ego` block in `~/.config/sra/credentials.json` (for `get_job_metrics.sh`)
- `/tmp/ego-openapi-v1/` cloned

---

## When to use / 何时使用

- Round training has finished and you want the canonical metrics summary.
- You need to update `<KP-dir>/MEMORY.md` after a round.
- For epic-file.md section 5 sync, use `/ads-okr-memory-sync` separately.

---

## Quick Start / 快速开始

```
/ads-ar-conclusion
```

The skill asks for:

1. Round directory (`<KP-dir>/research/round-N/`)
2. Target metrics — for round 1, ask fresh (e.g. `shop_broad_cr`, `pCTR`,
   `shop_ctr`; must match heads defined in your model code). For `N >= 2`,
   pre-fill from the prior round's `metrics.md` "Target Metrics" line and
   ask whether to keep or update.
3. Comparison baseline `job_id` (defaults to the one in `plan.md`)
4. Language preference (`English` / `Chinese` / `Both`) — passed through from
   the orchestrator; controls headings/body of `metrics.md`.

It then pulls eval-round AUC for baseline and each variant, computes Δ vs
baseline, identifies the winner, and writes
`<KP-dir>/research/round-N/metrics.md`. All sibling links (`plan.md`,
`training.md`, `codes/...`) inside `metrics.md` are KP-relative — never
`/tmp/`.

---

## Output / 产出

- `<KP-dir>/research/round-N/metrics.md`
- One row appended to `<KP-dir>/MEMORY.md`
- One "Key Decisions & Findings" entry in
  `<KP-dir>/memory/YYYY-MM-DD-<user>.md`

---

## Notes / 注意事项

- `epic-file.md` is **not** auto-updated. Run `/ads-okr-memory-sync` once you
  want section 5 (KP Execution & Status) refreshed.
- Failed / partial variants are recorded as such — not silently dropped.
- For online AB analysis, use `/ads-experiment-analyze`. For TRD writeup, use
  `/anthropic-skills:model-trd-writer`.
- If a winner is found, the skill offers to launch a longer follow-up training
  run on that variant — you'll be asked for the date range, cold/warm start,
  checkpoint or job ID (warm only), and `filter_nn` value, then it hands off
  to `/ads-ego-multiday-pipeline`.

---

## References / 参考资料

- [SKILL.md](../../skills/common/ads-ar-conclusion/SKILL.md)
- [ads-ego-training guide](ads-ego-training.md) — `get_job_metrics.sh` semantics
- [ads-ego-multiday-pipeline guide](ads-ego-multiday-pipeline.md) — `state.json` history
