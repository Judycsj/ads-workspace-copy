# Ads EGO 配额保护任务提交使用指南/Ads EGO Quota-Gated Job Submission Guide
> **Contributors**: chenjiawei, chenglong.cao ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ego-job-quota-submit.md)
> **Language**: [English](ads-ego-job-quota-submit.md) | [中文](ads-ego-job-quota-submit.zh-CN.md)

Submit one `tmp_` Product Ads EGO training job only after projected quota
validation, then record the submitted `job_id` in a fixed existing Spark SQL
table. This skill rejects planned `exp_` and `prd_` versions.

**Trigger keywords**: "quota gate", "safe submit", "wait for quota", "EGO job quota", "等配额", "配额可用时提交", "排队等配额提交", "避免超配"

## 加载/Loading

As a common skill, this skill participates in project-local auto-load when
opening `ads-workspace`. To refresh the project mirror after local changes, run:

```bash
bash scripts/sync-project-skills.sh
```

For global/manual installation, run:

```bash
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install ads-ego-job-quota-submit
```

The installer reads `skill_dependencies` and automatically installs
`sra-ego-job-submit`: it first reuses a local installed skill, then local
sra-toolkit checkouts, and finally the default sra-toolkit Git repository.

## 使用场景/Scenarios

### 场景 1：等配额后提交/Scenario 1: Submit After Quota Is Available

```text
Use ads-ego-job-quota-submit to submit one job based on job 46290718. Create a new version first.
```

The AI should:

1. Resolve source job parameters and planned model/version/region.
2. Create or resolve the requested new version.
3. Run quota gate for exactly one planned job.
4. Submit through `sra-ego-job-submit` only if quota passes.
5. Append the returned `job_id` to
   `dev_mkplpaidads_discovery_ads.ad_algos_job_infos`.

### 场景 2：只检查 quota/Scenario 2: Check Quota Without Submitting

Use `--check-once` only when the user explicitly asks to inspect quota:

```bash
uv run scripts/quota_gate.py \
  --user-email chenglong.cao@shopee.com \
  --planned-model-name BiddingEnvAutoModels \
  --planned-version-name tmp_example_sg \
  --planned-region sg \
  --check-once
```

The check reserves capacity for one planned job. To submit another job, run the
full workflow again.

`tmp_sg_*` and `tmp_us_*` are independent clusters. Count only the cluster where
the planned job will be submitted; SG and US are not added into one shared
limit.

Version names must match `tmp_{r_name}_{region}`, where `region` is one of
`sg/th/vn/tw/id/ph/br/my`. The EGO cluster does not need to appear in the
version name. Count unique tmp bases after removing that region suffix; for
example, `tmp_xxxx_id` and `tmp_xxxx_ph` count as one task.

The skill also forces submission priority. Ignore user-provided priority and
pass the `enforced_job_priority` printed by `quota_gate.py`:

```text
projected tmp count <= 5: job_priority=4
5 < projected tmp count <= 10: job_priority=2
projected tmp count > 10: keep polling until count <= 10
```

### 场景 3：写入已提交 job_id/Scenario 3: Persist A Submitted Job ID

After `sra-ego-job-submit` returns `job_id`, append it to the fixed table:

```bash
uv run scripts/write_job_id.py \
  --job-id 46290000 \
  --metadata-json '{"source_job_id":"46290718"}'
```

The script submits `INSERT INTO TABLE` through Data Studio Spark SQL and does
not require local `hadoop` or `hdfs`.

To register a job from a host that has a native Hadoop SQL client but no
datasuite login (e.g. an EGO driver), copy the script there and add
**`--executor spark-sql`** (preferred). Its default `--spark-master local[2]`
runs the 1-row insert in local mode, so it needs no YARN queue grant (a bare
YARN `spark-sql` is denied on the default `regular` queue). `--executor hive`
usually fails on drivers (`hive` not installed) — check `which spark-sql hive`.
This is how `ads-ego-multiday-pipeline` registers each day's job for validity
from the driver.

## 安全规则/Safety Rules

- Never call `train_job.py create` when quota gate exits non-zero.
- Submit one job per workflow run. For multiple jobs, repeat the full workflow
  after each `job_id` is recorded.
- Always write to the fixed existing table; do not create a new table per run
  or per job.
- Do not whitelist, kill, or cancel existing jobs unless the user explicitly
  asks for that action.
- If job creation succeeds but Spark SQL insert fails, do not rollback or kill
  the created EGO job.

## 相关文件/Related Files

| File | Purpose |
| --- | --- |
| [SKILL.md](../../skills/common/ads-ego-job-quota-submit/SKILL.md) | Skill workflow and trigger rules |
| [DESIGN.md](../../skills/common/ads-ego-job-quota-submit/DESIGN.md) | Design rationale and known limits |
| [quota_gate.py](../../skills/common/ads-ego-job-quota-submit/scripts/quota_gate.py) | Active plus planned quota validation |
| [write_job_id.py](../../skills/common/ads-ego-job-quota-submit/scripts/write_job_id.py) | Spark SQL job ID persistence |
| [test_quota_gate.py](../../skills/common/ads-ego-job-quota-submit/tests/test_quota_gate.py) | Quota gate unit tests |
| [test_write_job_id.py](../../skills/common/ads-ego-job-quota-submit/tests/test_write_job_id.py) | Write job ID unit tests |
