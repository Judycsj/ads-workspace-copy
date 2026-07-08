<!-- ads-workspace-gdoc-sync: gdoc_id=1FUB2OGn5HJaWqYbrjuZE03SIOS7vm57lFamHNm0VPjQ gdoc_url=https://docs.google.com/document/d/1FUB2OGn5HJaWqYbrjuZE03SIOS7vm57lFamHNm0VPjQ/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_antifraud_exp_level_order_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `is_ads` + `scenario_tag` + `exp_type` + `grass_region` + `local_date`
**分区：** `exp_type` / `grass_region` / `local_date`
**更新频率：** 每日全量覆盖（INSERT OVERWRITE，按分区）
**引用频次 / 访问频次：** 2593

---

## 业务描述

本表面向**搜索推荐平台 A/B 实验**场景，以**实验组（exp_group_id）× 是否广告（is_ads）× 场景标签（scenario_tag）× 日期**为粒度，汇总**近 7 日滑动窗口**的订单量与 GMV 指标，并叠加**反欺诈过滤**维度，提供去除刷单/羊毛党后的净化版订单指标。

**核心业务场景：**
- 搜索 A/B 实验效果评估：按实验组对比订单量与 GMV 的变化；
- 广告与自然流量分桶对比：通过 `is_ads` 区分广告订单与非广告订单；
- 反欺诈影响分析：对比 `order_cnt` / `gmv` 与 `rm_fraud_order_cnt` / `rm_fraud_gmv`，评估刷单对实验结论的干扰程度；
- 多场景维度下钻：通过 `scenario_tag` 拆解全局搜索、推荐等不同场景的订单贡献。

**适合回答的问题举例：**
- 某实验组在过去 7 天内（相对于统计日）的搜索订单量与 GMV 是多少？去除欺诈订单后结论是否变化？
- 广告流量与自然流量在各实验组之间的 GMV 差异如何？
- 某场景标签（如 Global Search）在各实验组的贡献占比是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验类型，标识 ETL 写入方式；当前仅有 `assign_log_join` 一个分区值，表示通过用户分配日志关联行为数据的方式聚合 |
| `grass_region` | string | 大区/市场标识（如 `TH`、`VN` 等），与上游表保持一致 |
| `local_date` | date | 统计日期，为汇总窗口的最后一天（即数据涵盖 `[local_date-6, local_date]` 共 7 天） |

### 维度：实验与流量属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验组 ID，来源于实验平台用户分桶日志；每个 ID 对应一个具体的实验分组 |
| `is_ads` | string | 是否广告订单，取值为 `'true'` 或 `'false'`；来源于行为宽表的 `is_ads` 字段 |
| `scenario_tag` | string | 场景标签，用于区分不同流量来源/业务场景（如 `Global Search`、具体 algo_tag 等）；特殊值 `'__ALL__'` 表示该实验组下全部场景的汇总行 |

### 指标：订单量与 GMV（含反欺诈口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 实验组在统计窗口内的总订单数（含欺诈订单），来源于行为宽表 `operation_cnt` 的累计求和 |
| `gmv` | double | 实验组在统计窗口内的总 GMV（含欺诈订单），来源于行为宽表 `place_order_gmv` 的累计求和；单位与上游保持一致 |
| `rm_fraud_order_cnt` | double | 去除欺诈订单后的净订单数；当订单在反欺诈表中命中刷单（Brushing）或滥用（Abuse）标签时被排除，仅统计未被标记的订单 |
| `rm_fraud_gmv` | double | 去除欺诈订单后的净 GMV；同 `rm_fraud_order_cnt`，仅对未被反欺诈标记的订单进行 GMV 累计 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，避免全量扫描。该字段为每日全量覆盖分区，建议精确指定日期或使用日期范围过滤。
- **`grass_region`**：必须指定目标市场，不同 region 数据独立写入，混合查询无业务意义。
- **`exp_type`**：当前固定为 `'assign_log_join'`，建议显式加上以利用分区裁剪。

示例：
```sql
WHERE exp_type = 'assign_log_join'
  AND grass_region = 'TH'
  AND local_date = '2025-01-01'
```

### 不可直接 SUM 的字段

- **`order_cnt` / `gmv` / `rm_fraud_order_cnt` / `rm_fraud_gmv`**：同一实验组在同一天存在 **`scenario_tag = '__ALL__'` 的汇总行** 与各具体 `scenario_tag` 的明细行，若不过滤 `scenario_tag` 直接 SUM，将导致**重复计算**。
  - 若需要实验组整体指标，使用 `scenario_tag = '__ALL__'` 的行；
  - 若需要场景维度拆解，使用 `scenario_tag != '__ALL__'` 的行，不要与汇总行混用。
- 本表指标均为**预聚合累计值**（7 日滑动窗口），不要对多个 `local_date` 直接 SUM，否则会产生重叠窗口的重复计数。

### 时效性说明

- 本表为 **`_1d` 后缀日表**，每日产出一次，数据时效性为 T+1。
- **窗口语义**：每个 `local_date` 分区的指标覆盖 `[local_date-6, local_date]` 共 **7 个自然日**的数据，为滑动窗口聚合，**非当日单日数据**。
- 如需单日数据，需通过两个相邻 `local_date` 的差值计算，或回溯上游 DWD 层表。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，提供用户与实验组的映射关系（筛选分配日志白名单用户） |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜索推荐平台行为宽表，提供订单行为数据（订单量、GMV、是否广告、场景标签等） |
| `szci_antifraud.dws_ob_online_s1_di` | 反欺诈标签表，提供订单维度的欺诈标签（0: Brushing 刷单，1: Abuse 滥用） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
                                           ├──► exp_group_data_filter（实验组×行为聚合）
dwd_sr_data_warehouse_platform ──────────┤         │
                                           │         ├──► feature_tag_data（场景标签展开）
szci_antifraud.dws_ob_online_s1_di ──────┘         │
                                                     ▼
                             目标表（UNION ALL 汇总行 + 场景明细行）
```

### 关键步骤

1. **`selected_user_exps`（Temporary View）**
   从实验分组维度表中筛选目标 `grass_region`、近 7 日内、满足 `is_assignment_log = 1` 且 `is_rcmd_search_whitelist = 1` 条件的用户-实验组映射关系。

2. **`behavior_data`（Temporary View）**
   从行为宽表中过滤 `operation = 'order'` 的记录，提取订单粒度的 `is_ads` 标识与多路场景标签数组（主归因、source1、source2），并按用户×订单×日期×is_ads×场景标签数组聚合订单量与 GMV。

3. **`order_antifraud_tag`（Temporary View）**
   从反欺诈表中拉取近 7 日内目标区域的订单反欺诈标签（Brushing / Abuse）。

4. **`behavior_data_joined`（Temporary View）**
   将行为数据与反欺诈标签进行 LEFT JOIN（以行为数据为主），合并三路场景标签数组（`array_union`），并按用户×is_ads×场景标签数组×日期聚合：
   - `rm_fraud_order_cnt` / `rm_fraud_gmv`：`antifraud_tag IS NULL` 时计入（即未被标记为欺诈的订单）；
   - `order_cnt` / `gmv`：全量统计（含欺诈订单）。

5. **`exp_group_data_filter`（Cached Table，`MEMORY_AND_DISK_SER`）**
   将行为数据与实验分组维度进行 INNER JOIN（按 `user_id` + `local_date`），过滤出属于实验白名单的用户订单，并按实验组×is_ads×场景标签数组×日期聚合四项指标。该中间结果被 Cache 以供后续两次读取复用。

6. **`feature_tag_data`（Temporary View）**
   对 `exp_group_data_filter` 的场景标签数组进行 `LATERAL VIEW EXPLODE` 展开，生成每个实验组×is_ads×单一场景标签×日期的聚合指标行。

7. **INSERT OVERWRITE（最终写入）**
   以 `exp_type = 'assign_log_join'`、目标 `grass_region`、`local_date` 为分区，写入目标表，数据由两部分 UNION ALL 合并：
   - **汇总行**：从 `exp_group_data_filter` 直接聚合，`scenario_tag` 固定为 `'__ALL__'`；
   - **明细行**：从 `feature_tag_data` 输出，包含各具体 `scenario_tag` 的指标。

### 注意事项

- **多写入风险**：本表为单 ETL 文件写入（`multi_writer: false`），但 `grass_region` 为参数化变量，实际生产中不同 region 的任务会分别执行，各自覆盖对应的 `grass_region` 分区，**不同 region 任务不应并发写入同一 `grass_region` 分区**。
- **`__ALL__` 与场景明细重复**：目标表同时存在 `scenario_tag = '__ALL__'` 的汇总行和具体场景标签的明细行，查询时必须区分使用，不能混合 SUM。
- **7 日滑动窗口**：上游三张表均使用 `date_add(date(${local_date}), -6)` 作为起始日期，窗口长度为 7 天，`local_date` 分区值代表窗口终止日。
- **反欺诈表 LEFT JOIN 语义**：欺诈判断以 `antifraud_tag IS NULL` 作为"干净订单"的判断条件，若反欺诈表存在数据延迟或缺失，可能导致 `rm_fraud_order_cnt` 虚高（误将欺诈订单统计为干净订单）。
- **Cache 策略**：`exp_group_data_filter` 使用 `MEMORY_AND_DISK_SER` 持久化，Job 执行期间需保证 Executor 有足够内存/磁盘空间，否则可能影响 ETL 性能。

---

*文档生成时间：2026-05-17*