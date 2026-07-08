# ads-epic-experiment-summary

从 Epic file 中读取正在进行的实验，生成独立 Markdown 实验效果汇总。

## 快速开始

```bash
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py O1-KR1
```

默认输出：

```text
docs/personal/<user>/ads-epic-experiment-summary/<date>-<scope>-experiment-summary.md
```

## 入选规则

KA 同时满足以下条件才会进入报告：

- `5.1` 的 `UAT` 非空。
- `5.1` 的 `Done` 为空或 `-`。
- `5.2` 同 KA 的 `实验链接` 非空。

## 常用参数

```bash
# 指定统计窗口
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --date-range 2026-05-20:2026-05-24 O1-KR1

# 汇总整个 Objective
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --scope objective O1

# 使用 fixture/provider JSON
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --ab-data-dir tmp/ads-epic-summary-fixture O1-KR1

# 可选回写 Epic 5.2
uv run skills/common/ads-epic-experiment-summary/scripts/epic_experiment_summary.py \
  --write-back-5-2 --ab-data-dir tmp/ads-epic-summary-fixture path/to/epic-file.md
```

## 风险规则

只判断 `rev` 和 `advv`：当实验流量 `>= 10%`，且 relative uplift 劣化超过 `2 * rollout guardrail threshold` 时，报告会提示需要周知的大盘风险。
