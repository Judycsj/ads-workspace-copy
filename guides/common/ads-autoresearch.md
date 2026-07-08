# ads-autoresearch Skill Guide / ads-autoresearch 技能使用指南

> **Contributors**: chenjiawei ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-autoresearch.md)

`ads-autoresearch` orchestrates a full Content Ads model research loop by chaining
`ads-ar-planner` → `ads-ar-ego` → `ads-ar-conclusion`, prompting the user after each
round whether to iterate again.

---

## Prerequisites / 前提条件

### One-time bootstrap

Run once per workstation; it's idempotent:

```bash
bash skills/common/ads-autoresearch/scripts/bootstrap-autoresearch.sh
```

Populates `~/.config/sra/credentials.json`:
- **`ego` block** — token + Content Ads driver defaults (driver `10.168.130.21`,
  `mkplpaidads_brand_ads` HDFS dev path, `mkplpaidads-search-dev` Spark queue),
  with `<user_name>` substituted from your LDAP.
- **`autoresearch` block** — orchestrator policy defaults (`ego_region=sg`,
  `ego_scope=1`, `ego_project=ads_algo`, `trd_team=00.paid-ads-dev`).

Then it tests `smc toc <driver_host>` connectivity. **If the test fails, fix
smc / network before launching the skill** — the script prints the exact error.

EGO token: ego-portal → top-right avatar → **User Profile → Copy Token**.

### Other prerequisites

- A KP directory created via `ads-okr-epic-td` under
  `docs/team/<trd_team>/10.trd-prd-td-list/<quarter>/<objective>/<kr-kp-YYYYMMDDHHMM>/`
- `/tmp/ego-openapi-v1/` cloned (the orchestrator delegates to `ads-ar-ego` which
  delegates to `ads-ego-training`)
- (Optional) `algolab.space_token` + `algolab.user_email` in the same credentials
  file — required only if you plan to ask feature / slot questions during the
  loop (handled by `ads-afp`)

If the KP directory does not exist, the skill stops and tells you to run
`/ads-okr-epic-td` first.

---

## Quick Start / 快速开始

```
/ads-autoresearch
```

The orchestrator is **KP-driven**: a single KP is the unit of input. The skill
reads the KP's `epic-file.md` (and any prior `research/round-*/` artefacts)
before asking questions, then confirms each piece of context with you:

1. **KP directory** — KP id (e.g. `o1-kr2-kp3`) or full path. The skill
   verifies `epic-file.md` exists.
2. **Baseline model** — extracted from `epic-file.md` (KP Metadata, section
   5.3 关键发现 / KA descriptions) and, for round `N >= 2`, from the prior
   round's `metrics.md` winner. You confirm or override `model_id` /
   `version_id` / `job_id`.
3. **Research direction** — extracted from `epic-file.md` section 2.5
   方案思路（终版）, KA descriptions, section 5.5 下一步计划, and prior
   `metrics.md` "Action for next round". You confirm or adjust.
4. **Extra materials** — papers (PDFs), arxiv links, online search keywords,
   or internal docs. Pick any combination or skip.
5. **Prior-round carry-over** (round `N >= 2` only) — cluster, training
   days, countries, image, priority, target metrics from the previous
   round's `training.md` / `metrics.md`. You confirm or change what should
   differ this round.
6. **Language preference** — `English`, `Chinese`, or `Both` (single
   bilingual file with interleaved 中文 / English headings — current
   default). Applies to every doc this round produces (`plan.md`,
   `training.md`, `metrics.md`).

Then it executes the three stages and asks whether to continue with the next
round. Each new round re-runs the handshake above so you can shift direction
or change language per round.

During Stage 2 (training), every submitted EGO job — the Round-1 baseline
retrain, each variant, and every per-day job of a multi-day pipeline — is
registered in the validity table `dev_mkplpaidads_discovery_ads.ad_algos_job_infos`
so the quota enforcer does not kill it mid-round (wired in by `ads-ar-ego`; see
its guide).

---

## Output Layout / 产出目录

```
<KP-dir>/
├── research/
│   ├── round-1/
│   │   ├── plan.md             # from ads-ar-planner
│   │   ├── codes/              # Git-tracked entry-file copies (from ads-ar-planner)
│   │   │   ├── baseline/<entry>.py
│   │   │   ├── variant-a/<entry>.py
│   │   │   └── variant-a.diff
│   │   ├── training.md         # from ads-ar-ego
│   │   └── metrics.md          # from ads-ar-conclusion
│   ├── round-2/
│   └── ...
├── MEMORY.md                   # one row appended after each Stage 3 (by ads-ar-conclusion)
└── memory/
    └── YYYY-MM-DD-<user>.md    # appended after every stage by the stage's sub-skill
```

Each round persists the baseline + variant **entry files** (e.g.
`model_all_features.py`) plus unified diffs under `codes/`, so the round is
reviewable from Git and reproducible after `/tmp` is cleaned. The full code
zip can be re-fetched from EGO via the `model_version_id` recorded in
`plan.md` (filled in retroactively by `ads-ar-ego` after Stage 2).

**Path discipline**: every link inside `plan.md` / `training.md` /
`metrics.md` points to a sibling-relative path under the KP directory
(e.g. `codes/variant-a/model_all_features.py`). The
`/tmp/ads-ar/round-N/` working copies used by EGO submission are
**never** referenced from any checked-in doc.

---

## References / 参考资料

- [SKILL.md](../../skills/common/ads-autoresearch/SKILL.md)
- [ads-ar-planner SKILL.md](../../skills/common/ads-ar-planner/SKILL.md)
- [ads-ar-ego SKILL.md](../../skills/common/ads-ar-ego/SKILL.md)
- [ads-ar-conclusion SKILL.md](../../skills/common/ads-ar-conclusion/SKILL.md)
- [ads-ego-training guide](../team/03.content-algo/ads-ego-training.md)
- [ads-ego-multiday-pipeline guide](../team/03.content-algo/ads-ego-multiday-pipeline.md)
