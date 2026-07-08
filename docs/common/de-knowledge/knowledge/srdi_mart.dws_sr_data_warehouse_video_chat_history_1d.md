<!-- ads-workspace-gdoc-sync: gdoc_id=19-VpvPsWIf17IGETa3r6KxJUnELv5S-d5JbkwZQatLQ gdoc_url=https://docs.google.com/document/d/19-VpvPsWIf17IGETa3r6KxJUnELv5S-d5JbkwZQatLQ/edit -->

# srdi_mart.dws_sr_data_warehouse_video_chat_history_1d

**分层：** DWS（数据仓库汇总层）
**主键：** `round_id` + `grass_region` + `regional_date` + `manual_check_date`
**分区：** `grass_region` / `regional_date` / `manual_check_date`
**更新频率：** 每日（T+1，按人工审核日期写入）
**访问频次：** 542

---

## 业务描述

本表记录视频 AI 对话（Video Chat）的逐轮次内容审核明细，面向搜推数仓内容安全（Content Safety）业务域。

核心业务场景如下：

1. **自动审核结果存档**：从原始对话日志中提取每轮对话的 prompt（用户提问）与 response（AI 回答），并记录系统自动安全检测结论（`is_flagged`、`prompt_is_flagged`、`response_is_flagged`）。
2. **人工审核结果关联**：将质检系统（QC）两个队列（旧队列 `queue_id=1000000011` / 新队列 `queue_id=1000000067`）的人工标注结果（`is_violation`、`prompt_is_violation`、`response_is_violation` 及对应 policy 列表）与对话轮次打通，支持违规溯源。
3. **自动审核效果评估**：通过 `category`（TN/FP/FN/TP）量化自动系统与人工结果的一致性，支持精准率、召回率等模型效果评估。
4. **人工审核过程还原**：记录操作员列表（`operator_list`）、抽样类型（`sample_type`）及命中关键词（`hit_keywords_list`）等质检元数据。

**适合回答的问题：**
- 某日某地区有多少对话轮次被人工判定为违规？
- 自动审核系统的 FP/FN/TP/TN 分布如何？
- 某用户在某会话中的对话内容是否命中安全策略？
- 旧队列与新队列的违规 policy 分布差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 TH、MY 等），与业务地区对应 |
| `regional_date` | date | 对话发生日期，由请求时间戳（`request.timestamp`）解析；2024-08-25 之前无时间戳的记录统一归为 `2024-08-25` |
| `manual_check_date` | date | 人工审核执行日期（即 ETL 运行日期 `local_date`），用于标记本批次审核结果写入时间 |

---

### 维度：对话标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `round_id` | bigint | 对话轮次 ID，为本表核心粒度标识，来源于原始对话日志 |
| `biz_session_id` | string | 业务会话 ID，标识一次完整的用户会话 |
| `user_id` | bigint | 用户 ID，从请求元数据 `request.request_meta.userid` 解析 |
| `queue_id` | decimal(20,0) | 人工审核队列 ID；`1000000011` 为旧队列，`1000000067` 为新队列，决定各违规字段的含义 |
| `sample_type` | string | 抽样类型，标识本轮次进入质检的抽样策略（来源于 QC 抽样表） |

---

### 维度：对话内容

| 字段 | 类型 | 说明 |
|---|---|---|
| `prompt_text` | string | 用户输入的对话文本（`request.utterance`） |
| `response_text` | array\<string\> | AI 回复内容数组，按 bubble 类型（item_full / item_lite / item_rcmd / apprl / text）提取 `frontier_md` 或 `content_md` |
| `fallback_answer` | string | 命中安全策略时系统返回的兜底回答文本 |

---

### 维度：审核元数据

| 字段 | 类型 | 说明 |
|---|---|---|
| `category` | string | 自动审核与人工审核结果的对比分类，仅旧队列（`queue_id=1000000011`）有效；取值：`TP`（均判违规）/ `FP`（自动误判）/ `FN`（自动漏判）/ `TN`（均判安全） |
| `operator_list` | array\<string\> | 参与本轮次人工审核的操作员列表 |
| `hit_keywords_list` | array\<string\> | 命中安全规则的关键词列表，过滤掉空字符串后保留 |
| `hit_safe_reason` | int | 命中安全策略的原因码（来源于 `history_metas.hit_safe_reason`） |

---

### 指标：自动审核结果

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_flagged` | int | 整体安全标记；`response.data.is_safe` 或 `request.is_safe` 为 false 则为 1，否则为 0 |
| `prompt_is_flagged` | int | 用户 prompt 被系统标记为不安全；`response_code = 1508700004` 时为 1，否则为 0 |
| `response_is_flagged` | int | AI response 被系统标记为不安全；`response_code = 1508700001` 时为 1，否则为 0 |

---

### 指标：人工审核结果（旧队列）

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_violation` | int | 整体人工违规判定；仅旧队列（`queue_id=1000000011`）有效，`policy_list` 非空则为 1，否则为 0；新队列为 null |
| `policy_list` | array\<string\> | 旧队列人工标注的违规策略列表；新队列为 null |

---

### 指标：人工审核结果（新队列）

| 字段 | 类型 | 说明 |
|---|---|---|
| `prompt_is_violation` | int | prompt 人工违规判定；仅新队列（`queue_id=1000000067`）有效，`prompt_policy_list` 非空则为 1，否则为 0；旧队列为 null |
| `prompt_policy_list` | array\<string\> | 新队列中 prompt 维度的违规策略列表（`key_id=1094`）；旧队列为 null |
| `response_is_violation` | int | response 人工违规判定；仅新队列有效，`response_policy_list` 非空则为 1，否则为 0；旧队列为 null |
| `response_policy_list` | array\<string\> | 新队列中 response 维度的违规策略列表（`key_id=1095`）；旧队列为 null |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须在 WHERE 条件中明确指定，避免全分区扫描；该字段同时作为分区键。
- **`manual_check_date`**：推荐始终指定，代表人工审核批次日期；不同 `manual_check_date` 的数据会重叠覆盖同一 `regional_date` 的轮次（因为 ETL 采用近 90 天滚动窗口写入），直接跨日期聚合会导致 `round_id` 重复计数。
- **`regional_date`**：在分析对话发生时间时使用，需与 `manual_check_date` 配合使用以避免重复。

### 不可直接 SUM 的字段

- **`is_flagged` / `prompt_is_flagged` / `response_is_flagged` / `is_violation` / `prompt_is_violation` / `response_is_violation`**：0/1 标记字段，在多 `manual_check_date` 下同一 `round_id` 可能多次出现，需先按 `round_id` 去重再聚合。
- **`policy_list` / `prompt_policy_list` / `response_policy_list` / `hit_keywords_list` / `operator_list` / `response_text`**：数组类型字段，不可直接 SUM，需使用 `explode` 或 `flatten` 展开后统计。
- **`category`**：分类标签字段，仅适用于旧队列（`queue_id=1000000011`），新队列数据该字段为 null，统计时须先过滤 `queue_id`。
- **`queue_id` 相关字段**：`is_violation`/`policy_list` 仅旧队列有效；`prompt_is_violation`/`prompt_policy_list`/`response_is_violation`/`response_policy_list` 仅新队列有效，混合队列聚合时需分组或过滤。

### 时效性说明

- 本表为 **1d（日）粒度表**，每日 T+1 更新，`manual_check_date` 代表审核执行日。
- ETL 采用 **近 90 天滚动窗口**（`dt between date_sub(local_date, 89) and local_date`）从上游读取数据，因此历史 `regional_date` 分区的数据可能随每日 ETL 更新而被重写。
- 2024-08-25 之前的历史数据因无请求时间戳，`regional_date` 统一归为 `2024-08-25`，不代表真实对话日期。
- 2024-09-14 之前的数据存在特殊全量补录逻辑（不受 90 天滚动限制），使用时需注意分区边界。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_video_chat_log` | 原始视频对话日志，提供每轮对话内容（prompt/response）、安全检测结果、用户信息等核心字段 |
| `qc.shopee_luckyvideo_qc_manual_id_db__manual_ticket_result_tab__reg_continuous_s0_live` | QC 系统人工审核结果表，提供 policy 标注详情（旧队列整体 policy / 新队列 prompt+response 分项 policy）及操作员信息 |
| `qc.shopee_luckyvideo_qc_manual_id_db__manual_ticket_tab__reg_continuous_s0_live` | QC 工单主表，提供工单 ID 与对话 `round_id` 的映射关系 |
| `qc.shopee_luckyvideo_qc_manual_id_db__manual_ticket_material_tab__reg_continuous_s0_live` | QC 工单素材表，提供工单 ID 与 `content_id` 的对应关系，用于关联抽样类型 |
| `qc.tns_video_ai_chat_sample_daily` | 旧队列（`queue_id=1000000011`）的每日抽样记录，提供 `sample_type` |
| `qc.tns_video_ai_chat_sample_daily_v2` | 新队列（`queue_id=1000000067`）的每日抽样记录，提供 `sample_type` |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_video_chat_log
        │
        ▼
[chat_history] ── 提取对话内容、安全检测结果（近90天滚动）
        │
        │   qc.manual_ticket_result_tab ──► [manual_result_base] ──► [manual_result]
        │   qc.manual_ticket_tab ──────────► [manual_ticket_round_id_mapping]
        │   qc.manual_ticket_material_tab ─► [sample_type_mapping_temp_left]
        │   qc.tns_video_ai_chat_sample_daily(v1+v2) ──► [sample_type_mapping_temp_right]
        │                                         └──► [sample_type_mapping]
        │
        ▼
[manual_result_joined] ── 按 round_id + queue_id 聚合 policy、operator、sample_type
        │
        ▼
[manual_result_final] ── 按 queue_id 区分旧/新队列字段语义，计算 is_violation
        │
        ▼
chat_history INNER JOIN manual_result_final ON round_id
        │
        ▼
srdi_mart.dws_sr_data_warehouse_video_chat_history_1d
  （INSERT OVERWRITE，分区：grass_region / regional_date / manual_check_date）
```

### 关键步骤

1. **`chat_history`（Temporary View）**：从 DWD 原始日志中按地区和时间窗口过滤有效对话轮次，解析 JSON 字段提取 prompt 文本、response 内容数组（多 bubble 类型归一化）、用户 ID、安全标记及兜底回答等信息。仅保留 `is_safe` 明确为 `true`/`false` 且 `round_id` 非空的记录。

2. **`manual_result_base`（Temporary View）**：从 QC 工单结果表中展开 `ext` 数组，筛选 `label_type=2` 的标注项，解析 pms_ext_detail_list 结构，限定为当日审核（`date(ctime/1000) = local_date`），覆盖两个队列。

3. **`manual_result`（Temporary View）**：按队列 ID 区分 policy 提取逻辑——旧队列取 `pms_ext_detail_list[0]` 的 title 数组作为整体 `policy_array`；新队列通过 `key_id=1094` 提取 prompt policy，`key_id=1095` 提取 response policy。

4. **`manual_ticket_round_id_mapping`（Temporary View）**：从工单主表获取近 90 天工单对应的 `round_id`，供后续关联。

5. **`sample_type_mapping`（Temporary View）**：将工单素材表与新旧抽样表（UNION ALL）按 `content_id = object_id` 关联，获取每个工单的 `sample_type`。

6. **`manual_result_joined`（Temporary View）**：以 `round_id + queue_id` 为粒度，聚合 policy 列表（`array_distinct + flatten + collect_list`）、operator 列表，并取 `sample_type`（`min`，每个 `round_id` 唯一）。

7. **`manual_result_final`（Temporary View）**：按 `queue_id` 分支计算 `is_violation`（旧队列：`size(policy_list) > 0`）、`prompt_is_violation`/`response_is_violation`（新队列），不适用的队列字段置 null。

8. **`INSERT OVERWRITE`（目标写入）**：将 `chat_history` 与 `manual_result_final` 按 `round_id` INNER JOIN，计算 `category`（TN/FP/FN/TP，仅旧队列）、`prompt_is_flagged`（response_code=1508700004）、`response_is_flagged`（response_code=1508700001），以 `grass_region`/`regional_date`/`manual_check_date` 为分区写入目标表。

### 注意事项

- **INNER JOIN 语义**：最终写入步骤对 `chat_history` 与 `manual_result_final` 做 INNER JOIN，**仅保留同时存在人工审核结果的对话轮次**，未进入质检队列的轮次不会出现在本表中。
- **多分区覆盖风险**：ETL 采用近 90 天滚动窗口读取原始数据，`INSERT OVERWRITE` 按 `regional_date` 动态分区写入，每次运行会重写历史 `regional_date` 下该 `manual_check_date` 的全部分区。同一 `regional_date` 在不同 `manual_check_date` 下均有数据，跨 `manual_check_date` 聚合时须去重 `round_id`。
- **双队列字段互斥**：旧队列（`queue_id=1000000011`）和新队列（`queue_id=1000000067`）的违规字段是互斥的，同一 `round_id` 不同队列的审核结果可能分别存为两行（`queue_id` 不同）。
- **历史数据时间戳缺失**：2024-08-25 之前的数据无 `request.timestamp`，`regional_date` 被强制归为 `2024-08-25`，时序分析时需单独处理该日期。
- **`response_code` 字段未入表**：ETL 中间层使用 `response_code` 推导 `prompt_is_flagged` 和 `response_is_flagged`，但 `response_code` 本身未写入最终表。

---

*文档生成时间：2026-05-17*