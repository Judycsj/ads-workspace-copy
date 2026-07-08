# Epic 进展报告（ads-okr-epic-report）使用指南

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-02 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-okr-epic-report.zh-CN.md)
> **Language**: [English](ads-okr-epic-report.md) | [中文](ads-okr-epic-report.zh-CN.md)

指定 KR 编号、KP 编号、Objective 编号或 epic-file.md 路径，从 Epic TD 文件（section 五）提取数据，生成结构化的项目进展报告并保存到文件。

四阶段管道：Phase 0（预检）→ Phase 1（`epic-report-meta.json` + `epic-report.md`）→ Phase 2（`kr-report.md`）→ Phase 3（`okr-report.md`），执行阶段由 target 粒度自动推导。

**唤醒词**：「epic report」、「项目报告」、「进展报告」、「ads-okr-epic-report」、「KP 报告」、「生成报告」、「团队进展」、「team progress」、「project report」

---

## Skill 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 主 skill 定义，包含统一报告格式（概览 + 各 KP 详细报告） |
| `agents/common/ads-okr-epic-report-phase1.md` | Phase 1 子任务执行器（agent 定义），含完整生成规则、数据提取规则、元数据字段说明、关键进展分类规则 |
| `scripts/extract_epic_data.py` | Phase 1 Step 3a：从 epic-file.md 机械提取元信息、VN Info、5.1-5.5 变更行 |
| `scripts/check_freshness.py` | Phase 0：新鲜度检测，输出结构化 JSON |
| `scripts/generate_epic_overview.py` | Phase 1 Step 4b：从 JSON 生成项目概览 markdown |
| `scripts/generate_kr_report.py` | Phase 2：从 JSON + epic-report.md 组装 kr-report |
| `scripts/generate_okr_report.py` | Phase 3：从 JSON 全量生成 okr-report.md + README.md |
| `epic-report-meta.json`（各 KP 目录） | 结构化 JSON 元数据，含中英文字段，供 Phase 2/3 脚本直接读取 |
| `epic-report.md`（各 KP 目录） | 中间产物：各 KP 的详细报告，生成在 epic-file 同级目录 |

---

## 前置依赖

| 依赖 | 类型 | 用途 |
|-----|------|------|
| Epic TD 文件 | 数据 | 读取指定 KR 下各 KP 的状态信息（section 五） |

---

## 使用场景

### 快速开始

```
# KP 粒度：仅处理指定的单个 KP（→ Phase 1）
/ads-okr-epic-report o1-kr5-kp3

# KR 粒度：处理该 KR 下所有 KP（→ Phase 1 + 2）
/ads-okr-epic-report o1-kr5

# O 粒度或省略：处理该 Objective 下所有 KP（→ Phase 0 + 1 + 3）
/ads-okr-epic-report o1
/ads-okr-epic-report

# 文件路径：直接指定 epic-file.md（→ Phase 1）
/ads-okr-epic-report docs/team/00.paid-ads-dev/10.trd-prd-td-list/2026q2/o1/kr5-kp3-202605061814/epic-file.md
```

执行阶段由 target 粒度自动推导，无需手动指定 `--phase`。

### 自定义时间范围

```
/ads-okr-epic-report --range 1m o4-kr3
```

生成报告，关键发现/问题取最近 1 个月。

### 参数说明

| 参数 | 可选值 | 默认值 | 说明 |
|------|--------|--------|------|
| `<target>` | KP 编号 / KR 编号 / O 编号 / 文件路径 / 省略 | 省略 = 全部 | Target 粒度决定执行阶段：KP → Phase 1，KR → Phase 1+2，O 或省略 → Phase 0+1+3 |
| `--range` | `1w`, `2w`, `1m`, `all` | `2w` | 过滤 5.3/5.4 中日期列的时间范围 |
| `--quarter` | 如 `2026q2` | （根据当前日期推算） | 季度目录名 |

### 输出文件

KP 级输出（各 KP 目录）：
```
{kp-dir}/epic-report-meta.json   （结构化 JSON）
{kp-dir}/epic-report.md          （详细报告）
```

KR 报告（双语）：
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/o{x}/kr{y}/{yyyy-mm-dd}-{range}.md
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/o{x}/kr{y}/{yyyy-mm-dd}-{range}.EN.md
```

KP List Index（每个 KR 的进度总览表同步更新）：
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/README.md
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/README.EN.md
```

OKR 汇总报告（双语）：
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/okr-report.md
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/okr-report.EN.md
```

OKR 列表（权威 O/KR 枚举源）：
```
docs/team/00.paid-ads-dev/05.okr-and-projects/{quarter}/okr-list.md
```

---

## 四阶段数据管道

执行阶段由 target 粒度自动推导：

| Target | 执行阶段 |
|--------|---------|
| KP（`o1-kr5-kp3` 或文件路径） | 仅 Phase 1 |
| KR（`o1-kr5`） | Phase 1 + 2 |
| O（`o1`）或省略 | Phase 0 + 1 + 3（跳过 Phase 2） |

```
Phase 0: 预检 — 新鲜度扫描 + 用户确认
Phase 1: epic-file.md → epic-report-meta.json + epic-report.md （逐 KP，并行 subagent）
Phase 2: epic-report-meta.json → kr-report.md + .EN.md         （Python 脚本）
Phase 3: epic-report-meta.json → okr-report.md + .EN.md        （Python 脚本，全量生成）
```

### Phase 0：预检（集中式新鲜度扫描）

- **脚本**：`scripts/check_freshness.py`
- 扫描所有目标 KP，检查 `epic-report-meta.json` 和 `epic-report.md` 相对于 `epic-file.md` 的新鲜度（默认 12 小时过期阈值，可通过 `--stale-days` 调整）
- 向用户展示新鲜度结果和更新策略选项，确认后继续
- 仅在 O 粒度或省略 target 时运行

### Phase 1：生成 epic-report-meta.json + epic-report.md（逐 KP，并行 subagent）

- **输入**：`epic-file.md`（各 KP 的 Epic TD 文件）
- **输出**：`epic-report-meta.json`（含中英文双语字段的结构化 JSON）+ `epic-report.md`（详细报告正文）
- **不读取**：`kr-report.md`、`okr-report.md`

每个 KP 生成两个文件：机器可读的 `epic-report-meta.json`，包含所有汇总字段（owner、contributor、step、vn_info、status 等）及 `_en` 后缀的英文翻译字段；以及 `epic-report.md` 完整的详细报告正文。

**并行分发**：所有 stale KP 均通过独立的 Agent subagent 并行处理，每个 KP 一个 subagent。每个 subagent 使用 agent 定义文件 `agents/common/ads-okr-epic-report-phase1.md`，在单条消息中统一发起。技能等待所有 subagent 完成后，汇总结果告知用户。

### Phase 2：生成 kr-report.md（Python 脚本）

- **输入**：`epic-report-meta.json` + `epic-report.md`（所有 KP）
- **输出**：`kr-report.md` + `.EN.md`（双语 KR 级报告）
- **脚本**：`scripts/generate_kr_report.py`

单次 Python 脚本调用，从各 KP 的 `epic-report-meta.json` 读取元数据生成 header（关键进展、进度总览表、KP 简报、风险汇总），然后拼接 header + 各 `epic-report.md` 为最终报告。自动生成中文和英文两个版本。README 更新由 Phase 3 统一负责。

### Phase 3：生成 okr-report.md（Python 脚本，全量生成）

- **输入**：`epic-report-meta.json`（所有 KP）+ `okr-list.md`（权威 O/KR 枚举源）
- **输出**：`okr-report.md` + `.EN.md` + `README.md` + `README.EN.md`
- **脚本**：`scripts/generate_okr_report.py`
- **不读取**：`kr-report.md` 内容（仅用于生成链接）

Phase 3 执行全量重新生成。从 `okr-list.md` 枚举所有 Objective 和 KR，从各 KP 的 `epic-report-meta.json` 读取内容，生成完整的 `okr-report.md` 和 `okr-report.EN.md`。包含备份/恢复安全机制：生成前将已有文件备份为 `.bak`，失败时恢复，成功时删除备份。

---

## 增量生成与断点续传

Phase 1 采用逐 KP 增量生成详细报告的方式，避免一次性写入大文件导致 subagent 卡住。

### 工作原理

1. 每个 KP 的输出独立写入其 epic-file 同级目录的 `epic-report-meta.json` + `epic-report.md`
2. 生成前对比 `epic-report-meta.json` 和 `epic-report.md` 与 `epic-file.md` 的文件修改时间（默认 12 小时过期阈值）
3. 若两个输出文件都比 `epic-file.md` 更新（数据源未变化），则**跳过**该 KP
4. 新鲜度检查在 Phase 0 中通过 `check_freshness.py` 集中执行（O 粒度 target）

### 中断恢复

若生成过程中断（如 7 个 KP 中完成了 3 个）：
1. 重新调用相同命令
2. 已完成的 KP 自动跳过（其输出文件已比 `epic-file.md` 新）
3. 继续生成剩余 KP

若需强制重新生成某个 KP，可 `touch` 其 `epic-file.md` 更新 mtime，然后重新调用命令。

---

## 相关 Skill

| Skill | 用途 |
|-------|------|
| `/ads-okr-epic-td` | Epic TD 文档生成与审查 |
| `/ads-okr-planner` | OKR KR→KP 规划与质量审查 |
| `/ads-okr-meeting-doc` | 会议文档起草、会后整理与回写 |
