<!-- ads-workspace-gdoc-sync: gdoc_id=1ZOeAohFDeplm-fpdRP-DYSQSnho290P64lWsVpZTr0I gdoc_url=https://docs.google.com/document/d/1ZOeAohFDeplm-fpdRP-DYSQSnho290P64lWsVpZTr0I/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_exp_scene_nmv_aggr_r7d_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `mapping_general` + `is_ads` + `is_item_card`
**分区：** `grass_region`（站点大区）、`local_date`（本地日期）
**更新频率：** 每日一次（1d）
**数据窗口：** 滚动近 7 天（r7d），即每次写入覆盖当前 `local_date` 往前 7 天的聚合结果
**引用频次 / 访问频次：** 1

---

## 业务描述

本表面向**搜推（SR）流量控制（TC）实验场景**，以 A/B 实验分组维度统计近 7 天的 NMV（网络成交额）及订单量指标，按曝光场景（搜索、推荐子场景）、是否广告、是否商品卡片等维度进行多维聚合。

**核心业务场景：**
- 评估各 A/B 实验组（TC 实验、推荐实验、流量管控实验等）在不同场景下对 GMV / NMV 的影响；
- 支持 Traffic Management、MKP RCMD 等项目的实验效果归因分析；
- 以 GROUPING SETS 展开多维切片（全量 / 广告维度 / 商品卡片维度 / 细粒度），满足多角度下钻需求。

**适合回答的典型问题：**
- 某实验组在近 7 天内、特定推荐场景下的 NMV 贡献是多少？
- 广告流量与自然流量在各实验分组中的 NMV 差异如何？
- 商品卡片曝光与非商品卡片曝光在实验组间的净订单量对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识（如 `ID`、`MY` 等），每次写入覆盖单个大区分区 |
| `local_date` | date | 本地业务日期，为滚动窗口的结束日期，动态分区写入 |

### 维度：实验分组信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，来源于 `abtest.shopee_experiment_admin_db__group_dimension_tab` |
| `exp_group_type` | int | 实验分组类型，来源于 `srdi_mart.dim_sr_data_warehouse_tc_exp_rule` |
| `layer_id` | bigint | 实验所属层 ID，标识实验层归属（如 cheapest replace 层、TC hold-out 层等） |
| `rule_ids` | string | 实验规则 ID 列表；ETL 中固定写入 `null`，暂未填充 |

### 维度：曝光场景信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 场景名称映射（如搜索、推荐各子场景），已排除 `Video` 与 `Live Streaming` |
| `is_ads` | string | 是否广告流量；`__ALL__` 表示该行为全量聚合（不区分广告/非广告） |
| `is_item_card` | string | 是否商品卡片曝光；`__ALL__` 表示该行为全量聚合（不区分商品卡片类型） |

### 指标：交易成交指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `nmv` | double | 近 7 天净成交额（美元，统一货币），为该分组 + 场景维度下所有用户的汇总值 |
| `nmv_local` | double | 近 7 天净成交额（本地货币） |
| `net_order_cnt` | double | 近 7 天净订单数，为正向订单扣除退款后的净值 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能。示例：`WHERE grass_region = 'ID'`。
- **`local_date`**：建议同时指定，避免读取多个历史滚动窗口导致数据重复叠加。示例：`AND local_date = '2024-06-01'`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `nmv` / `nmv_local` / `net_order_cnt` | 表内已按 GROUPING SETS 展开多维聚合，同一 `(exp_group_id, local_date)` 下存在多条不同维度切片（全量行 + 细粒度行），**直接 SUM 会导致重复计数**。查询时需严格限定 `is_ads` 与 `is_item_card` 的取值或只取某一特定维度切片 |
| `nmv` / `nmv_local` / `net_order_cnt` | 本表为近 7 天滚动窗口，每个 `local_date` 分区存储的是该日期前 7 天的汇总结果，**跨多个 `local_date` SUM 会产生时间窗口重叠，导致重复计算** |

### 时效性说明

- 数据为 **T+1 每日更新**，`local_date` 最新分区通常反映前一自然日的数据。
- 本表为 **r7d（近 7 天滚动窗口）** 聚合表，每日 INSERT OVERWRITE 覆盖写入，单个分区内指标已对过去 7 天求和，不代表单日数据。
- `rule_ids` 字段当前恒为 `null`，请勿依赖该字段进行过滤或关联。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_tc_exp_rule` | 提供实验分组的规则信息，包括 `exp_group_type` 和 `rule_ids`，按 `regional_date` 过滤当日快照 |
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 提供实验分组与实验层的对应关系（`group_id`、`layer_id`、`scene_name`），并按白名单层 ID 筛选 TC 相关实验 |
| `szci_traffic.shopee_traffic_mangement_db__layer_tab__reg_continuous_s0_live` | 提供 Traffic Management 项目的合法实验层 ID 列表，用于过滤实验层范围 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 提供用户与实验分组的分配记录，取近 7 天内已正式分配（`is_assignment_log = 1`）的数据 |
| `srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_aggr_r7d_1d` | 提供用户粒度、场景粒度的近 7 天 NMV 及净订单量基础指标，按站点和日期范围过滤，排除 Video、Live Streaming 场景 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_tc_exp_rule          ─┐
abtest group_dimension_tab                  ├─► [exp_info] 实验分组白名单 & 元数据
szci_traffic layer_tab                     ─┘
                                                        │
dim_sr_data_warehouse_abtest_user_group ──► [user_exp_raw] 用户实验分配（近7天）
                                                        │
                                            JOIN [exp_info] ─► [user_exp] 有效用户实验分配
                                                        │
dws_sr_data_warehouse_tc_nmv_basic_aggr_r7d_1d          │
    GROUPING SETS 多维展开                               │
                                            JOIN [user_exp] ─► [every_scene_data] 用户级场景指标
                                                        │
                                            GROUP BY 聚合 ─► [scene_aggr_data] 分组级场景汇总
                                                        │
                                            LEFT JOIN [exp_info] 补充元数据
                                                        │
                                              INSERT OVERWRITE 目标表
```

### 关键步骤

1. **`tc_exp_rule`（Temporary View）**：从 `dim_sr_data_warehouse_tc_exp_rule` 按当日 `regional_date` 快照过滤，获取实验规则元数据。

2. **`exp_info`（CACHE TABLE）**：关联 A/B 实验分组表与实验规则表，按白名单 `layer_id`（涵盖 Traffic Management、MKP RCMD 项目层及指定的 TC 特殊实验层）筛选，并排除历史废弃层，得到本次计算使用的有效实验分组集合。

3. **`user_exp_raw`（Temporary View）**：从用户实验分配维表中读取目标站点近 7 天（`date_sub(local_date, 7)` 至 `local_date`）的正式分配记录（`is_assignment_log = 1`）。

4. **`user_exp`（Temporary View）**：将 `user_exp_raw` 与 `exp_info` 做 INNER JOIN（Broadcast join），过滤掉不在白名单内的实验分组，保留有效用户实验分配。

5. **`every_scene_data`（Temporary View）**：从基础 NMV 表读取近 7 天用户级场景指标，通过 GROUPING SETS 展开 4 种维度组合（`is_ads` × `is_item_card` 全量/细粒度），排除 Video 和 Live Streaming 场景后与 `user_exp` 按 `user_id` + `local_date` JOIN，得到用户-实验-场景级明细。

6. **`scene_aggr_data`（Temporary View）**：对 `every_scene_data` 按 `(exp_group_id, is_ads, is_item_card, mapping_general, local_date)` 分组求和，汇总为分组级场景指标。

7. **INSERT OVERWRITE（目标表写入）**：将 `scene_aggr_data` LEFT JOIN `exp_info` 补充 `exp_group_type`、`layer_id` 等元数据，`rule_ids` 固定写入 `null`，按 `grass_region` + `local_date` 动态分区覆盖写入目标表。

### 注意事项

- **Multi-writer**：本表为单文件写入（`multi_writer: false`），不存在多进程并发写入同一物理表的风险。
- **动态分区覆盖**：使用 `INSERT OVERWRITE ... PARTITION (grass_region = ${grass_region}, local_date)` 动态写入，每次执行仅覆盖当前 `grass_region` 下涉及的 `local_date` 分区，不影响其他大区数据。
- **GROUPING SETS 多行展开**：ETL 中对 `is_ads` 和 `is_item_card` 使用 GROUPING SETS 生成全量聚合行（`__ALL__`）和细粒度行，目标表中同一实验分组 + 场景存在多条记录，查询时须明确限定维度取值，避免重复计算。
- **`rule_ids` 字段**：ETL 中明确写入 `null`，字段保留作为预留扩展，当前不可用于过滤或业务计算。
- **参数化模板**：SQL 中 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等为运行时参数，由调度系统注入；各 Temporary View 名称含站点后缀，保证多站点并发执行时隔离。

---

*文档生成时间：2026-05-17*