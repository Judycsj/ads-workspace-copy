<!-- ads-workspace-gdoc-sync: gdoc_id=109lK4eQTg8udKgCU5ufCwd5cDfy3KTsh9jyghhtdNN8 gdoc_url=https://docs.google.com/document/d/109lK4eQTg8udKgCU5ufCwd5cDfy3KTsh9jyghhtdNN8/edit -->

# mp_paidads.dws_advertise_keyword_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`shop_id` + `item_id` + `ads_id` + `keywords` + `match_type` + `placement` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 调度，覆盖当日分区）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告关键词维度的每日汇总宽表，以"广告主 × 商品 × 广告计划 × 关键词 × 匹配类型 × 广告位"为粒度，记录每条关键词在单日内的曝光、点击、消耗、GMV 及派生率指标。表中同时存储了绝对量指标（如曝光次数、点击次数、消耗金额）和预计算率指标（如 CTR、CR、CIR、CPC），为广告运营和算法团队提供开箱即用的关键词粒度分析基础。

典型使用场景包括：关键词竞价策略评估（通过 CIR、ROAS 判断关键词投入产出）、广告排名监控（`avg_ads_ranks_1d` 趋势追踪）、关键词效果归因（点击-转化漏斗分析）以及跨 SKU / 跨广告计划的横向对比。与同层 Query 事件表相比，本表已完成关键词级聚合，查询效率更高，适合 BI 报表和日常运营看板直接使用。

各地区按本地时区参数化调度，`tz_type = 'local'` 分区对应各地区本地日期口径下的数据；所有地区通过统一调度模板覆盖，不存在地区缺失问题。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区口径类型。当前写入值为 `'local'`（各地区本地时区）。查询时**必须指定**此分区字段，避免全表扫描。 |
| `grass_region` | string | 国家/地区代码（大写，如 `'BR'`、`'MX'`）。各地区独立分区，查询时**必须指定**。 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD`。查询时**必须指定**，避免读取全量历史分区。 |

---

### 维度：主键与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 卖家店铺 ID，关联广告主维度。 |
| `user_name` | string | 卖家账号用户名，来源于 `dim_advertiser` 维表 JOIN 后的 `user_name` 字段。 |
| `item_id` | bigint | 广告投放的商品 ID（SKU 级别）。 |
| `ads_id` | bigint | 广告计划 ID。 |
| `keywords` | string | 关键词文本内容，区分大小写，为关键词的原始字符串。 |
| `match_type` | bigint | 关键词匹配类型枚举值：`0` = 精确匹配（KW_EXACT_MATCH），`1` = 短语匹配（KW_PHRASE_MATCH）。 |
| `placement` | bigint | 广告位编码，标识广告展示的版位（如搜索结果页、推荐位等）。 |

---

### 指标：流量与消耗

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `impression_cnt_1d` | bigint | 当日广告曝光次数。 |
| `click_cnt_1d` | bigint | 当日广告点击次数。 |
| `expenditure_amt_local_1d` | double | 当日广告扣费金额（本地货币）。 |
| `expenditure_amt_usd_1d` | double | 当日广告扣费金额（USD）。 |
| `cpc_local_1d` | double | 当日平均单次点击费用（本地货币）。计算逻辑：`expenditure_amt_local_1d / click_cnt_1d`，`click_cnt_1d = 0` 时取 `0.0`。⚠️ 为预计算比率，不可直接 SUM；多行合并时应用分子/分母重新计算：`SUM(expenditure_amt_local_1d) / NULLIF(SUM(click_cnt_1d), 0)`。 |
| `cpc_usd_1d` | double | 当日平均单次点击费用（USD）。计算逻辑：`expenditure_amt_usd_1d / click_cnt_1d`，`click_cnt_1d = 0` 时取 `0.0`。⚠️ 为预计算比率，不可直接 SUM；多行合并时应用分子/分母重新计算：`SUM(expenditure_amt_usd_1d) / NULLIF(SUM(click_cnt_1d), 0)`。 |

---

### 指标：转化与 GMV

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `order_cnt_1d` | bigint | 当日通过关键词广告带来的直接成单数（直接归因订单数）。 |
| `ads_gmv_amt_local_1d` | double | 当日关键词广告带来的 GMV（本地货币），来源于 Query GMV 事件表。 |
| `ads_gmv_amt_usd_1d` | double | 当日关键词广告带来的 GMV（USD），来源于 Query GMV 事件表。 |

---

### 指标：广告效率比率

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ctr_1d` | double | 当日点击率（Click-Through Rate）。计算逻辑：`click_cnt_1d / impression_cnt_1d`，`impression_cnt_1d = 0` 时取 `0.0`。⚠️ 为预计算比率，不可直接 SUM；多行合并时应用分子/分母重新计算：`SUM(click_cnt_1d) / NULLIF(SUM(impression_cnt_1d), 0)`。 |
| `cr_1d` | double | 当日转化率（Conversion Rate）。计算逻辑：`order_cnt_1d / click_cnt_1d`，`click_cnt_1d = 0` 时取 `0.0`。⚠️ 为预计算比率，不可直接 SUM；多行合并时应用分子/分母重新计算：`SUM(order_cnt_1d) / NULLIF(SUM(click_cnt_1d), 0)`。 |
| `cir_1d` | double | 当日费效比（Cost-Income Rate），即广告花费占 GMV 的比率。计算逻辑：`expenditure_amt_local_1d / ads_gmv_amt_local_1d`，分母为 `0` 时取 `0.0`。⚠️ 为预计算比率，不可直接 SUM；多行合并时应用分子/分母重新计算：`SUM(expenditure_amt_local_1d) / NULLIF(SUM(ads_gmv_amt_local_1d), 0)`。 |

---

### 指标：广告排名

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `avg_ads_ranks_1d` | double | 当日该广告在关键词维度下的平均排名（由上游表聚合 AVG 得出）。⚠️ 为预计算均值，不可直接 SUM；多行合并时需根据原始曝光事件重新计算加权均值，直接对本字段 AVG 仅为近似值，精度取决于各行数据量是否均匀。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，导致查询超时并产生大量不必要的计算费用：

| 分区字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | `tz_type = 'local'` | 读取所有时区口径数据，产生重复计算；目前仅写入 `'local'`，遗漏则读取空分区或未来可能引入的其他口径数据，结果不可预期 |
| `grass_region` | `grass_region = 'BR'` | 跨地区全量扫描，数据量成倍增加，结果混入多地区数据 |
| `grass_date` | `grass_date = '2026-05-19'` | 读取全量历史分区，数据量极大，且可能拉取到不完整的历史数据 |

**推荐过滤条件模板**：
```sql
WHERE tz_type = 'local'
  AND grass_region = '${region}'
  AND grass_date = '${grass_date}'
```

### 不可直接 SUM 的字段

以下字段为预计算的比率或均值，**跨行聚合时不得直接使用 SUM / AVG**，必须回到分子分母层面重新计算：

| 字段 | 错误写法 | 正确写法 |
|------|---------|---------|
| `ctr_1d` | `SUM(ctr_1d)` | `SUM(click_cnt_1d) / NULLIF(SUM(impression_cnt_1d), 0)` |
| `cr_1d` | `SUM(cr_1d)` | `SUM(order_cnt_1d) / NULLIF(SUM(click_cnt_1d), 0)` |
| `cir_1d` | `SUM(cir_1d)` | `SUM(expenditure_amt_local_1d) / NULLIF(SUM(ads_gmv_amt_local_1d), 0)` |
| `cpc_local_1d` | `SUM(cpc_local_1d)` | `SUM(expenditure_amt_local_1d) / NULLIF(SUM(click_cnt_1d), 0)` |
| `cpc_usd_1d` | `SUM(cpc_usd_1d)` | `SUM(expenditure_amt_usd_1d) / NULLIF(SUM(click_cnt_1d), 0)` |
| `avg_ads_ranks_1d` | `AVG(avg_ads_ranks_1d)` | 建议回溯原始事件表进行加权均值计算；若仅需近似值且各行数据量差异不大，可谨慎使用 `AVG(avg_ads_ranks_1d)` 但需注明为近似结果 |

> **特别说明**：当 `click_cnt_1d = 0` 时，`cpc_local_1d`、`cpc_usd_1d`、`cr_1d` 均被强制填充为 `0.0`（COALESCE 处理），而非 NULL。聚合计算时需注意这些 `0.0` 值会干扰 AVG 结果，建议在聚合前过滤掉分母为 0 的行或使用 NULLIF 处理。

### 时效性说明

本表每日 T+1 调度，数据覆盖的是 `grass_date` 对应的自然日（本地时区）。查询**昨日数据**时，应指定 `grass_date = CURRENT_DATE - 1`（即今日调度写入的最新分区）。ETL 逻辑中通过 `is_today = 1` 标记仅汇总当日事件，不存在累计历史叠加问题，每个 `grass_date` 分区独立存储当日数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live` | 主数据源，提供关键词级别的曝光、点击、消耗、订单量、GMV 及广告排名等原始事件汇总数据 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，通过 `shop_id` + `grass_region` LEFT JOIN，补充卖家的 `user_name` 字段 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_query_gmv_event_1d__reg_s0_live
  (WHERE grass_region = ${region}, grass_date = ${grass_date}, tz_type = 'local')
        │
        │  LEFT JOIN on shop_id + grass_region
        │
mp_paidads.dim_advertiser__reg_s0_live
  (WHERE grass_region = ${region}, grass_date = ${grass_date})
        │
        ▼
  [子查询层] COALESCE 空值填充，标记 is_today 标志位
        │
        ▼
  [聚合层] GROUP BY shop_id, username, item_id, ads_id, keywords,
                    match_type, placement, grass_region
           SUM(CASE WHEN is_today=1 THEN ... ELSE 0 END) → 1d 绝对量指标
           AVG(avg_ads_ranks) → avg_ads_ranks_1d
        │
        ▼
  [派生层] COALESCE(分子/分母, 0.0) → cpc / ctr / cr / cir
        │
        ▼
  INSERT OVERWRITE PARTITION (tz_type='local', grass_region=${region}, grass_date=${grass_date})
        │
        ▼
mp_paidads.dws_advertise_keyword_performance_1d__reg_s0_live
```

### 关键 CTE 说明

本 ETL 无显式 CTE（WITH 子句），使用嵌套子查询方式组织逻辑，共三层：

| 层次 | 对应代码结构 | 作用 |
|------|-------------|------|
| 内层子查询（数据准备层） | 最内层 `FROM (SELECT a.*, b.user_name ...)` | 从事件表读取原始字段，LEFT JOIN 维表补充 `user_name`，COALESCE 填充空值，计算 `is_today` 标志位（当日数据标记为 1） |
| 中层子查询（聚合层） | 中层 `FROM (...) GROUP BY 1,2,3,4,5,6,7,grass_region` | 按关键词维度分组，SUM 汇总当日（`is_today=1`）绝对量指标，AVG 计算平均排名 |
| 外层 SELECT（派生层） | 最外层 `SELECT ... COALESCE(a/b, 0.0)` | 在聚合结果基础上派生 `cpc_local_1d`、`cpc_usd_1d`、`ctr_1d`、`cr_1d`、`cir_1d` 等比率字段 |

### 注意事项

1. **`is_today` 过滤机制**：ETL 中 `is_today = CASE WHEN a.grass_date = date('${grass_date}') THEN 1 ELSE 0 END`，仅汇总与调度日期匹配的数据。当前 WHERE 条件已限定 `grass_date = date('${grass_date}')`，因此 `is_today` 恒为 1，该机制为保险设计，适配可能存在的多日期分区场景。

2. **比率字段的零值陷阱**：当分母（`click_cnt_1d`、`impression_cnt_1d`、`ads_gmv_amt_local_1d`）为 0 时，所有比率字段均被 COALESCE 强制赋值为 `0.0`，而非 NULL。这导致无法通过 `IS NULL` 区分"无数据"与"分母为零"两种情况，聚合分析时需特别注意。

3. **`user_name` 字段来源**：来自 `dim_advertiser` 维表的 LEFT JOIN，若某 `shop_id` 在维表中不存在，则 `user_name` 为 NULL（不经过 COALESCE 处理）。使用 `user_name` 做过滤时需注意潜在的 NULL 值。

4. **`avg_ads_ranks_1d` 的精度问题**：中层聚合使用 `AVG(avg_ads_ranks)` 直接对已聚合字段求均值，存在样本量加权问题。若上游 `dws_advertise_query_gmv_event_1d` 中 `avg_ads_ranks` 本身已是聚合均值，则本表的 `avg_ads_ranks_1d` 为"均值的均值"，在各组数据量差异较大时会产生偏差。

5. **参数化调度覆盖多地区**：ETL SQL 中出现的 `upper('${region}')`、`date('${grass_date}')` 均为调度模板参数，每次调度实例化为具体地区和日期。本表通过统一调度框架覆盖所有支持地区，各地区按本地时区独立写入对应分区。

---

*文档生成时间：2026-05-20*