# Ads EGO 配额保护任务提交使用指南/Ads EGO Quota-Gated Job Submission Guide
> **Contributors**: chenjiawei, chenglong.cao ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ego-job-quota-submit.zh-CN.md)
> **Language**: [English](ads-ego-job-quota-submit.md) | [中文](ads-ego-job-quota-submit.zh-CN.md)

在提交 1 个 `tmp_` Product Ads EGO 训练任务前先校验 projected quota
（当前 active jobs + 本次 planned job），通过后再提交任务，并把返回的
`job_id` 写入固定现有 Spark SQL 表。本 skill 会拒绝 planned `exp_` 和
`prd_` 版本。

**触发关键词**: "quota gate"、"safe submit"、"wait for quota"、"EGO job quota"、"等配额"、"配额可用时提交"、"排队等配额提交"、"避免超配"

## 加载/Loading

作为 common skill，本 skill 会参与打开 `ads-workspace` 时的项目级自动加载。
本地改动后如需刷新 project mirror，执行：

```bash
bash scripts/sync-project-skills.sh
```

如果需要全局/手动安装，执行：

```bash
uv run skills/common/ads-workspace-skill-install/scripts/install_skill.py install ads-ego-job-quota-submit
```

安装脚本会读取 `skill_dependencies` 并自动安装 `sra-ego-job-submit`：
先复用本机已安装的 skill，再查找本地 sra-toolkit checkout，最后从默认
sra-toolkit Git 仓库拉取。

## 使用场景/Scenarios

### 场景 1：等配额后提交/Scenario 1: Submit After Quota Is Available

```text
用 ads-ego-job-quota-submit，参考 46290718 提交 1 个任务，先新建 version。
```

AI 应该：

1. 解析源任务参数以及 planned model/version/region。
2. 按需创建或解析本次计划使用的新 version。
3. 对 1 个 planned job 运行 quota gate。
4. 只有 quota gate 通过时才通过 `sra-ego-job-submit` 提交。
5. 把返回的 `job_id` 追加写入
   `dev_mkplpaidads_discovery_ads.ad_algos_job_infos`。

### 场景 2：只检查 quota/Scenario 2: Check Quota Without Submitting

只有用户明确要求“只检查”时才使用 `--check-once`：

```bash
uv run scripts/quota_gate.py \
  --user-email chenglong.cao@shopee.com \
  --planned-model-name BiddingEnvAutoModels \
  --planned-version-name tmp_example_sg \
  --planned-region sg \
  --check-once
```

检查会固定为 1 个 planned job 预留容量。要提交第二个任务，需要重新跑完整
workflow。

`tmp_sg_*` 和 `tmp_us_*` 是独立集群。只统计本次 planned job 要提交到的
cluster；SG 和 US 不合并成一个共享上限。

version 命名必须符合 `tmp_{r_name}_{region}`，其中 `region` 是
`sg/th/vn/tw/id/ph/br/my` 之一。version 名里不需要包含 EGO 集群。计数时
会去掉末尾业务 region 后缀后按 tmp base 去重，例如 `tmp_xxxx_id` 和
`tmp_xxxx_ph` 只算 1 个任务。

本 skill 也会强制提交优先级。忽略用户传入的 priority，只使用
`quota_gate.py` 打印的 `enforced_job_priority`：

```text
projected tmp count <= 5: job_priority=4
5 < projected tmp count <= 10: job_priority=2
projected tmp count > 10: 继续轮询等待，直到 count <= 10
```

### 场景 3：写入已提交 job_id/Scenario 3: Persist A Submitted Job ID

`sra-ego-job-submit` 返回 `job_id` 后，追加写入固定表：

```bash
uv run scripts/write_job_id.py \
  --job-id 46290000 \
  --metadata-json '{"source_job_id":"46290718"}'
```

该脚本通过 Data Studio Spark SQL 提交 `INSERT INTO TABLE`，不依赖本机
`hadoop` 或 `hdfs` 命令。

若要在有原生 Hadoop SQL 客户端但没有 datasuite 登录的机器上（如 EGO driver）
登记 job，把脚本复制过去并加上 **`--executor spark-sql`**（推荐）。其默认
`--spark-master local[2]` 以 local 模式跑这条单行 insert，无需 YARN queue 权限
（裸 YARN `spark-sql` 会因默认 `regular` queue 无权限而被拒）。`--executor hive`
在 driver 上通常失败（未安装 `hive`）——先用 `which spark-sql hive` 确认。
`ads-ego-multiday-pipeline` 正是借此在 driver 上登记每天的 job 有效性。

## 安全规则/Safety Rules

- quota gate 非 0 退出时，禁止调用 `train_job.py create`。
- 本 skill 每次 workflow 只提交 1 个任务；多个任务要在每个 `job_id`
  记录完成后重新跑下一次完整 workflow。
- 始终写入固定现有表，不要每次运行或每个任务创建新表。
- 不要自动 whitelist、kill 或 cancel 现有任务，除非用户明确要求。
- 如果任务创建成功但 Spark SQL 写表失败，不要 rollback 或 kill 已创建的
  EGO job。

## 相关文件/Related Files

| 文件 | 用途 |
| --- | --- |
| [SKILL.md](../../skills/common/ads-ego-job-quota-submit/SKILL.md) | Skill 工作流与触发规则 |
| [DESIGN.md](../../skills/common/ads-ego-job-quota-submit/DESIGN.md) | 设计说明与已知限制 |
| [quota_gate.py](../../skills/common/ads-ego-job-quota-submit/scripts/quota_gate.py) | active + planned 配额校验 |
| [write_job_id.py](../../skills/common/ads-ego-job-quota-submit/scripts/write_job_id.py) | Spark SQL job_id 写入 |
| [test_quota_gate.py](../../skills/common/ads-ego-job-quota-submit/tests/test_quota_gate.py) | 配额校验单元测试 |
| [test_write_job_id.py](../../skills/common/ads-ego-job-quota-submit/tests/test_write_job_id.py) | job_id 写入单元测试 |
