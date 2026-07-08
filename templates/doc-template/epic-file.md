<!-- Template version: 1.4 | Updated: 2026-06-17 -->

# 202xQx-Ox-KRx-KPx-epicTitle

> **Language**: [English](epic-file.EN.md) | [中文](epic-file.md)

---

<!-- 为了提高文档效率，文档使用中英文均可，鼓励用你更熟悉语言写作。 -->
<!-- To improve documentation efficiency, you can use either Chinese or English. You are encouraged to write in the language you are more familiar with. -->

## KP 元信息/KP Metadata(kr-file.md同步覆盖,此处勿改)
<!-- 此处字段由 kr-file.md 同步覆盖，请在 kr-file.md 中修改。 -->

- **KP ID**：${kp_id}, [epic-file](${epic_file_path}), [gitlab](${gitlab_url})
- **KP Title**：${来源于输入给 agent 的 prompt}
- **KP Type**：${greenfield | problem-driven | incremental | refactor}
- **Owner**：${KP 负责人}
- **Why Do**：${来源于输入给 agent 的 prompt}
- **交付目标/Deliverable**：【收益】${量化的业务指标目标，如 rev +5%、达标率 +1pp、延迟 -30%；收益是努力方向，不保证 100% 达成}；【执行】${确定性交付物，如功能开发、框架建设、专题分析、模型复现；只要认真执行即可 100% 完成}
- **Phase**：Waiting
<!-- Phase 由 memory-sync 根据 5.1 表 KA 进度自动更新，也可手动修改（如改为 Close 关闭 epic） -->

---

## 一、项目背景和目标/Project Background and Objectives

### 1.1 KP 相关 KB Summary

${根据 KP 引子调用 /ads-knowledge-qa 获取相关 kb 信息}

### 1.2 背景/Background

${描述项目背景，按 KP Type 侧重不同，详见 specs/common/okr/05-ads-okr-epic-td-spec.md「KP Type 各章节侧重点」}

### 1.3 项目验收标准/Project Acceptance Criteria

${分两类列出验收标准：}

**收益指标**（量化业务目标，对应交付目标【收益】部分）：

* ${如 rev +1.5%（绝对值 +10w usd/day），达标率 +2pp}

**交付验收**（确定性交付物完成标准，对应交付目标【执行】部分）：

* ${如 完成 XX 功能开发并上线，产出 XX 分析报告}

<!-- 注意：rev/advv 指标必须包含绝对值 -->
<!-- Note: rev/advv metrics must include absolute values -->

### 1.4 非目标 scope（可选）/Non-Goals (Optional)

${明确本次不做的事情，避免范围蔓延}

## 二、分析与方案推导/Analysis & Solution Derivation

### 2.1 分析思路/Analysis Approach

${按 KP Type 侧重不同，详见 specs/common/okr/05-ads-okr-epic-td-spec.md「KP Type 各章节侧重点」}

### 2.2 方案思路（粗版）/Solution Ideas (Draft)

${基于分析思路，初步构思解决问题或达成目标的方案方向：}

- 整体方案思路有哪些方向？
- 每个方向的预期效果如何？
- 需要通过数据分析验证哪些假设？

### 2.3 分析方案设计/Analysis Implementation

${将 2.1 的分析思路落地为具体可执行的分析方案，验证 2.2 粗版方案思路的可行性，到代码实现层面：}

- 需要查询哪些 hive 表？具体 SQL 是什么？
- 是否需要编写分析脚本？逻辑是什么？
- 分析结果如何验证 2.2 中的假设？

### 2.4 分析结论/Analysis Conclusion

${2.3 分析方案执行后的结论：}

- 分析发现了什么？
- 哪些假设被验证/推翻？
- 对 2.2 粗版方案思路有什么修正？

### 2.5 方案思路（终版）/Solution Ideas (Final)

${基于 2.4 分析结论，修正 2.2 粗版方案思路，确定最终技术方案方向，再从方案推理拆解出可落地的执行节奏和可 check 的关键里程碑（KA）：}

- 基于分析结论，修正后的方案方向有哪些？
- 各方案方向的预期效果如何？多方案如何取舍和排列优先级？
- 从确定的方案出发，按什么节奏落地？在哪些节点可以验证和 check？（→ KA 列表）

## 三、实现方案和落地实施【重点】/Solution Design and Implementation [Key Section]

### 3.1 系统现状梳理（可选）/Current State Analysis (Optional)

${当前系统链路、代码路径、已有能力，方案的边界和约束}

### 3.2 方案设计/Solution Design

${方案设计，按 KP Type 侧重不同，详见 specs/common/okr/05-ads-okr-epic-td-spec.md「KP Type 各章节侧重点」}

<!-- 可以在此总结所有 KA 的方案，也可以每个 KA 单独在子页面中展开。若使用子页面，此节留空。 -->
<!-- You can summarize all KA solutions here, or break down each KA's solution into its own sub-page. -->

### 3.3 示例（可选）/Worked Example (Optional)

${用具体数值示例说明方案行为，帮助 reviewer 快速理解}

### 3.4 验证方案/Validation Plan

${离线/在线验证方法、核心指标、成功标准、回滚标准}

## 四、TRD 文档列表（可选）/TRD List (Optional)

${各 KA 对应的 TRD 文档链接，TD review 通过后填入}

| KA  | TRD 链接 |
| --- | ------ |
| KA1 | ${url} |

## 五、KP 执行与状态/KP Execution & Status

<!-- 以下章节在项目执行阶段维护，Epic 生成时只需保留空骨架。 -->
<!-- Maintained during execution. Keep empty skeletons when generating the Epic. -->

### 5.1 里程碑进度/Milestone Progress

<!-- KA 描述须带 Phase 前缀：[TD]/[Dev]/[Int]/[UAT]，不写默认 [Dev]。详见 specs/common/okr/03-core-concepts.md -->

| ID    | KA  | 描述              | Owner    | ETA    | Effort    | Start    | Done    |
| ----- | --- | --------------- | -------- | ------ | --------- | -------- | ------- |
| 5.1.1 | KA1 | ${[Phase]描述}    | ${owner} | ${ETA} | ${effort} | ${Start} | ${Done} |
| 5.1.2 | KA2 | ${[Phase]描述}    | ${owner} | ${ETA} | ${effort} | ${Start} | ${Done} |

### 5.2 实验与全量/Experiments & Rollouts

**实验信息/Experiment Info：**

| ID    | 新增时间     | KA  | 实验链接         | 实验区域 | 开始日期    | 最新修改日期  | 最新实验数据                          | 实验分析 Doc       | 状态              | 全量日期    |
| ----- | -------- | --- | ------------ | ---- | ------- | ------- | ------------------------------- | --------------- | --------------- | ------- |
| 5.2.1 | ${YYYY-MM-DD} | KA1 | ${AB实验平台URL} | ${BR} | ${YYYY-MM-DD} | ${YYYY-MM-DD} | ${rev +x%, advv +y%（YYYY-MM-DD~YYYY-MM-DD）} | ${分析文档链接} | 实验中/已暂停/全量/归档 | ${YYYY-MM-DD/-} |

### 5.3 关键发现/Key Findings

| ID    | 新增时间     | KA  | 类型                | 发现内容    | 来源/依据        |
| ----- | -------- | --- | ----------------- | ------- | ------------ |
| 5.3.1 | ${YYYY-MM-DD} | KA1 | ${数据分析/实验结论/线上观察} | ${发现描述} | ${分析链接或实验链接} |
| 5.3.2 | ${YYYY-MM-DD} | KA2 | ${数据分析/实验结论/线上观察} | ${发现描述} | ${分析链接或实验链接} |

### 5.4 问题与讨论/Problems & Discussion

| ID    | 新增时间     | KA  | 问题描述    | 影响范围    | 紧急程度        | 状态  | 结论/备注 |
| ----- | -------- | --- | ------- | ------- | ----------- | --- | ----- |
| 5.4.1 | ${YYYY-MM-DD} | KA1 | ${问题描述} | ${影响范围} | ${P0/P1/P2} | ${待讨论/已讨论/待解决/已解决/归档} | ${结论/备注} |
| 5.4.2 | ${YYYY-MM-DD} | KA2 | ${问题描述} | ${影响范围} | ${P0/P1/P2} | ${待讨论/已讨论/待解决/已解决/归档} | ${结论/备注} |

### 5.5 下一步计划/Next Steps

| ID    | 新增时间     | KA  | 下一步动作       | 预计开始时间   | 目标状态      | 预计完成日期   | 状态         |
| ----- | -------- | --- | ----------- | -------- | --------- | -------- | ---------- |
| 5.5.1 | ${YYYY-MM-DD} | KA1 | ${预计完成 xxx} | ${YYYY-MM-DD} | ${进入 yyy} | ${YYYY-MM-DD} | 待开始/进行中/归档 |
| 5.5.2 | ${YYYY-MM-DD} | KA2 | ${预计完成 xxx} | ${YYYY-MM-DD} | ${进入 yyy} | ${YYYY-MM-DD} | 待开始/进行中/归档 |

### 5.6 结项总结/Close Summary

<!-- 当 Phase 进入 Done/Close 时填写。可使用 /ads-okr-epic-retro 辅助填写。 -->

#### 5.6.1 总览/Overview

| 结项日期 | 结项人 | 实际耗费人力(人天) | 实际执行自然天 | 收益自评(0-10) | 执行自评(0-10) |
| --- | --- | --- | --- | --- | --- |
| - | - | - | - | - | - |

#### 5.6.2 收益指标实际达成总结/Benefit Achievement（必填）

${对照交付目标【收益】，逐项说明实际达成情况和差异原因}

#### 5.6.3 执行交付物落地总结/Execution Summary（必填）

${对照交付目标【执行】，逐项说明落地情况}

#### 5.6.4 其他总结和收获/Other Learnings（选填）

-

## 六、附录（可选）/Appendix (Optional)

<!-- 附录用于存放非正文核心元素，保持正文精简。所有子节均为可选，格式自由，按需使用。 -->
<!-- The appendix holds supplementary material to keep the main body concise. All subsections are optional and free-form. -->

### 6.1 讨论记录/Discussion Log

<!-- 记录会议、评审、对齐等讨论的要点，按日期倒序排列（最新在最上面）。 -->
<!-- Record key points from meetings, reviews, and alignment discussions. Reverse chronological order. -->

### 6.2 公式推导/Formula Derivation

<!-- 记录算法公式推导、数学证明等技术细节，避免在正文方案设计中展开过多数学推导。 -->
<!-- Record algorithm formula derivations and mathematical proofs. Keeps the main solution design section concise. -->

### 6.3 参考资料/References

<!-- 外部文档、论文、竞品分析、内部 wiki 等参考链接。 -->
<!-- External documents, papers, competitor analysis, internal wiki links, etc. -->

### 6.4 废弃方案/Deprecated Solutions

<!-- 记录评估后未采纳的方案及其放弃原因，供后续回顾参考。 -->
<!-- Record solutions that were evaluated but not adopted, along with reasons for rejection. -->
