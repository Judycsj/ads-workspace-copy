# ads-ar-planner 技能使用指南 / ads-ar-planner Skill Guide

> **Contributors**: chenjiawei ｜ **最后更新**：2026-05-21 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-ar-planner.zh-CN.md)

`ads-ar-planner` 是 `ads-autoresearch` 的第 1 阶段。给定 OKR/KP、基线模型和研究方向后，
生成 2-3 份消融实验变体代码，并产出本轮的 `plan.md`。

---

## 前提条件 / Prerequisites

- `~/.config/sra/credentials.json` 中的 `ego` 配置块（用于 `ads-ego-training` 下载基线代码）
- 已存在带 `epic-file.md` 的 KP 目录，否则先运行 `/ads-okr-epic-td`
- 在线检索模式需要 `WebSearch` / `WebFetch` 工具

---

## 何时使用 / When to use

- 你想新建一轮研究，但只需要规划阶段的产出
- 训练阶段稍后再做（或交由同事执行）
- 想先 peer-review plan 再启动 EGO 训练

完整 plan→train→conclude 流程请使用 `/ads-autoresearch`。

---

## 快速开始 / Quick Start

```
/ads-ar-planner
```

**从 `ads-autoresearch` 调用时**，基线、研究方向、补充材料、上一轮路径、
语言偏好都已经在编排器的握手阶段确认过 —— planner 只负责出方案。

**独立调用时**，技能会依次询问：

1. KP 目录路径
2. 基线模型 —— round 1 要 `model_id + version_id` 或 `job_id`；
   `N >= 2` 默认沿用上一轮 winner 的 `model_version_id`，可覆盖。
3. 研究方向 —— 先从 `epic-file.md` 2.5 / KA 描述 / 5.5 中提取并与你确认。
4. 补充材料 —— 论文（PDF） / arxiv 链接 / 在线搜索关键词 / 内部文档。
5. 语言偏好 —— `English` / `Chinese` / `Both`（单文件双语交错，默认）。

然后将基线代码下载到 `/tmp/ads-ar/round-N/baseline/`，在
`/tmp/ads-ar/round-N/variant-<x>/` 中起草 2-3 份变体，并将每个变体的入口
文件 + diff 持久化到 `<KP-dir>/research/round-N/codes/`，最后写入
`<KP-dir>/research/round-N/plan.md`。plan 中所有代码链接都是 KP 相对路径
（`codes/variant-a/<entry_file>`），不会出现 `/tmp/`。

---

## 产出 / Output

**持久化（KP 目录内，`plan.md` 实际链接到的路径）：**
- `<KP-dir>/research/round-N/plan.md`
- `<KP-dir>/research/round-N/codes/baseline/<entry_file>`
- `<KP-dir>/research/round-N/codes/variant-<x>/<entry_file>` 每个变体一份
- `<KP-dir>/research/round-N/codes/variant-<x>.diff` 每个变体一份
- `<KP-dir>/memory/YYYY-MM-DD-<user>.md` 追加一条记忆

**临时工作副本（仅供 `create_model_version.sh --model_path` 使用）：**
- `/tmp/ads-ar/round-N/baseline/`、`variant-{a,b,c}/`、`variant-<x>.diff`
  —— 不会出现在任何提交的文档中。

---

## 参考资料 / References

- [SKILL.md](../../skills/common/ads-ar-planner/SKILL.md)
- [ads-ego-training 指南](ads-ego-training.zh-CN.md) —— 基线代码下载方法
- [ads-okr-epic-td](../../skills/common/ads-okr-epic-td/SKILL.md) —— KP 目录创建
