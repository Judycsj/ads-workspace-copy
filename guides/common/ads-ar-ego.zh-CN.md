# ads-ar-ego 技能使用指南 / ads-ar-ego Skill Guide

> **Contributors**: chenjiawei ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ar-ego.zh-CN.md)

`ads-ar-ego` 是 `ads-autoresearch` 的第 2 阶段。读取 planner 产出的 round 目录，
将每个变体提交到 EGO —— 短训用单 job、完整消融用 multiday pipeline —— 并监控、重试失败。

工作流第 0 步会主动 `find` 并 `Read` `ads-ego-training/references/` 下的 config / debug
参考文档，以及 `ads-ego-multiday-pipeline/scripts/train_pipeline.py`，确保每次使用的
CLI flag、YAML schema 和失败处理流程都来自源文件，而不是凭记忆。

---

## 前提条件 / Prerequisites

- `~/.config/sra/credentials.json` 中的 `ego` 配置块（token、driver_host、
  driver_login_cmd、driver_work_dir、hdfs_dev_path、spark_queue、ldap_user），
  与 `ads-ego-training` 和 `ads-ego-multiday-pipeline` 共用
- 已克隆 `/tmp/ego-openapi-v1/`
- 多日训练模式：driver 上 `$DRIVER_WORK_DIR/ego-pipeline/` 已部署 `train_pipeline.py`
- `<KP-dir>/research/round-N/plan.md` 已由 `ads-ar-planner` 生成

---

## 何时使用 / When to use

- 已有 round-N 的 plan，需要启动 EGO 训练阶段
- 某个变体失败，需要单独重新提交
- 仅需提交单 job 训练（与调研轮无关）请直接使用 `ads-ego-training`

---

## 快速开始 / Quick Start

```
/ads-ar-ego
```

技能会依次询问：

1. Round 目录（`<KP-dir>/research/round-N/`）
2. 版本命名规则（默认 `<kr-kp-id>_round<N>_variant-<x>`）
3. 训练天数 —— round 1 默认 24，`N >= 2` 默认沿用上一轮的天数（若指标早早
   收敛会建议你缩短）
4. 训练集群区域（`us-east` → `hdfs://D2/...`、A100-80GiB / `sg` →
   `hdfs://R2/...`、A30） —— `N >= 2` 默认沿用上一轮的集群
5. 训练国家 / 市场（`all` / `BR` / `non-BR` / 指定国家列表） ——
   `N >= 2` 默认沿用上一轮的过滤
6. 资源配置 —— round 1 默认采用集群预设；`N >= 2` 默认沿用上一轮的
   完整预设（包括 `worker_mem` / `batch_size` 等覆盖项），可按变体覆盖
7. 镜像 / 优先级 —— `N >= 2` 默认沿用上一轮 `training.md` 的值
8. 语言偏好（`English` / `Chinese` / `Both`）—— 由编排器透传，控制
   `training.md` 的标题与正文语言

`N >= 2` 时，技能会先 `Read` `<KP-dir>/research/round-{N-1}/training.md`，
然后只针对差异（如 *"Same as round N-1 except `days` 7 → 5; OK?"*）
询问你一次。

随后为每个变体新建 model version，按天数选择单 job 或 pipeline 模式提交，
监控进度并写入 `<KP-dir>/research/round-N/training.md`。文件中所有代码
链接都使用 KP 相对路径（`codes/variant-a/<entry_file>`），不会出现 `/tmp/`。

写完 `training.md` 后，技能会回填 `plan.md` 中每个变体的
`**EGO version**` 行（`model_version_id` + `version_name`）。

每个提交的 job 都**必须**在 `dev_mkplpaidads_discovery_ads.ad_algos_job_infos`
中登记有效性，避免被 EGO 配额执行器中途 kill——这是强制要求，并非尽力而为。
多日训练通过流水线的 `register_job_cmd` 搭配 `require_registration: true`，
某天的 job 登记失败时会被停止并重试，而不是放任未登记的 job 继续训练；
单 job 训练则在提交后立即登记并暴露失败。详见 SKILL.md 第 2d 步。

> Driver 登记要点（第 2d 步）：用 **`--executor spark-sql`**（默认 `local[2]`
> master 绕开 YARN queue；driver 上通常无 `hive`）；把**当前版本的
> `train_pipeline.py`** 传到 driver（旧版本会忽略 `register_job_cmd`）；
> 启动前先跑一次**真实 test-insert**，避免登记失效导致反复提交-停止的空转。

---

## 产出 / Output

- `<KP-dir>/research/round-N/training.md`
- 每个变体的 EGO job ID 与最终 checkpoint
- 多日模式下，driver 上的 `$DRIVER_WORK_DIR/ego-pipeline/<variant>_state.json`
- `<KP-dir>/memory/YYYY-MM-DD-<user>.md` 的记忆更新

---

## 参考资料 / References

- [SKILL.md](../../skills/common/ads-ar-ego/SKILL.md)
- [ads-ego-training 指南](../team/03.content-algo/ads-ego-training.zh-CN.md) —— 单 job CLI、调试、Web UI
- [ads-ego-multiday-pipeline 指南](../team/03.content-algo/ads-ego-multiday-pipeline.zh-CN.md) —— 多日训练
