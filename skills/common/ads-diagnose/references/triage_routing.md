# Triage Routing 桶路由规则/Triage Routing Rules

> **Contributors**: ivan.duzl ｜ **最后更新**：2026-05-17 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/skills/common/ads-diagnose/references/triage_routing.md)

本文档定义 `ads-diagnose` 主 skill 的 L1 模块判定标准、三桶路由映射、主 skill ↔ sub-agent 上下文契约，以及报告合并规则。仅 ID 诊断和已知异常归因模式走本路由；异常类型诊断（批量 top case）和一级模块自动评审保持原流程。

节点和表字段的权威定义已拆到公共知识目录：

| 模块 | 节点定义 | 表字段 |
|---|---|---|
| Overall / L1 / A-B 异常 | `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` | `docs/common/skill-knowledge/diagnose/overall/table_info.md` |
| R3 model | `docs/common/skill-knowledge/diagnose/rank-model/factual_nodes.md` | `docs/common/skill-knowledge/diagnose/rank-model/table_info.md` |
| R4 bidding | `docs/common/skill-knowledge/diagnose/bidding/factual_nodes.md` | `docs/common/skill-knowledge/diagnose/bidding/table_info.md` |
| R5 funnel | `docs/common/skill-knowledge/diagnose/funnel/factual_nodes.md` | `docs/common/skill-knowledge/diagnose/funnel/table_info.md` |

## 1. 三桶模型/Three-Bucket Model

| 桶 | 处理方 | 包含模块 |
|---|---|---|
| 自身 (self) | 主 skill 直接展开叶子 | R1, R2, R5, R6, R7, R8, R9, R10 |
| 出价 (bidding) | `ads-diagnose-bidding-deepdive-xyz` agent | R4 |
| 模型 (model) | `ads-diagnose-model-deepdive-hb` agent | R3 |

- 自身桶始终由主 skill 处理，不需要 agent
- 出价/模型 agent 只在对应一级模块判定为**命中**、且用户在主 skill「Deep Dive 用户确认闸门」显式确认后才被调起（dispatch 前主 skill 先完成自身桶展开并输出整体诊断报告，R3/R4 命中桶仅 L1 行标注待确认；用户跳过的桶标记 `skipped by user`，只保留 L1 verdict）
- 三桶都未命中（健康 case）→ 主 skill 直接出"未检测到异常"报告，零 agent 调用
- 命中 R3 + R4 且均经用户确认 → 两 agent 并行 dispatch

## 2. L1 模块判定标准/L1 Module Verdict Criteria

主 skill 在 Step 5 对 R1-R10 每个一级模块输出以下四态判定之一，只到模块级（自身桶模块在 Step 6a 才展开叶子；R3/R4 由对应 agent 展开叶子）：

| 模块状态 | 判定条件 | 数字依据写法 |
|---|---|---|
| 命中 | 该模块下任一叶子节点公式可命中且方向匹配主异常 | 最关键的命中数值（例：`final_coef_avg_7d = 2.78 > 1`） |
| 未命中 | 模块下所有可计算叶子节点均未命中 | 最关键的排除数值（例：`14 节点全部未命中：target_roi_by_imp_0/_1 = 1.00`） |
| 证据不足 | 关键叶子节点缺数据 | 缺什么字段/查询（例：`缺同品类 P25，无法判定 R1.6.1`） |
| 不适用 | 模块前提不成立 | 前提值（例：`当前为 single campaign 诊断，R9 不适用`） |

**方向过滤规则（R3/R4 特殊）：** R3 模型预估异常和 R4 出价调控策略异常必须按主异常方向过滤。主 skill 在 L1 阶段也使用该过滤规则判定 R3/R4 模块级 verdict（只有方向匹配的叶子或宽口径阈值可计入命中），并把主异常方向作为上下文传给 `ads-diagnose-model-deepdive-hb` / `ads-diagnose-bidding-deepdive-xyz` agent；agent 在叶子层级使用同一规则做详细展开。完整规则见 `docs/common/skill-knowledge/diagnose/overall/factual_nodes.md` 的 R3/R4 章节。

**自身桶补充规则（R1/R6）：**
- R1.1/R1.2 的 TROI / budget 变更优先使用 UNION 日聚合字段；当字段缺失、为 0、无限制、或与同日广告主操作明显不一致时，STATUS `dwd_ads_index_status_live.reason` 中的 `change_budget`、`change roi`、`target roi` 可作为 `STATUS operation fallback` 证据。超收/爆量只接受 budget 增加或 TROI 降低；欠收/掉量只接受 budget 降低或 TROI 提高。
- R6 掉量场景除单指标极端阈值外，还接受联合退化信号：GMV/revenue 显著下降，同时 `avg_coef_0/avg_coef_1 < 0.7` 且 `mixrank_rate_0/mixrank_rate_1 < 0.8`。

**方向集合：**
- 超收/爆量：A1/A3/A9/B1/B3/B10。
- 欠收/掉量：A2/A4/A7/A8/B2/B4/B8/B9。
- R4 欠收/掉量宽口径除绝对阈值外，还包含 `avg_coef_0/avg_coef_1 < 0.7` 或 `final_coef_0/final_coef_1 < 0.8` 的相对退化。

## 3. 主 skill → sub-agent 上下文契约/Main Skill → Sub-agent Context Contract

主 skill 通过 Claude Code Agent 工具（`subagent_type: ads-diagnose-bidding-deepdive-xyz` 或 `ads-diagnose-model-deepdive-hb`）调起 agent，prompt 必须包含以下结构化上下文：

```yaml
mode: id_diagnosis | known_anomaly_attribution

target:
  campaign_id: <int>
  ads_ids: [<int>, ...]
  shop_id: <int>
  region: <str>             # ID / TH / PH / VN / MY / TW / SG / BR
  date_range: ["<YYYY-MM-DD>", "<YYYY-MM-DD>"]
  pricing_type: 11 | 15     # Target=11 / Simple=15
  target_roi: <float>          # ROI 下限/配置值，不代表真实 TROI
  target_roi_by_imp: <float>   # 真实 target ROI / TROI = troi_sum_by_imp / ads_imp

main_anomaly:
  hit_types: [A1, A8, ...]   # 主 skill Step 4 检测到的异常编号
  primary_direction: 超收 | 欠收 | 掉量 | 爆量 | 低效率 | 其他

l1_verdict_for_this_bucket:
  # 出价 agent 收到 R4；模型 agent 收到 R3
  <module>:
    verdict: 命中 | 未命中 | 证据不足 | 不适用
    direction: <str>           # 与 main_anomaly.primary_direction 一致或细化
    key_evidence: <str>

key_metrics_table: |       # 主 skill Step 1 campaign 级别已查的关键序列
  | 日期 | rev_usd | advv_usd | cost_ratio_1d | final_coef | balance |
  | mpc_e_gmv | mpc_e_cost | ultra_core_rev | ultra_core_advv |
  | pctr_pcoc | pcr_pcoc | pgmv_pcoc |
  覆盖完整 Step 1 时间窗口（提供日期 D 时为 D-7 ~ D+5；提供日期范围 [D1, D2]
  时为 D1-3 ~ D2+5；未提供日期时为 today()-7 ~ today()）

ad_level_table: |          # 主 skill Step 2 ad 级别下钻（如有多 ads）
  | 日期 | ads_id | entrance | rev_usd | advv_usd | imp | clk | order |
  | final_coef | pctr_pcoc | pcr_pcoc | ... |

other_buckets_l1_summary:  # 跨桶上下文（让 agent 判因果链时用）
  R1: {verdict: 未命中}
  R2: {verdict: 命中, key_evidence: "item_price_0/avg_7d = 1.6"}
  R5: ...
  ...

leaves_to_evaluate:        # 该 agent 要展开的叶子节点编号
  # 主 skill 运行时从对应 factual_nodes.md 提取当前节点集合，按节点编号自然升序传入。
  # 出价 agent: 从 docs/common/skill-knowledge/diagnose/bidding/factual_nodes.md 提取 ^### R4. 节点
  #           不允许主 skill 手写固定范围；如果节点文件包含 RegulationEvent 节点，也一并传入。
  # 模型 agent: 从 docs/common/skill-knowledge/diagnose/rank-model/factual_nodes.md 提取 ^### R3. 节点；
  #           如使用 HB agent 的额外到达/归因链路节点，以该 agent 当前 Node 定义和 SQL 结果为准补齐。
  # 禁止手写固定范围或固定清单，避免 factual_nodes 新增/删除叶子后漏判。
```

**R4 / xyz 单一职责边界：** `triage_routing.md` 只定义主 skill 与 sub-agent 的上下文和合并契约，不定义 R4 deep dive 的执行步骤。`ads-diagnose-bidding-deepdive-xyz.md` 是 R4 的唯一执行规范；主 skill / worker prompt 不应在本契约中复写该 agent 的 Step 1-7。

## 4. Sub-agent → 主 skill 输出契约/Sub-agent → Main Skill Output Contract

每个 agent 必须返回以下 markdown 片段（主 skill 用 section header `### deep_dive_module: <Rx>` 作为锚点解析）：

````markdown
### deep_dive_module: <Rx>

#### 模块/节点合表片段

| 模块/节点 | 判定 | role | 数字依据 | 备注 |
|---|---|---|---|---|
| · <Rx.y> <叶子名> | 命中 / 未命中 / 证据不足 / 不适用 / 旁证 | trigger / amplifier / direct / selection_evidence | <实际值> <比较符> <阈值> 或 <当前值> vs <基线值> | <方向匹配/不匹配说明> |
| ... |

#### 命中根因
##### [<异常编号>] <Rx.y> <叶子名> (role: <trigger/amplifier/direct>)
- 证据: <来自数据的具体数值>
- 建议: <排查或修复方向>

#### 修复优先级
- P0: <Rx.y>（<理由>）
- P1: <Rx.y>（<理由>）

#### L1 复核
- module: <Rx>
- main_skill_verdict: 命中 / 未命中 / 证据不足 / 不适用
- agent_verdict: 命中 / 未命中 / 证据不足 / 不适用
- comment: <空字符串或异议说明>
````

`ads-diagnose-bidding-deepdive-xyz` 可以在 `### deep_dive_module: R4` 下输出其专属段落。主 skill 合并时只按语义映射结果，不关心 xyz 内部如何产生这些段落：

| xyz 输出 | 主报告合并方式 |
|---|---|
| 节点明细 / Node Summary | 转成 R4 模块/节点合表片段；`selection_evidence` 节点（如 R4.20-R4.27）只要 agent 判定为命中或旁证，也必须逐行保留，不能因未出现在修复优先级 P0/P1 中而省略 |
| `Case 明细` 中的 `first_abnormal_module`、`primary_anomaly`、`action_chain` | 转成命中根因、因果链和修复优先级依据 |
| `blocked / script_failed` | 按第 8 节错误处理，不得改写成成功结论 |

## 5. Sub-agent 职责边界/Sub-agent Responsibility Boundary

**做什么：**
- 对 `leaves_to_evaluate` 中每个叶子节点逐个判定；如果该字段缺失或为空，agent 必须读取对应 `factual_nodes.md` 自行提取当前叶子集合，不能依赖内置固定清单
- 必要时跑补充 SQL（如 final_coef hour 级轨迹、entrance 拆分、PCOC 校准前/后多天对比）
- 按上述 schema 输出 deep dive 报告片段
- R4 / xyz 场景必须按 `ads-diagnose-bidding-deepdive-xyz.md` 的当前流程执行；只读自然语言复核不算完成 R4 / xyz deep dive。

**不做什么：**
- 不重跑 Step 0-3 的基础查询（主 skill 已传给它）
- 不评估其他桶的模块（如 model agent 不评 R4，反之亦然）
- 不做最终的"一级模块归因总结"（这是主 skill 合并职责）
- 不修改主 skill 的 L1 verdict（如复核异议，只在 L1 复核段写明，由主 skill 决定是否采纳）
- R4 / xyz 场景不修改源码、skills、agents、README；诊断输出和中间证据文件的写入范围由 `ads-diagnose-bidding-deepdive-xyz.md` 约束。

## 6. 报告合并规则/Report Merge Rules

主 skill 在 Step 7 按以下规则拼装最终 diagnose report：

| Report Section | 来源 |
|---|---|
| 上下文 | 主 skill |
| 摘要 | 主 skill（汇总三方结论，保证与修复优先级 P0 一致） |
| 异常检测 | 主 skill Step 4 |
| 根因归因 → 模块/节点判定合表 | 主 skill 合并三方： |
| · 模块汇总行（R1-R10 全部 10 行） | 主 skill Step 5 L1 verdict |
| · R1/R2/R5/R6/R7/R8/R9/R10 命中模块的叶子行 | 主 skill Step 6a 自己展开 |
| · R4 命中模块的叶子行 | bidding agent 返回的合表片段；必须包含 agent 合表中的命中、旁证、证据不足、不适用行，尤其是 R4.20-R4.27 选点证据节点 |
| · R3 命中模块的叶子行 | model agent 返回的合表片段 |
| 命中根因与因果链 | 主 skill 跨桶整合：收集所有 trigger / amplifier / direct 节点，按时间顺序构建链路 |
| PCOC & 漏斗汇总表 | 主 skill（Step 1-2 数据） |
| 7 天聚合 | 主 skill |
| 一级模块归因总结 | 主 skill |
| 二级归因（叶子节点）总结 | 主 skill 汇总三方：自身桶命中叶子（主 skill）+ R4 agent 合表片段中判定为命中且方向匹配的叶子/选点证据节点 + R3 agent 合表片段中判定为命中且方向匹配的叶子；优先级从 agent 修复优先级段补充，未列入 P0/P1/P2 的 `selection_evidence` 优先级填 `-`；最终表必须按叶子节点编号自然升序排序，不能按修复优先级或 agent 输出顺序排序 |

## 7. 输出一致性校验/Output Consistency Check

合并后报告必须满足现有 SKILL.md 的"输出一致性约束"，由主 skill 在 Step 7 显式校验：

1. 修复优先级 P0 节点必须出现在摘要的"主根因"中，不能降级为"放大因素"
2. 同模块多 direct 节点必须做并联识别（不默认串联）
3. 因果链中的所有 direct 节点必须出现在修复优先级 P0 中
4. L1 模块归因总结中出现的所有命中模块，二级归因总结中必须有至少 1 行叶子；反之，二级归因总结中的所有叶子，其所属模块必须出现在 L1 模块归因总结中
5. 二级归因（叶子节点）总结必须按节点编号自然升序排列；若 P0/P1 与编号顺序冲突，仍以编号顺序为准，优先级只写在列里
6. R4 agent 合表片段中的命中 `selection_evidence` 节点必须同时出现在最终模块/节点合表和二级归因总结；可在命中根因与因果链中作为支撑证据引用，但不能从报告中删除

如果 agent 输出的 P0 与摘要冲突，主 skill 在合并时打出 warning 并以 agent 叶子证据为准重写摘要。

## 8. 错误处理/Error Handling

| 错误场景 | 主 skill 处理 |
|---|---|
| Sub-agent 返回明确失败 / blocked / script_failed | 报告中标注"⚠️ {bucket} deep dive 未完成：{失败原因}"。继续输出 L1 verdict + 自身桶 + 其他成功 agent 内容。最终摘要不包含失败桶的根因结论。 |
| Sub-agent 仍在运行 / 耗时过长 / 超时 / 暂无结果 / 读到空（**非失败**） | 不视为失败，不启动本地 fallback，不用主 skill 推理顶替叶子结论。默认动作是**继续轮询等待**直到 sub-agent 进入终态（成功块 / 明确失败）。仅当用户明确要求先出报告时，才把该桶标记为 `pending / 进行中`，只输出 L1 模块级 verdict，不展开叶子、不下根因结论。详见 SKILL.md Step 6「Worker 完成闸门」。 |
| Sub-agent 输出格式不符 schema | 主 skill 解析失败后，回退到只输出该桶的 L1 模块汇总行（不展开叶子），加 warning |
| Sub-agent L1 复核异议（agent 认为 L1 误判） | 在合表中保留 agent 的叶子判定（叶子是更精细的证据），模块汇总行改为 agent verdict，并在备注列写"主 skill L1 初判 {x}，agent 复核后改为 {y}：{原因}" |
| 多 agent 并发部分失败 | 成功的桶照常输出，失败的桶按上面规则；最终因果链只能用成功桶的节点构建 |
