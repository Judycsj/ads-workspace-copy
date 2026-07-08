<!-- ads-workspace-gdoc-sync: gdoc_id=1jPDaG1zhYbk79Nr3F_jAYyjQjCBKALei-VjdWCcqFpQ gdoc_url=https://docs.google.com/document/d/1jPDaG1zhYbk79Nr3F_jAYyjQjCBKALei-VjdWCcqFpQ/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `feature_group` + `outlier_type` + `percentile`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日一次（1d）
**访问频次：** 1627 次

---

## 业务描述

本表用于记录各广告流量入口（Feature Group）在指定站点、指定日期下，用户维度广告 ABS（Average Basket Size，客单价）的分位数异常阈值，包含直接广告（Direct Ads）和泛广告（Broad Ads）两种口径。

**核心业务场景：**
- 广告效果质量管控：识别 ABS 异常高值用户，用于反作弊、异常流量过滤或归因修正。
- 离群值检测（Outlier Detection）：为下游报表或模型提供 P95 / P99 / P99.5 / P99.9 四档分位数阈值，供异常判断使用。
- 各 Feature Group 独立建模：支持对 Search、YMAL、Daily Discover、Game 等入口分别制定异常阈值。

**适合回答的问题：**
- 某站点某日，Search 入口广告客单价的 P99 阈值是多少？
- 某站点下，`Cart Unify` 泛广告客单价的 P99.5 异常截断值是多少？
- 如何识别 ABS 异常偏高的广告用户？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域标识，如 `SG`、`MY` 等，用于数据分区隔离 |
| `local_date` | date | 业务日期，数据统计口径日期，格式 `YYYY-MM-DD` |

### 维度：流量入口与异常类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_group` | string | 广告流量入口分组，取值包括原子入口（如 `Search`、`You May Also Like`、`Daily Discover`、`Game`、`Cart Recommendation` 等）以及聚合入口（如 `Cart Unify`、`RCMD Unify`、`DD_PP Unify`、`Search_RCMD`、`YMAL_Cart`、`all`） |
| `outlier_type` | string | 异常类型口径，`direct_ads_abs` 表示直接广告客单价（ads_gmv / ads_order_cnt），`broad_ads_abs` 表示泛广告客单价（broad_gmv / broad_order_cnt） |

### 指标：分位数阈值

| 字段 | 类型 | 说明 |
|---|---|---|
| `percentile` | double | 分位数档位，取值为 `0.95`、`0.99`、`0.995`、`0.999`，对应 P95 / P99 / P99.5 / P99.9 |
| `abs` | double | 对应 `outlier_type` 和 `percentile` 下的 ABS（客单价，单位 USD）分位数阈值，由 `APPROX_PERCENTILE` 近似计算得出，仅统计 ABS > 0 的用户 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：本表按站点分区，查询时务必指定 `grass_region`，否则将触发全量扫描，严重影响性能。
- **`local_date`**：本表按日期分区，查询时务必指定具体日期，避免读取历史全量分区。

示例：
```sql
SELECT feature_group, outlier_type, percentile, abs
FROM srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d
WHERE grass_region = 'SG'
  AND local_date = '2024-01-01'
  AND outlier_type = 'direct_ads_abs'
  AND percentile = 0.99;
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `abs` | 分位数（近似百分位数），不可跨 `feature_group`、`outlier_type` 或 `percentile` 进行 SUM / AVG，无统计意义 |
| `percentile` | 档位标识，属于维度枚举值，不可聚合 |

- `abs` 字段由 `APPROX_PERCENTILE` 计算，是近似值，不代表精确分位数，不可用于精确统计。
- 各 `feature_group` 之间存在包含关系（如 `RCMD Unify` 包含多个原子入口），跨 `feature_group` 聚合会导致重复计算。

### 时效性说明

- 本表为 **每日全量覆盖写入（INSERT OVERWRITE）**，当日分区数据在当天 ETL 完成后可用。
- 数据反映 `local_date` 当日的用户级广告表现，不包含历史累计数据。
- 分位数基于当日用户样本近似计算，不同日期阈值独立，不可跨日合并使用。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 提供用户粒度、入口粒度的广告订单量、广告 GMV、泛广告 GMV 等基础指标，作为 ABS 计算和分位数统计的数据源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d
    │
    ▼
dwd_ads_performance（用户×入口级汇总，过滤无效用户）
    │
    ▼
dwm_ads_performance（入口编码映射为 feature_group 名称）
    │
    ▼
dws_ads_performance（扩展聚合入口：Cart Unify、RCMD Unify）
    │
    ▼
dws_ads_performance_extended（进一步扩展：DD_PP Unify、Search_RCMD、YMAL_Cart、all）
    │
    ▼
dws_abs（计算用户×feature_group 级 ABS 和 broad_abs）
    │
    ▼
approx_pct（按 feature_group 计算 APPROX_PERCENTILE，输出 4 档分位数数组）
    │
    ▼
INSERT OVERWRITE → ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `dwd_ads_performance` | 从上游 DWS 表按 `grass_region`、`local_date` 过滤，按用户×入口汇总广告订单和 GMV，HAVING 过滤掉无广告行为用户 |
| Step 2 | `dwm_ads_performance` | 将 entrance 编码映射为可读 feature_group 名称（Search、YMAL、Game、Daily Discover 等），过滤掉未覆盖的 entrance 值 |
| Step 3 | `dws_ads_performance` | 在原子 feature_group 基础上，UNION ALL 追加 `Cart Unify`（购物车系推荐场景合并）和 `RCMD Unify`（所有推荐场景合并）两个聚合视图 |
| Step 4 | `dws_ads_performance_extended` | 继续 UNION ALL 追加 `DD_PP Unify`（Daily Discover + Cart Unify）、`Search_RCMD`（Search + RCMD Unify）、`YMAL_Cart`（YMAL 系入口合并）、`all`（全量入口汇总，来自 dwd 层） |
| Step 5 | `dws_abs` | 按用户×feature_group 计算 `abs = ads_gmv_usd / ads_order_cnt`，`broad_abs = broad_gmv_usd / ads_broad_order_cnt`，除零时默认为 0 |
| Step 6 | `approx_pct` | 按 feature_group 分组，对 abs > 0 的样本用 `APPROX_PERCENTILE` 计算 P95/P99/P99.5/P99.9 数组 |
| Step 7 | **INSERT OVERWRITE** | 使用 `POSEXPLODE` 将分位数数组展开为行，分别对 `direct_ads_abs`（abs_pct）和 `broad_ads_abs`（broad_abs_pct）UNION ALL 后写入目标表的指定分区 |

### 注意事项

- **multi-writer：** 本表为单文件写入（`multi_writer = false`），无并发写入风险。
- **分区写入：** 每次执行为 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 覆盖写入，同一分区数据会被完整替换，重跑幂等性良好。
- **近似分位数：** `abs` 字段由 `APPROX_PERCENTILE` 计算，存在一定精度误差，不适用于需要精确分位数的场景。
- **ABS 零值过滤：** 分位数计算时使用 `IF(abs > 0, abs, '')` 过滤零值，仅基于有效客单价用户样本，需注意小样本 feature_group 场景下的稳定性。
- **Feature Group 包含关系：** `Cart Unify`、`RCMD Unify`、`all` 等聚合入口与原子入口之间存在用户重叠，查询时应明确选择所需粒度，避免双重计数。
- **entrance 覆盖范围：** `dwm` 层仅覆盖白名单 entrance 编码，上游 DWD 层中其他 entrance 值会被过滤丢弃（但 `all` 来自 DWD 层，仍包含全部 entrance）。

---

*文档生成时间：2026-05-17*