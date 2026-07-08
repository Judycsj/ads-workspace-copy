<!-- ads-workspace-gdoc-sync: gdoc_id=1EJvkNTdarIYxW3lfBgKm1k9pLXtvHH7mOXM3FpHhMyQ gdoc_url=https://docs.google.com/document/d/1EJvkNTdarIYxW3lfBgKm1k9pLXtvHH7mOXM3FpHhMyQ/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_order_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_type` + `grass_region` + `local_date` + `exp_group_id` + `feature_detail` + `scenario_tag` + `is_ads` + `is_cod`
**分区：** `exp_type` / `grass_region` / `local_date`（三级分区）
**更新频率：** 每日调度（T+1），覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次：** 2946

---

## 业务描述

本表是搜推数据仓库（SRDI）A/B 实验平台的**实验组粒度每日订单指标汇总表**，面向搜索与推荐场景的实验分析需求。表中记录了不同实验分组（`exp_group_id`）、功能模块（`feature_detail`）、业务场景标签（`scenario_tag`）在各大区（`grass_region`）的每日订单量、商品数、SPU 数及 GMV 等多状态指标。

**核心业务场景：**

- **A/B 实验效果评估**：按实验组比对不同策略/算法对搜索/推荐订单转化的影响，支持 `traffic`（流量归因）、`assign_log_join`（分配日志关联）、`dim_join`（维度表关联）三种不同实验人群圈定方式的对比分析。
- **多状态订单漏斗分析**：覆盖下单、支付、完成、取消、退货五个订单状态，可还原完整订单生命周期。
- **广告/非广告、COD/非 COD 流量拆分**：支持广告流量与自然流量、货到付款与在线支付的交叉分析。
- **搜索场景归因**：通过 `scenario_tag` 区分全局搜索（Search）及其他算法标签场景下的订单贡献。

**适合回答的问题举例：**

- 某实验组在某大区某日相比对照组 GMV 提升了多少？
- 广告流量对实验组完成支付订单数的贡献有多大？
- 搜索场景（Search）与推荐场景的实验订单漏斗差异如何？
- 使用 `assign_log_join` 与 `dim_join` 方式圈定的实验人群，订单指标是否存在差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验人群圈定方式，区分三条写入 pipeline：`traffic`（直接流量归因，不依赖用户维度）、`assign_log_join`（基于分配日志 `is_assignment_log=1` 圈定白名单用户）、`dim_join`（基于维度表 `is_dim_join=1` 圈定白名单用户） |
| `grass_region` | string | 大区标识，如 `SG`、`MY`、`TH` 等；每次 ETL 按大区参数化执行并写入对应分区 |
| `local_date` | date | 业务本地日期，为订单行为发生的本地时区日期 |

### 维度：实验与功能模块标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | 实验分组 ID，标识具体的实验桶（对照组/实验组） |
| `feature_detail` | string | 功能模块/特征细节标识；聚合逻辑中来自主归因（`feature_detail`）、一级来源（`source1_feature_detail`）或二级来源（`source2_feature_detail`）的去重合并；`__ALL__` 表示不区分功能模块的全量汇总 |
| `scenario_tag` | string | 业务场景标签，由算法标签（`algo_tag`）及是否属于全局搜索（`reporting_business_line='Search'` 且 `reporting_module='Global Search'` 时追加 `Search`）合并展开生成；`__ALL__` 表示不区分场景的全量汇总 |

### 维度：流量属性标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 是否为广告流量；来源于行为数据中的 `is_ads` 字段 |
| `is_cod` | boolean | 是否为货到付款（Cash On Delivery）订单；由订单状态表中 `is_cod_order` 汇聚而来（`max(is_cod_order) > 0` 则为 `true`） |

### 指标：下单阶段（Place Order）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单订单数（`sum(operation_cnt)` where `operation='order'`） |
| `item_cnt` | bigint | 下单商品 item 去重数（`count(distinct item_id)`） |
| `model_cnt` | bigint | 下单 SKU（model）去重数（`count(distinct model_id)`） |
| `gmv` | double | 下单 GMV（`sum(place_order_gmv)`） |

### 指标：支付阶段（Paid）

| 字段 | 类型 | 说明 |
|---|---|---|
| `paid_order_cnt` | double | 已支付订单数（`pay_datetime is not null`） |
| `paid_item_cnt` | bigint | 已支付商品 item 去重数 |
| `paid_model_cnt` | bigint | 已支付 SKU 去重数 |
| `paid_gmv` | double | 已支付 GMV |

### 指标：完成阶段（Completed）

| 字段 | 类型 | 说明 |
|---|---|---|
| `completed_order_cnt` | double | 已完成订单数（`complete_datetime is not null`） |
| `completed_item_cnt` | bigint | 已完成商品 item 去重数 |
| `completed_model_cnt` | bigint | 已完成 SKU 去重数 |
| `completed_gmv` | double | 已完成 GMV |

### 指标：取消阶段（Cancelled）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cancelled_order_cnt` | double | 已取消订单数（`cancel_datetime is not null`） |
| `cancelled_item_cnt` | bigint | 已取消商品 item 去重数 |
| `cancelled_model_cnt` | bigint | 已取消 SKU 去重数 |
| `cancelled_gmv` | double | 已取消 GMV |

### 指标：退货阶段（Returned）

| 字段 | 类型 | 说明 |
|---|---|---|
| `returned_order_cnt` | double | 退货订单数（`is_returned_item = 1`） |
| `returned_item_cnt` | bigint | 退货商品 item 去重数 |
| `returned_model_cnt` | bigint | 退货 SKU 去重数 |
| `returned_gmv` | double | 退货 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须显式指定，否则触发全量分区扫描。建议使用精确日期或有界范围，如：
  ```sql
  WHERE local_date = '2024-06-01'
  ```
- **`exp_type`**：必须指定，三条 pipeline（`traffic`、`assign_log_join`、`dim_join`）写入同一物理表的不同分区，**跨 `exp_type` 混合查询会导致重复计数**。业务场景下应明确选择一种实验人群圈定方式：
  ```sql
  AND exp_type = 'assign_log_join'
  ```
- **`grass_region`**：建议显式过滤，避免跨大区聚合产生无意义汇总。

### 不可直接 SUM 的字段

- **`item_cnt`、`paid_item_cnt`、`completed_item_cnt`、`cancelled_item_cnt`、`returned_item_cnt`**：基于 `count(distinct item_id)` 预聚合，跨行直接 SUM 会高估去重数，不可再次累加。
- **`model_cnt`、`paid_model_cnt`、`completed_model_cnt`、`cancelled_model_cnt`、`returned_model_cnt`**：同上，基于 `count(distinct model_id)` 预聚合。
- **`feature_detail = '__ALL__'` 与具体 feature 行之间**：存在预聚合的上下级包含关系，混合 SUM 会导致重复计数。
- **`scenario_tag = '__ALL__'` 与具体 tag 行之间**：同上。
- **跨 `exp_type` 聚合**：三种 exp_type 各自使用不同的人群圈定逻辑，对同一用户的订单可能存在交叉覆盖，**不可对 `exp_type` 维度直接 SUM**。

### 时效性说明

- 本表为 **`_1d` 日粒度表**，每日调度写入 T-1 数据（即数据延迟约 1 天）。
- 行为数据取当日回溯 **14 天**窗口（`local_date between date_add(${local_date}, -14) and ${local_date}`），订单状态数据取近 **15 天**（`create_datetime >= current_date - 15 day`）。即查询单日分区时，指标已包含历史 14 天内发生的行为归因到该日的汇总，而非仅当日新增。
- 订单状态（支付/完成/取消/退货）为实时快照数据，反映查询时最新状态，**历史分区数据已固化，不会随订单状态变更自动回填**。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜推行为明细宽表，提供订单行为（`operation='order'`）、下单 GMV、feature 信息、算法标签、用户 ID 等核心字段 |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | 全量订单 item 明细表，提供支付时间、完成时间、取消时间、退货状态、COD 标识等订单状态字段 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 实验用户分组维度表，提供 user_id 与 exp_group_id 的映射关系，用于 `assign_log_join`（`is_assignment_log=1 AND is_rcmd_search_whitelist=1`）和 `dim_join`（`is_dim_join=1 AND is_rcmd_whitelist=1`）两种用户圈定方式的人群过滤 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform  ──┐
                                             ├──► behavior_data（行为聚合至 order/item/model 粒度）
mp_order.dwd_order_item_all_ent_df__reg_s0_live ──► order_status_data（订单状态快照）
                                             │
                                             └──► joined_data / behavior_data_joined（LEFT JOIN 补充订单状态）
                                                          │
srdi_mart.dim_sr_data_warehouse_abtest_user_group ──►（仅 assign_log_join / dim_join）用户白名单过滤
                                                          │
                                                     exp_group_data_filter / joined_data
                                                          │
                                                   LATERAL VIEW EXPLODE exp_group_ids
                                                          │
                                                   exploded_data（按实验组展开）
                                                          │
                                         ┌─────────────────────────────────┐
                                         │  feature_tag_data               │
                                         │  （feature_detail × scenario_tag│
                                         │   三路 UNION：主/source1/source2）│
                                         └─────────────────────────────────┘
                                                          │
                                                   union_data（三路汇总 UNION ALL）
                                                   1. feature=__ALL__, tag=__ALL__（全量汇总）
                                                   2. feature=__ALL__, tag=具体 tag（场景维度汇总）
                                                   3. feature=具体, tag=具体（明细）
                                                          │
                              INSERT OVERWRITE partition(exp_type, grass_region, local_date)
                                                          │
                         dws_sr_data_warehouse_platform_exp_level_order_metrics_1d
```

### 关键步骤

**Source 1（exp_type = 'traffic'，共 7 个 Statement）**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| S1-1 | `behavior_data` | 从 `dwd_sr_data_warehouse_platform` 过滤 `operation='order'`，按 feature_detail / order_id / item_id / model_id 等维度聚合下单数和 GMV，构建场景标签数组 |
| S1-2 | `order_status_data` | 从 `dwd_order_item_all_ent_df__reg_s0_live` 按 (order_id, item_id, model_id) 聚合最新支付/完成/取消时间、退货状态及 COD 标识 |
| S1-3 | `joined_data`（CACHE） | LEFT JOIN 行为数据与订单状态数据，计算五个状态维度的 order/item/model/GMV 指标；同时通过 `LATERAL VIEW EXPLODE(exp_group_ids)` 将多实验组展开 |
| S1-4 | `exploded_data` | 基于 `joined_data` 展开实验组，合并三路 scenario_tags 为 `union_scenario_tags` |
| S1-5 | `feature_tag_data` | 对三路 feature_detail（主/source1/source2）分别 EXPLODE scenario_tags，UNION ALL 生成 feature × scenario 明细行 |
| S1-6 | `union_data` | 三路 UNION：① 全量汇总（`__ALL__` × `__ALL__`）；② 场景汇总（`__ALL__` × scenario_tag）；③ feature × scenario 明细 |
| S1-7 | INSERT OVERWRITE | 写入 `partition(exp_type='traffic', grass_region, local_date)` |

**Source 2（exp_type = 'assign_log_join'，共 8 个 Statement）**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| S2-1 | `selected_user_exps` | 从 `dim_sr_data_warehouse_abtest_user_group` 过滤 `is_assignment_log=1 AND is_rcmd_search_whitelist=1`，圈定白名单用户与实验组映射 |
| S2-2 | `behavior_data` | 同 S1-1 |
| S2-3 | `order_status_data` | 同 S1-2 |
| S2-4 | `behavior_data_joined` | 行为数据与订单状态 LEFT JOIN，保留 user_id 列（后续用于白名单过滤） |
| S2-5 | `exp_group_data_filter`（CACHE） | INNER JOIN `selected_user_exps`，仅保留白名单用户；按实验组和维度聚合 |
| S2-6 | `feature_tag_data` | 同 S1-5，基于白名单过滤后数据 |
| S2-7 | `union_data` | 同 S1-6 |
| S2-8 | INSERT OVERWRITE | 写入 `partition(exp_type='assign_log_join', grass_region, local_date)` |

**Source 3（exp_type = 'dim_join'，共 8 个 Statement）**

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| S3-1 | `selected_user_exps` | 从 `dim_sr_data_warehouse_abtest_user_group` 过滤 `is_dim_join=1 AND is_rcmd_whitelist=1`，圈定白名单用户（与 assign_log_join 使用不同的白名单字段） |
| S3-2 ~ S3-7 | 同 Source 2 S2-2 ~ S2-7 结构 | 流程结构与 assign_log_join 完全一致，仅人群来源不同 |
| S3-8 | INSERT OVERWRITE | 写入 `partition(exp_type='dim_join', grass_region, local_date)` |

### 注意事项

1. **Multi-writer 并发写入风险**：三个 ETL 文件分别向目标表写入不同 `exp_type` 分区（`traffic` / `assign_log_join` / `dim_join`），若并发执行需确保分区隔离，避免相互覆盖。
2. **14 天滑动窗口行为数据**：行为数据拉取范围为 `[local_date - 14, local_date]`，单个分区数据不仅包含当日行为，还包含过去 14 天内触达但延迟上报的行为，需注意指标口径。
3. **`__ALL__` 汇总行与明细行并存**：`feature_detail` 和 `scenario_tag` 均存在 `__ALL__` 聚合行，查询时若不过滤将导致重复计数。建议查询时明确指定 `feature_detail != '__ALL__'` 或反之。
4. **item_cnt / model_cnt 为预聚合去重值**：由于在 `joined_data` 阶段已经执行 `count(distinct)`，后续聚合层（feature_tag_data、union_data）对这些字段执行的是 `sum`，实际为加法累加（非真正去重），跨维度汇总时数值仅供参考，不代表真实去重数。
5. **source1/source2 feature 去重逻辑**：source1_feature_detail 仅在不为空且不等于主 feature_detail 时才写入；source2_feature_detail 需额外满足不等于 source1_feature_detail，防止同一订单在不同 feature 维度下被重复计入。
6. **订单状态为时点快照**：`dwd_order_item_all_ent_df__reg_s0_live` 为 live 表，历史分区写入后订单状态不会随后续变更自动回填，支付/完成/取消状态以当次 ETL 执行时刻为准。

---

*文档生成时间：2026-05-17*