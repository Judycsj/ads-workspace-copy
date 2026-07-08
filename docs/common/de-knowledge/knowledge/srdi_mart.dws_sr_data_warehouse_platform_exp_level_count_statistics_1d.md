<!-- ads-workspace-gdoc-sync: gdoc_id=1D86vdCIX50HZb7OxXQhZL3WvNn_DPL0bb_ij9vuOiFs gdoc_url=https://docs.google.com/document/d/1D86vdCIX50HZb7OxXQhZL3WvNn_DPL0bb_ij9vuOiFs/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_level_count_statistics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `exp_type` + `platform` + `is_ads` + `scenario_tag` + `exp_group_id`
**分区：** `grass_region`（大区）/ `local_date`（业务日期）/ `exp_type`（实验类型，枚举值：`traffic`、`assign_log_join`、`dim_join`）
**更新频率：** 每日（1d）
**访问频次：** 28 次

---

## 业务描述

本表为搜推数据仓库平台（SR Data Warehouse Platform）的**实验组级别**（Experiment Level）用户行为指标汇总表，以天为粒度记录各实验组在不同平台、场景下的核心漏斗 UV 数据。

**核心业务场景：**
- A/B 实验效果评估：按实验组（`exp_group_id`）对比各组在曝光、点击、加购、下单等关键路径上的用户规模；
- 多实验类型横向对比：支持流量实验（`traffic`）、分配日志关联实验（`assign_log_join`）、维度关联实验（`dim_join`）三种实验类型的统一查询；
- 平台 × 广告 × 场景多维下钻：结合 `platform`、`is_ads`、`scenario_tag` 进行细分分析。

**适合回答的问题：**
- 某实验组在某天的曝光用户数、点击用户数分别是多少？
- 各实验组的加购漏斗转化用户规模如何对比？
- 特定场景标签下，广告与非广告流量的订单 UV 差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区（地理分区），如 `SG`、`MY` 等，用于数据分区隔离 |
| `local_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd` |
| `exp_type` | string | 实验类型，枚举值：`traffic`（流量实验）、`assign_log_join`（分配日志关联实验）、`dim_join`（维度关联实验） |

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 终端平台，如 `android`、`ios`、`web` 等 |
| `is_ads` | string | 是否为广告流量，标识当前流量的广告属性 |
| `scenario_tag` | string | 场景标签，标识具体业务场景（如首页、搜索、推荐等） |
| `exp_group_id` | int | 实验组 ID，唯一标识 A/B 实验中的某个实验分组 |

### 指标：用户行为漏斗 UV

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 曝光去重用户数（Impression Unique Users），当日发生曝光行为的 UV |
| `click_uu` | bigint | 点击去重用户数（Click Unique Users），当日发生点击行为的 UV |
| `ppv_uu` | bigint | 商品详情页访问去重用户数（Product Page View Unique Users） |
| `cart_uu` | bigint | 加购去重用户数（Add-to-Cart Unique Users），当日发生加购行为的 UV |
| `order_uu` | bigint | 下单去重用户数（Order Unique Users），当日发生下单行为的 UV |
| `item_imp_uu` | bigint | 商品曝光去重用户数（Item Impression Unique Users） |
| `item_click_uu` | bigint | 商品点击去重用户数（Item Click Unique Users） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，查询时必须指定，否则触发全分区扫描，产生高额计算成本。
- **`local_date`**：分区字段，查询时必须指定具体日期或日期范围。
- **`exp_type`**：分区字段，三个取值（`traffic`、`assign_log_join`、`dim_join`）对应不同的实验口径，**跨类型混合查询前须确认业务含义一致**，避免数据重复叠加。

示例过滤：
```sql
WHERE grass_region = 'SG'
  AND local_date = '2025-05-16'
  AND exp_type = 'traffic'
```

### 不可直接 SUM 的字段

以下所有指标字段均为**去重用户数（UV）**，在多个维度（如 `platform`、`scenario_tag`）之间**不可直接累加求和**，跨维度汇总会导致重复计数：

- `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`item_imp_uu`、`item_click_uu`

> ⚠️ 如需跨维度汇总，须回溯至明细层或基础指标层重新计算去重 UV，不可在本表基础上 SUM。

### 时效性说明

- 本表为**日粒度**（`_1d`）汇总表，数据反映截至 `local_date` 当天的完整行为汇总。
- 数据通常在次日完成写入，**不支持实时/当日查询**，请使用 `local_date = current_date - 1` 获取最新数据。
- 不同 `exp_type` 分区由独立 ETL 任务写入，各分区数据就绪时间可能略有差异。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d` | 实验基础指标宽表，提供各实验类型下所有维度组合的 UV 指标；本表通过过滤 `target_type = '__ALL__'` 且 `feature_detail = '__ALL__'` 从中抽取实验组级别的汇总数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d
    │
    ├─ [过滤 exp_type='traffic',       target_type='__ALL__', feature_detail='__ALL__'] ──► 分区 exp_type='traffic'
    ├─ [过滤 exp_type='assign_log_join', target_type='__ALL__', feature_detail='__ALL__'] ──► 分区 exp_type='assign_log_join'
    └─ [过滤 exp_type='dim_join',       target_type='__ALL__', feature_detail='__ALL__'] ──► 分区 exp_type='dim_join'
                                                                                              │
                                          srdi_mart.dws_sr_data_warehouse_platform_exp_level_count_statistics_1d
```

### 关键步骤

1. **Source 1（exp_type = 'traffic'）**
   - 从上游基础指标表中过滤出 `exp_type = 'traffic'`、`target_type = '__ALL__'`、`feature_detail = '__ALL__'` 的汇总行；
   - 选取维度字段（`platform`、`is_ads`、`scenario_tag`、`exp_group_id`）和 7 个 UV 指标字段；
   - `INSERT OVERWRITE` 写入目标表 `exp_type = 'traffic'` 分区。

2. **Source 2（exp_type = 'assign_log_join'）**
   - 逻辑与 Source 1 完全对称，仅 `exp_type` 过滤值变更为 `'assign_log_join'`；
   - `INSERT OVERWRITE` 写入目标表 `exp_type = 'assign_log_join'` 分区。

3. **Source 3（exp_type = 'dim_join'）**
   - 逻辑与 Source 1 完全对称，仅 `exp_type` 过滤值变更为 `'dim_join'`；
   - `INSERT OVERWRITE` 写入目标表 `exp_type = 'dim_join'` 分区。

### 注意事项

- **Multi-writer 风险**：三个 ETL 文件并发写入**同一物理表的不同 `exp_type` 分区**，各分区间相互独立，正常情况下无冲突；但若调度系统同时触发，需确认分区级别写锁机制已生效，避免分区覆盖互相干扰。
- **`INSERT OVERWRITE` 语义**：每次执行均会覆盖对应 `(grass_region, local_date, exp_type)` 分区的全量数据，重跑安全，但需注意三个分区任务完整成功才算当日数据就绪。
- **过滤条件语义**：上游表 `target_type = '__ALL__'` 且 `feature_detail = '__ALL__'` 代表不分目标类型和特征细节的全量汇总行，本表仅消费该层级，下钻分析请回溯上游宽表。
- **上游依赖**：本表完全依赖 `dws_sr_data_warehouse_platform_exp_base_metrics_1d`，若上游当日数据缺失或延迟，三个分区数据均不可用。

---

*文档生成时间：2026-05-17*