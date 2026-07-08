# ads-ar-ego Skill Guide / ads-ar-ego 技能使用指南

> **Contributors**: chenjiawei ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ar-ego.md)

`ads-ar-ego` is stage 2 of `ads-autoresearch`. It takes a planner-produced round
directory and submits each variant to EGO — single-job for short tests,
multi-day pipeline for full ablations — then monitors and retries failures.

Step 0 of the workflow `find`s and `Read`s the config / debug references inside
`ads-ego-training/references/` and the multi-day driver
`ads-ego-multiday-pipeline/scripts/train_pipeline.py` so the skill always uses
the canonical CLI flags, YAML schema, and failure playbook rather than guessing.

---

## Prerequisites / 前提条件

- The `ego` block in `~/.config/sra/credentials.json` (token, driver_host,
  driver_login_cmd, driver_work_dir, hdfs_dev_path, spark_queue, ldap_user)
  — same as `ads-ego-training` and `ads-ego-multiday-pipeline`
- `/tmp/ego-openapi-v1/` cloned locally
- For multi-day mode: `train_pipeline.py` deployed at
  `$DRIVER_WORK_DIR/ego-pipeline/` on the driver server
- `<KP-dir>/research/round-N/plan.md` already produced by `ads-ar-planner`

---

## When to use / 何时使用

- You already have a round-N plan and want to launch the EGO training stage.
- A previous variant failed and you want to resubmit just that one.
- For single-job submission only (no research-round context), use
  `ads-ego-training` directly.

---

## Quick Start / 快速开始

```
/ads-ar-ego
```

The skill asks for:

1. Round directory (`<KP-dir>/research/round-N/`)
2. Version naming pattern (default: `<kr-kp-id>_round<N>_variant-<x>`)
3. Training days — for round 1 default 24, for `N >= 2` default to the prior
   round's value (with a prompt to shorten if metrics converged early)
4. Training cluster region (`us-east` → `hdfs://D2/...`, A100-80GiB / `sg`
   → `hdfs://R2/...`, A30) — for `N >= 2` default to prior round's cluster
5. Training countries / markets (`all` / `BR` / `non-BR` / specific country list)
   — for `N >= 2` default to prior round's filter
6. Resource config — defaults to the cluster preset for round 1, or the prior
   round's exact preset (including `worker_mem` / `batch_size` overrides) for
   `N >= 2`; override per variant if needed
7. Image / priority — for `N >= 2` default to prior `training.md` values
8. Language preference (`English` / `Chinese` / `Both`) — passed through from
   the orchestrator; controls headings/body of `training.md`

For round `N >= 2`, the skill first reads
`<KP-dir>/research/round-{N-1}/training.md` and surfaces a single
"carry-over diff" prompt — *"Same as round N-1 except `days` 7 → 5; OK?"* —
so you only confirm what changed.

It then creates one model version per variant, submits jobs (single or pipeline
mode based on days), monitors them, and writes
`<KP-dir>/research/round-N/training.md` with the job IDs and status. All
code links inside `training.md` use the durable KP-relative paths
(`codes/variant-a/<entry_file>`); never `/tmp/`.

After writing `training.md`, the skill retroactively patches each variant's
`**EGO version**` line in `plan.md` with the `model_version_id` and
`version_name` it just created.

Every submitted job is registered for validity in
`dev_mkplpaidads_discovery_ads.ad_algos_job_infos` so the EGO quota enforcer does
not kill it mid-round — this is **mandatory**, not best-effort. Multi-day runs set
the pipeline's `register_job_cmd` **and** `require_registration: true`, so a day
whose job fails to register is stopped and retried rather than left running
unregistered; single-job runs register right after launch and surface any
failure. See SKILL.md Step 2d.

> Driver registration tips (Step 2d): use **`--executor spark-sql`** (default
> `local[2]` master avoids the YARN queue; `hive` is usually absent), **ship the
> current `train_pipeline.py`** to the driver (an old copy ignores
> `register_job_cmd`), and **run one real test-insert before launching** so a
> broken registry doesn't churn through job submissions.

---

## Output / 产出

- `<KP-dir>/research/round-N/training.md`
- EGO job IDs and final checkpoints per variant
- (Multi-day) pipeline state files at
  `$DRIVER_WORK_DIR/ego-pipeline/<variant>_state.json` on the driver
- Memory updates in `<KP-dir>/memory/YYYY-MM-DD-<user>.md`

---

## References / 参考资料

- [SKILL.md](../../skills/common/ads-ar-ego/SKILL.md)
- [ads-ego-training guide](../team/03.content-algo/ads-ego-training.md) — single-job CLI, debugging, web UI
- [ads-ego-multiday-pipeline guide](../team/03.content-algo/ads-ego-multiday-pipeline.md) — multi-day chaining
