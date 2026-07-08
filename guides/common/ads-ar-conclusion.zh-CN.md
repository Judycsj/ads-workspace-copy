# ads-ar-conclusion 技能使用指南 / ads-ar-conclusion Skill Guide

> **Contributors**: chenjiawei ｜ **最后更新**：2026-05-21 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ar-conclusion.zh-CN.md)

`ads-ar-conclusion` 是 `ads-autoresearch` 的第 3 阶段。在某轮训练完成后，
从 EGO 拉取离线指标，按用户确认的目标指标（如 `shop_broad_cr`、`pCTR`、`shop_ctr`）
汇总，写入 `metrics.md` 并追加到 KP 的记忆文件。

---

## 前提条件 / Prerequisites

- `ads-ar-ego` 已生成 `<KP-dir>/research/round-N/training.md`
- 所有变体的 job（或 multiday pipeline）训练已结束
- `~/.config/sra/credentials.json` 中的 `ego` 配置块（用于 `get_job_metrics.sh`）
- 已克隆 `/tmp/ego-openapi-v1/`

---

## 何时使用 / When to use

- 本轮训练已完成，需要规范化的指标汇总文件
- 需要在 `<KP-dir>/MEMORY.md` 中追加本轮结果
- 同步 `epic-file.md` section 5 请单独使用 `/ads-okr-memory-sync`

---

## 快速开始 / Quick Start

```
/ads-ar-conclusion
```

技能会依次询问：

1. Round 目录（`<KP-dir>/research/round-N/`）
2. 目标指标 —— round 1 全新询问（如 `shop_broad_cr`、`pCTR`、`shop_ctr`，
   必须与模型代码中定义的 head 一致）；`N >= 2` 时会从上一轮 `metrics.md`
   的 "Target Metrics" 行读取并询问是否沿用 / 更新。
3. 对比基线 `job_id`（默认使用 `plan.md` 中记录的 job_id）
4. 语言偏好（`English` / `Chinese` / `Both`） —— 由编排器透传，控制
   `metrics.md` 的标题与正文语言。

然后拉取基线和各变体的 eval-round AUC，计算 Δ vs baseline，挑选 winner，
并写入 `<KP-dir>/research/round-N/metrics.md`。文件中 `plan.md`、
`training.md`、`codes/...` 等同级链接均使用 KP 相对路径，不会出现 `/tmp/`。

---

## 产出 / Output

- `<KP-dir>/research/round-N/metrics.md`
- `<KP-dir>/MEMORY.md` 中新增一行
- `<KP-dir>/memory/YYYY-MM-DD-<user>.md` 中新增一条 "Key Decisions & Findings"

---

## 注意事项 / Notes

- 不会自动修改 `epic-file.md`。需要刷新第 5 节（KP Execution & Status）请运行
  `/ads-okr-memory-sync`。
- 失败 / 部分完成的变体会如实记录，不会被静默丢弃。
- 在线 AB 分析请使用 `/ads-experiment-analyze`；TRD 撰写请使用
  `/anthropic-skills:model-trd-writer`。
- 若识别到 winner，技能会询问是否在该变体上启动一次更长的后续训练 ——
  你需要提供训练起止日期、cold/warm 起步、warm 时的 checkpoint 或 job ID、
  以及 `filter_nn` 取值，随后由 `/ads-ego-multiday-pipeline` 接手提交。

---

## 参考资料 / References

- [SKILL.md](../../skills/common/ads-ar-conclusion/SKILL.md)
- [ads-ego-training 指南](ads-ego-training.zh-CN.md) —— `get_job_metrics.sh` 语义
- [ads-ego-multiday-pipeline 指南](ads-ego-multiday-pipeline.zh-CN.md) —— `state.json` 历史格式
