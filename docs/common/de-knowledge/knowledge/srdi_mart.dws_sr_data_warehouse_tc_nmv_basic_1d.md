<!-- ads-workspace-gdoc-sync: gdoc_id=1E4WTEmvP57aWCYpBykQj7xlmIJ-WJb3tIrSUyj6ljIw gdoc_url=https://docs.google.com/document/d/1E4WTEmvP57aWCYpBykQj7xlmIJ-WJb3tIrSUyj6ljIw/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_1d

**分层：** DWS（数据汇总层）
**主键：** shop_id + item_id + model_id + user_id + is_ads + source1_is_ads + source2_is_ads + feature_detail + source1_feature_detail + source2_feature_detail + feature_group + reporting_business_line + reporting_module + reporting_object + source1_feature_group + source1_reporting_business_line + source1_reporting_module + source1_reporting_object + source2_feature_group + source2_reporting_business_line + source2_reporting_module + source2_reporting_object + grass_region + local_date + local_hour
**分区：** grass_region（站点大区）/ local_date（业务日期）/ local_hour（业务小时）
**更新频率：** 每日一次（按天覆盖写入，覆盖范围为近 31 天数据）
**引用频次 / 访问频次：** 196

---

## 业务描述

本表是搜索与推荐（Search & Recommendation）数据仓库中，面向**成交 NMV（Net Merchandise Value）基础指标**的日粒度汇总宽表，是 SRDI 体系中 TC（Transaction / 成交）维度的核心汇总层。

**核心业务场景：**
- 衡量搜推各流量入口（reporting_object/module/business_line）在不同时间粒度下的成交净订单量与成交 NMV 贡献。
- 支持对广告（is_ads）与自然流量、不同归因来源（source1/source2）下的 NMV 拆分分析。
- 支持按商品（item_id/model_id）、店铺（shop_id）、用户（user_id）、特征组（feature_group/feature_detail）进行多维成交归因分析。
- 提供本地化货币（nmv_local）与标准货币（nmv）双口径成交金额，满足跨国/多站点对比需求。

**适合回答的问题：**
- 某大区某日/某小时，搜推各模块带来的净 NMV 是多少？
- 广告流量与自然流量的成交净订单数和 NMV 各占多少？
- 特定特征组（feature_group）下各商品/模型的成交表现如何？
- 某店铺在不同归因来源（source1/source2）下的 NMV 贡献如何拆分？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 SG、MY、TH 等），用于多站点数据隔离，写入时由调度参数 `${grass_region}` 指定 |
| `local_date` | date | 业务本地日期，数据覆盖范围为当前运行日前推 30 天至当日（共 31 天） |
| `local_hour` | int | 业务本地小时（0–23），支持小时粒度下钻分析 |

### 维度：商品与交易主体

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | 商品 SKU/规格 ID（model 级别） |
| `user_id` | bigint | 用户 ID |

### 维度：广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 当前归因链路是否为广告流量 |
| `source1_is_ads` | boolean | 归因来源1 是否为广告流量 |
| `source2_is_ads` | boolean | 归因来源2 是否为广告流量 |

### 维度：特征信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_group` | string | 当前归因的特征组，标识触发成交的搜推特征类别 |
| `feature_detail` | string | 当前归因的特征详情，feature_group 的细分描述 |
| `source1_feature_group` | string | 归因来源1 的特征组 |
| `source1_feature_detail` | string | 归因来源1 的特征详情 |
| `source2_feature_group` | string | 归因来源2 的特征组 |
| `source2_feature_detail` | string | 归因来源2 的特征详情 |

### 维度：搜推业务归因

| 字段 | 类型 | 说明 |
|---|---|---|
| `reporting_business_line` | string | 当前归因的业务线，如搜索、推荐等 |
| `reporting_module` | string | 当前归因的模块，业务线下细分模块 |
| `reporting_object` | string | 当前归因的上报对象，模块下的具体流量位或功能对象 |
| `source1_reporting_business_line` | string | 归因来源1 的业务线 |
| `source1_reporting_module` | string | 归因来源1 的模块 |
| `source1_reporting_object` | string | 归因来源1 的上报对象 |
| `source2_reporting_business_line` | string | 归因来源2 的业务线 |
| `source2_reporting_module` | string | 归因来源2 的模块 |
| `source2_reporting_object` | string | 归因来源2 的上报对象 |

### 指标：成交核心指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `net_order_cnt` | double | 净订单数（退款订单已扣除），由上游 DWD 层 `net_order_cnt` 按维度聚合 SUM 所得 |
| `nmv` | double | 净成交金额（标准货币口径，通常为 USD），由上游 DWD 层 `nmv` 按维度聚合 SUM 所得 |
| `nmv_local` | double | 净成交金额（本地货币口径），由上游 DWD 层 `nmv_local` 按维度聚合 SUM 所得，适用于本地化报表 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，必须指定具体站点大区以避免全表扫描。
- **`local_date`**：分区字段，必须指定日期范围。本表每次刷新覆盖近 31 天数据（当日及过去 30 天），查询历史数据请确认分区实际存在。
- **`local_hour`**：分区字段，若仅需天级汇总，需在 WHERE 条件中指定特定小时或在 GROUP BY 中显式聚合所有小时值。

**典型过滤示例：**
```sql
WHERE grass_region = 'SG'
  AND local_date = '2026-05-17'
```

### 不可直接 SUM 的字段

- 本表 `net_order_cnt`、`nmv`、`nmv_local` 均为按全维度组合聚合后的预聚合指标，在使用时需注意：
  - 若查询维度少于表中所有分组维度（例如仅按 `shop_id` 汇总），可以直接 SUM，但需确保 GROUP BY 覆盖所有未聚合的维度，避免重复计算。
  - **跨 `local_hour` 汇总天级数据**时，直接 SUM 各小时数据即可，但需确认上游 DWD 层的小时分区逻辑无重叠写入。
  - 不同归因来源（source1/source2）的 NMV 可能存在**归因重叠**，避免将 source1 与 source2 口径直接叠加汇总，以免双重计数。

### 时效性说明

- 本表为 **每日离线批量写入**（`INSERT OVERWRITE`），T+1 可用，不提供实时或准实时数据。
- 每次调度覆盖写入 `local_date BETWEEN date_sub(${local_date}, 30) AND ${local_date}`，共 **31 天滚动窗口**，历史分区数据会被覆盖刷新，查询时请注意数据以最新刷新结果为准。
- 表名后缀 `_1d` 表示基础粒度为天级，但分区含 `local_hour`，实际最细粒度为小时。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_nmv` | 搜推平台 NMV 明细层，提供成交订单的全维度明细数据，包含净订单数、NMV（标准/本地货币）及所有归因维度字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform_nmv
    └─ 过滤指定大区 & 近 31 天日期范围
        └─ 按全维度组合 GROUP BY
            └─ SUM(net_order_cnt / nmv / nmv_local)
                └─ INSERT OVERWRITE
                    └─ srdi_mart.dws_sr_data_warehouse_tc_nmv_basic_1d
                       分区：grass_region / local_date / local_hour
```

### 关键步骤

1. **过滤上游数据**：从 `dwd_sr_data_warehouse_platform_nmv` 中筛选满足 `grass_region IN (${grass_region})` 且 `local_date BETWEEN date_sub(${local_date}, 30) AND ${local_date}` 的记录，覆盖滚动 31 天窗口。

2. **多维聚合**：以 shop_id、item_id、model_id、user_id、is_ads 系列（含 source1/source2）、feature_detail 系列、feature_group 系列、reporting 三级归因系列（含 source1/source2）、local_date、local_hour 共 23 个字段为 GROUP BY 键，对 `net_order_cnt`、`nmv`、`nmv_local` 执行 SUM 聚合。

3. **分区覆盖写入**：以 `INSERT OVERWRITE ... PARTITION(grass_region = ${grass_region}, local_date, local_hour)` 方式写入目标表，`grass_region` 为静态分区（由调度参数决定），`local_date` 和 `local_hour` 为动态分区。

### 注意事项

- **单 ETL 文件，无 multi-writer 风险**：本表仅由一个 SQL 文件写入，不存在多文件并发写入同一分区的冲突风险。
- **动态分区写入**：`local_date` 和 `local_hour` 均为动态分区，单次调度会覆盖近 31 天内所有日期和小时的分区数据，请确保 Spark 动态分区配置（如 `hive.exec.dynamic.partition.mode=nonstrict`）已正确设置。
- **滚动窗口覆盖**：每次调度覆盖写入 31 天数据，历史分区数据会被重新刷新，若上游 DWD 层数据发生回刷，本表数据会在下次调度后自动同步修正。
- **草稿分区参数**：`${grass_region}` 和 `${local_date}` 均为调度注入的运行时参数，不同站点需分别触发调度任务。

---

*文档生成时间：2026-05-17*