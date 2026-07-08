<!-- ads-workspace-gdoc-sync: gdoc_id=13EKet-vnWpru8b9OvXSJI1hv5fXsgpoSNqEuKV2cGxk gdoc_url=https://docs.google.com/document/d/13EKet-vnWpru8b9OvXSJI1hv5fXsgpoSNqEuKV2cGxk/edit -->

# mp_paidads.dws_advertiser_livestream_revenue_1d

**分层**：DWS（数据服务层）
**主键**：`shop_id` + `streamer_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：18 次（候选表范围内统计）

---

## 业务描述

本表记录广告主维度下，各直播间（主播）在单自然日内的广告收入（消耗）明细，涵盖付费消耗与免费消耗，以及是否含过期金额的多种口径。表名中的"revenue"在此语境下特指广告主侧的广告消耗支出，即广告主在直播场景下的花费金额。

核心使用场景包括：广告主直播投放的日粒度消耗分析、付费 vs 免费额度拆解、含/不含过期消耗的口径对比，以及跨地区的广告消耗汇总。下游可基于本表进行广告主经营健康度评估、主播维度的广告效果归因和大盘 GMV 监控。

本表同时提供本地时区（`tz_type = 'local'`）和地区时区（`tz_type = 'regional'`）两套口径的数据，通过参数化调度覆盖所有上线地区，各地区按本地时区参数化调度写入对应分区，以满足不同报表口径的统计需求。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区口径类型。`local`：按各地区本地时区统计；`regional`：按地区区域时区统计。查询时**必须**指定该字段，否则数据翻倍。⚠️ 同一天同一地区存在两个分区值，直接聚合将导致重复计算。 |
| `grass_region` | string | 地区编码，大写字母，如 `US`、`GB`、`ID` 等，通过调度参数 `${region}` 参数化写入，覆盖所有上线地区。 |
| `grass_date` | date | 数据统计日期（自然日），格式 `YYYY-MM-DD`。查询时**必须**指定，避免全表扫描。 |

### 维度：主键与广告主属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 广告主店铺 ID，与 `streamer_id` 联合构成本表的业务主键。 |
| `streamer_id` | bigint | 直播间主播 ID，来源于 `livestream.ls_mart_dim_streamer`，通过 `shop_id` 关联补全。 |
| `streamer_type` | int | 主播类型编码，具体枚举值参见维度表 `ls_mart_dim_streamer`，0/1 等不同值代表不同主播身份类型。 |

### 指标：广告消耗总额

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_expenditure_amt_local_1d` | double | 当日广告消耗总额（本地货币），含付费与免费消耗之和。 |
| `total_expenditure_amt_usd_1d` | double | 当日广告消耗总额（USD），含付费与免费消耗之和。 |

### 指标：付费消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_wo_expiry_amt_local_1d` | double | 当日付费消耗金额（本地货币），**不含**过期消耗部分（wo = without expiry）。 |
| `paid_expenditure_wo_expiry_amt_usd_1d` | double | 当日付费消耗金额（USD），不含过期消耗。 |
| `paid_expenditure_w_expiry_amt_local_1d` | double | 当日付费消耗金额（本地货币），**含**过期消耗部分（w = with expiry）。 |
| `paid_expenditure_w_expiry_amt_usd_1d` | double | 当日付费消耗金额（USD），含过期消耗。 |

### 指标：免费消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_expenditure_wo_expiry_amt_local_1d` | double | 当日免费消耗金额（本地货币），不含过期消耗。⚠️ ETL 中发现此字段被误写为 `sum(paid_expenditure_w_expiry_amt_usd_1d)`（付费含过期 USD 列），存在潜在数据口径错误，使用时须注意与上游源表核对。 |
| `free_expenditure_wo_expiry_amt_usd_1d` | double | 当日免费消耗金额（USD），不含过期消耗。 |
| `free_expenditure_w_expiry_amt_local_1d` | double | 当日免费消耗金额（本地货币），含过期消耗。 |
| `free_expenditure_w_expiry_amt_usd_1d` | double | 当日免费消耗金额（USD），含过期消耗。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描或数据重复：

| 分区字段 | 推荐用法示例 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | `tz_type = 'local'`（推荐统一使用本地时区口径） | 数据量翻倍，`local` 与 `regional` 两套数据混合聚合，结果严重偏大 |
| `grass_region` | `grass_region = 'US'` | 全地区数据聚合，失去地区隔离 |
| `grass_date` | `grass_date = '2025-04-01'` | 全量历史数据扫描，性能极差，且数据无业务意义 |

> 建议在所有查询模板中将上述三个字段设为**必填参数**，禁止缺省。

### 不可直接 SUM 的字段

本表所有指标字段为**日粒度预聚合值**，以下几点需特别注意：

1. **跨 `tz_type` 聚合**：`local` 与 `regional` 分区中存储的是同一批数据写入的两套副本，若不过滤 `tz_type`，直接 SUM 所有消耗指标将导致**数值翻倍**。
2. **`wo_expiry` vs `w_expiry` 口径混用**：`paid_expenditure_wo_expiry` 和 `paid_expenditure_w_expiry` 含义不同，不可混加后作为"付费消耗"使用，需根据业务需求选择单一口径。
3. **`free_expenditure_wo_expiry_amt_local_1d` 字段**：ETL 中存在疑似字段映射错误（源列为 `paid_expenditure_w_expiry_amt_usd_1d`），**建议在使用该字段前与数据生产方确认口径**，或直接从上游表 `mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live` 取值验证。

### 时效性说明

- 本表为 T+1 更新，最新数据分区为**昨日**（即调度日 - 1）。
- 查询最新当日数据时，应使用 `grass_date = CURRENT_DATE - 1`，直接查询当天分区可能为空。
- `streamer_id` 与 `streamer_type` 来源于维度快照表 `ls_mart_dim_streamer` 当日切片，历史回溯时主播属性以写入当天的快照为准，不反映主播类型的历史变更。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live` | 广告主店铺维度的直播消耗明细数据，按 `shop_id` 聚合后作为主数据源 |
| `livestream.ls_mart_dim_streamer` | 主播维度快照表，提供 `streamer_id`、`streamer_type` 与 `shop_id` 的关联关系 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live
  （按 shop_id 聚合各消耗指标）
          │
          │  LEFT JOIN（on shop_id）
          │
livestream.ls_mart_dim_streamer
  （过滤地区/日期/tz_type=local，补全 streamer_id、streamer_type）
          │
          ▼
     [cache] base_data_local
          │
          ├──► INSERT OVERWRITE tz_type='local' 分区
          │
          └──► INSERT OVERWRITE tz_type='regional' 分区
                    │
                    ▼
mp_paidads.dws_advertiser_livestream_revenue_1d__reg_s0_live
（同时维护 __${region}_s0_live 区域独立外表视图，通过 location 指向同一 Parquet 文件）
```

### 关键 CTE 说明

| 视图/缓存 | 来源表 | 作用 |
|-----------|--------|------|
| `dim_ls` | `livestream.ls_mart_dim_streamer` | 按地区、日期过滤，取当日主播维度快照，提供 `streamer_id`、`shop_id`、`streamer_type` 映射关系 |
| `base_data_local` | `mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live` + `dim_ls` | 上游消耗数据按 `shop_id` 聚合后，LEFT JOIN 补全主播属性，缓存为临时表供两次 INSERT 复用 |

### 注意事项

1. **疑似字段映射 Bug**：ETL 中 `free_expenditure_wo_expiry_amt_local_1d` 的 SELECT 表达式为 `sum(paid_expenditure_w_expiry_amt_usd_1d)`，即使用了"付费消耗含过期 USD"的列填充"免费消耗不含过期本地货币"字段。这很可能是复制粘贴时产生的映射错误，导致该列存储的数值口径与字段名不符，**使用前务必与数据 owner 确认**。

2. **两套分区写入同一份数据**：ETL 先后向 `tz_type='local'` 和 `tz_type='regional'` 两个分区写入**完全相同**的 `base_data_local` 数据（均来源于 `tz_type='local'` 的上游）。因此当前 `regional` 分区数据并非真正按地区时区重新统计的数据，与 `local` 数值相同，查询时需确认所需口径。

3. **区域独立外表**：`dws_advertiser_livestream_revenue_1d__${region}_s0_live` 是一个 location 指向 `tz_type=local/grass_region=${upper_region}` 子目录的外表，与主表共享物理存储，仅做分区挂载（`alter table ... add partition`），并非独立写入。

4. **LEFT JOIN 主播维度**：维度关联使用 LEFT JOIN，若某 `shop_id` 在当日维度快照中无对应主播记录，则 `streamer_id` 和 `streamer_type` 为 NULL，消耗数据仍保留。下游分析时需注意 NULL 主播的过滤或单独处理。

5. **调度参数化**：`${region}`、`${grass_date}`、`${upper_region}` 均为调度层注入的参数，各地区独立调度任务写入对应 `grass_region` 分区，覆盖所有上线地区。

---

*文档生成时间：2026-04-22*