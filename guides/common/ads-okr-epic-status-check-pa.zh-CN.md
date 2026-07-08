# Product Ads Epic 状态检查（ads-okr-epic-status-check-pa）使用指南

> **语言**：[English](ads-okr-epic-status-check-pa.md) | [中文](ads-okr-epic-status-check-pa.zh-CN.md)

检查 Product Ads epic-file section 5 的执行期状态是否完整、是否新鲜、实验指标是否补齐，以及里程碑日期顺序是否合理。本 skill 名称里的 `pa` 表示 Product Ads。

**唤醒词**：「ads-okr-epic-status-check-pa」、「Product Ads epic status check」、「检查 epic 状态」、「检查 epic file 完整性」、「PA epic checker」

---

## Skill 文件说明

| 文件 | 说明 |
| --- | --- |
| `SKILL.md` | 主流程和边界 |
| `references/check-contract.md` | 完整检查规则和输出契约 |
| `scripts/epic_status_check_pa.py` | 可测试的 checker 实现 |

---

## 使用方式

检查单个 epic 文件：

```text
/ads-okr-epic-status-check-pa docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1/kr4-kp6-202605061800/epic-file.md
```

检查单个 KP：

```text
/ads-okr-epic-status-check-pa O1-KR4-KP6
```

检查一个目录：

```text
/ads-okr-epic-status-check-pa docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1
```

指定新鲜度窗口：

```text
/ads-okr-epic-status-check-pa --range 7d O1-KR4-KP6
```

直接运行脚本：

```bash
uv run skills/common/ads-okr-epic-status-check-pa/scripts/epic_status_check_pa.py --range 7d O1-KR4-KP6
```

---

## 检查内容

| 检查项 | 会发现的问题 |
| --- | --- |
| 四要素检查 | 非 Done KA 的 `5.3 KA 进度`、`5.4 风险`、`5.5 下一步` 缺失或过期；`5.2 实验` 仅在 UAT/在线实验已启动，或 5.2 有真实实验/全量 link、日期、数据时检查；问题文本会带 section 编号 |
| 实验检查 | 对 5.1 中明确为在线实验的 KA，或 5.2 已填写实验平台 link 的 KA：UAT 已启动超过 2 天，但实验 link 或反推 bucket 对应的核心指标缺失；指标可写在该 KA 的实验行或 5.2 KA 补充段落/表格 |
| 里程碑检查 | Owner / ETA / Effort 缺失，阶段日期无效，违反 `TD <= Dev <= Int <= UAT <= Done`，ETA 已到但阶段日期全空，或已有 5.2 / 5.3 / 5.5 推进记录但 5.1 阶段日期未同步 |

Traffic 和 Item 指标合同见 `references/check-contract.md`。

---

## 输出格式

输出按 KR 分组：

```md
## Epic Status Check Issues

### O1-KR4

| KP | 项目名 | PIC | 检查项 | 问题 | 证据 | 建议补充 |
| --- | --- | --- | --- | --- | --- | --- |
| KP6 | PCOC Calibration | quan.zheng | 四要素检查 | 5.3 KA 进度 过去 7 天无更新 | 2026-05-13 | 补充最近 7 天内的 5.3 KA 进度 更新 |
```

`ads-okr-meeting-doc --draft` 可以直接把这个表格作为 Topic context，并按一个 KR 一个 Topic 汇总。

---

## 边界

- 只读，不修改 epic-file。
- 不判断实验 uplift、显著性或是否可以推全。
- 根据同步实验数据反推 bucket type；出价类实验默认 Item，其他实验默认 Traffic，不输出 `bucket type 缺失`。
- Epic TD 设计质量审查请用 `ads-okr-epic-review`。
- 项目进展报告请用 `ads-okr-epic-report`。
