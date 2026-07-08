<!-- ads-workspace-gdoc-sync: gdoc_id=1hVs8hP1biDVXayslSSWbll-02Ze5u_eerx2_YUe65Po gdoc_url=https://docs.google.com/document/d/1hVs8hP1biDVXayslSSWbll-02Ze5u_eerx2_YUe65Po/edit -->

# mp_paidads.dim_streamer_new_old_tag

**分层**：DIM（维度层）
**主键**：`streamer_id` + `shop_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层维表，暂无下游候选表引用）

---

## 业务描述

本表是主播（Streamer）新老标签维度表，面向付费广告（Paid Ads）业务，以主播粒度记录其在直播带货广告投放场景下的新老属性标签、GMV 分层、收入分层及活跃状态等关键维度信息。表中每日快照覆盖所有活跃或曾经活跃的主播，支撑广告运营团队对主播精细化分层运营、拉新效果追踪及广告主质量评估等业务场景。

本表核心价值在于将主播的"新老"语义从多个时间维度进行精确定义：包括"今日新广告主"、"本月新广告主"（区分全新/回归/休眠）以及"新直播主播"状态，配合 GMV 分层（按近 30 日 GMV 和直播 GMV 百分位）与收入分层（按当日投放金额百分位），为 Paid Ads 策略制定和效果归因提供标准化的主播画像维度。

在使用场景上，分析师通常通过本表与绩效宽表进行关联，按主播新老标签、GMV 层级等维度下钻分析广告投放效果；运营团队亦可利用本表识别首次投流主播（`today_new_advertiser_status = 1`）进行定向激励或补贴策略触达。各地区按本地时区参数化调度，同一套逻辑覆盖所有上线地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。生产数据固定写入 `'local'`（各地区本地时区），查询时**必须指定** `tz_type = 'local'` |
| `grass_region` | string | 地区标识，大写格式（如 `'US'`、`'ID'`），各地区按本地时区参数化调度覆盖 |
| `grass_date` | date | 数据日期（本地日期），每日一个分区快照 |

---

### 维度：主播与店铺基础属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `streamer_id` | bigint | 主播唯一标识，主键之一，来源于直播维表 `ls_mart_dim_streamer` |
| `streamer_type` | int | 主播类型编码，具体枚举值参考直播维表定义 |
| `shop_id` | bigint | 主播关联的店铺 ID，主键之一；优先取广告投放侧 shop_id，若缺失则回退到直播维表中的 shop_id（COALESCE 兜底） |
| `shop_level1_global_be_category` | string | 店铺一级全球商业品类，优先取广告主维表中的类目，缺失时回退直播维表 |
| `shop_level2_global_be_category` | string | 店铺二级全球商业品类，优先取广告主维表中的类目，缺失时回退直播维表 |

---

### 维度：主播新老标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `today_new_advertiser_status` | string | **今日新广告主状态**。`0`=过去 365 天内有投流记录（老广告主）；`1`=今日有投流且过去 365 天内无记录（今日新广告主）；`'Not Applicable Today'`=今日无投流行为。⚠️ DDL 声明为 `string` 但取值含整数字符串与文字字符串，JOIN 或比较时注意类型转换，不可直接做数值聚合 |
| `month_new_advertiser_status` | int | **本月新广告主状态**。`0`=上月有收入且本月也有收入（留存）；`1`=过去 12 月有收入但上月无，本月恢复（回归）；`2`=过去 12 月均无收入，本月首次（全新）；`3`=本月无收入（不活跃）。⚠️ 该字段编码含义与业务强相关，过滤时需明确各值的语义 |
| `new_ls_streamer_status` | int | **新直播主播状态**。`0`=今日有直播且过去 90 天内无直播记录（今日新主播）；`1`=本月有直播（活跃主播）；`2`=其他（不活跃）。⚠️ 判断"今日新主播"需同时满足今日有直播（`is_streaming_today=1`）且过去 90 天无记录，逻辑基于前一日快照判断 90 天活跃 |

---

### 维度：分层标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `advertiser_gmv_tier` | string | **店铺 GMV 分层**（基于近 30 日 GMV，美元）。`large_seller`（≥25,000）、`medium_seller`（10,000~25,000）、`small_seller`（5,000~10,000）、`micro seller`（<5,000 或无数据）。⚠️ 此分层为当日快照值，不同日期分区的分层结果可能不同，不可跨日期直接合并 SUM |
| `advertiser_ls_gmv_tier` | string | **主播直播 GMV 百分位分层**（基于当日直播带货 GMV 百分位排名）。取值：`Top 1%`、`Top 5%`、`Top 10%`、`Top 20%`、`Top 30%`、`Top 40%`、`Top 50%`、`Other`（当日无 GMV 数据）。⚠️ 百分位基于 `PERCENT_RANK()` 分地区计算，`'Not Applicable Today'`（COALESCE 兜底）表示当日无直播 GMV，不可直接 SUM 或排序比较 |
| `advertiser_rev_tier` | string | **广告主投流收入百分位分层**（基于当日 USD 投放金额百分位排名）。取值：`1% percentile`、`10% percentile`、`25% percentile`、`50% percentile`、`75% percentile`、`Other`。⚠️ 百分位仅对当日投放金额 >0 的广告主计算，无投放记录的主播填充 `'Not Applicable Today'`，不代表其真实收入排名 |

---

### 维度：主播直播活跃时间

| 字段 | 类型 | 说明 |
|------|------|------|
| `streamer_first_streaming_date` | string | 主播首次直播日期，来源于直播维表，格式为日期字符串（如 `'2023-01-01'`）。⚠️ 存储为 string 类型，日期比较需显式转换 `date(streamer_first_streaming_date)` |
| `streamer_last_streaming_date` | string | 主播最近一次直播日期，来源于直播维表。⚠️ 存储为 string 类型，日期比较需显式转换 |
| `streamer_first_live_ads_date` | string | 主播首次直播广告投流日期，来源于广告收入累计表。⚠️ 存储为 string 类型，日期比较需显式转换；无投流记录时为 NULL |
| `streamer_last_live_ads_date` | string | 主播最近一次直播广告投流日期，来源于广告收入累计表。⚠️ 存储为 string 类型，日期比较需显式转换；无投流记录时为 NULL |

---

### 指标：主播当日活跃状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_streaming_today` | tinyint | 当日是否有直播，`1`=有，`0`=无。由 `streamer_last_streaming_date = grass_date` 推导，COALESCE 兜底为 0 |
| `is_rev_today` | tinyint | 当日是否有广告投流收入，`1`=有，`0`=无。由 `streamer_last_live_ads_date = grass_date` 推导，COALESCE 兜底为 0 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，造成资源浪费和查询超时：

```sql
WHERE tz_type = 'local'           -- 生产数据仅写入 local 分区，遗漏此条件将返回空或重复数据
  AND grass_region = 'XX'         -- 替换为目标地区大写代码，如 'US'、'ID'、'TH'
  AND grass_date = DATE('2025-01-01')  -- 指定具体日期或日期范围
```

> ⚠️ 遗漏 `tz_type` 过滤将扫描所有时区分区（即使目前只有 `local`），遗漏 `grass_region` 将全量扫描所有地区分区，均会导致极大的计算资源消耗。

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|-------------|
| `advertiser_rev_tier` | 预计算百分位分层标签，为字符串枚举，不可数值聚合 | 使用 `GROUP BY advertiser_rev_tier COUNT(DISTINCT shop_id)` 统计各层人数 |
| `advertiser_ls_gmv_tier` | 预计算百分位分层标签，含 `'Not Applicable Today'` 占位值 | 统计分布时先过滤 `advertiser_ls_gmv_tier != 'Not Applicable Today'` |
| `advertiser_gmv_tier` | 基于当日快照的分箱标签，跨日期分区合并时同一 `shop_id` 可能属于不同分层 | 跨日分析时应以单日分区为基准，不可跨分区 UNION 后直接 COUNT |
| `today_new_advertiser_status` | 存储为 string 类型，取值混合整数字符串（`'0'`、`'1'`）与文字（`'Not Applicable Today'`） | 过滤新广告主用 `today_new_advertiser_status = '1'`，注意引号；不可 SUM 或 AVG |
| `streamer_first_streaming_date` / `streamer_last_streaming_date` / `streamer_first_live_ads_date` / `streamer_last_live_ads_date` | string 类型存储日期，直接字符串比较可能因格式差异出错 | 使用 `date(streamer_first_streaming_date)` 显式转换后再比较 |

---

### 时效性说明

- 本表为**每日全量快照**，分区 `grass_date` 对应数据日期。查询当日最新主播标签应取**最新可用分区**（T+1 调度，当日数据次日产出）。
- `new_ls_streamer_status` 中"过去 90 天是否有直播"判断依赖的是 **T-1 日快照**（`grass_date = date_sub(grass_date, 1)`），存在 1 日数据延迟；`month_new_advertiser_status` 中"上月是否有收入"依赖**上月末日分区**（`date_sub(TRUNC(grass_date,'MM'),1)`），月初数据依赖前月数据完整性。
- `today_new_advertiser_status = '1'`（今日新广告主）具有强时效性，仅对当日有投流行为的主播有意义，**不建议跨日期累加统计**，应以每日分区独立分析。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `livestream.ls_mart_dim_streamer` | 主播基础维表，提供主播 ID、类型、店铺、品类、首末次直播日期等基础属性 |
| `mp_paidads.dws_advertiser_livestream_performance_1d__reg_s0_live` | 直播广告每日绩效表，用于获取当日有广告投放行为的 `shop_id` 集合 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，补充店铺品类信息 |
| `mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live` | 广告主直播收入累计表，提供首末投流日期、累计消耗、当日/本月/历史活跃标记 |
| `mp_paidads.dws_advertiser_livestream_revenue_1d__reg_s0_live` | 广告主直播收入日表，用于计算当日投放金额百分位分层（`advertiser_rev_tier`） |
| `mp_order.dws_seller_gmv_nd__reg_s0_live` | 卖家 GMV 滚动 N 日表，提供近 30 日 GMV 用于 `advertiser_gmv_tier` 分箱 |
| `mp_paidads.dws_streamer_livestream_org_performance_1d__reg_s0_live` | 主播直播带货每日绩效表，提供直播 GMV 用于 `advertiser_ls_gmv_tier` 百分位计算 |

---

## ETL 逻辑摘要

### 数据流

```
livestream.ls_mart_dim_streamer (当日)
        │
        ▼
   [dim_streamer]  ─────────────────────────────────────────────────────────┐
   主播基础维度                                                               │
        │                                                                    │
        │    mp_paidads.dws_advertiser_livestream_performance_1d (当日)      │
        │            │                                                       │
        │            ▼                                                       │
        │    [shop_id集合]                                                   │
        │            │                                                       │
        │    mp_paidads.dim_advertiser (当日)                                │
        │            │                                                       │
        │            ▼                                                       │
        │      [streamer_per]                                                │
        │      有投流行为的店铺+品类                                          │
        │            │                                                       │
        └──FULL JOIN─┘                                                       │
                │                                                            │
                ▼                                                            │
          [ls_streamer]                                                      │
          主播+店铺+品类融合                                                  │
                │                                                            │
                ├── LEFT JOIN ── [streaming_date_ytd]  (T-1日快照)           │
                │                 90天内是否有直播                            │
                │                                                            │
                ├── LEFT JOIN ── [revenue_td]          (当日快照)            │
                │                 首末投流日期/当日是否有收入                  │
                │                                                            │
                ├── LEFT JOIN ── [rev_date_ytd]        (T-1日快照)           │
                │                 过去365天是否有收入                         │
                │                                                            │
                ├── LEFT JOIN ── [rev_date_last_month] (上月末日快照)         │
                │                 上月/过去12月是否有收入                      │
                │                                                            │
                ├── LEFT JOIN ── [rev_tier]            (当日)                │
                │                 广告收入百分位分层                           │
                │                                                            │
                ├── LEFT JOIN ── [gmv_tier]            (当日)                │
                │                 近30日GMV分层                               │
                │                                                            │
                └── LEFT JOIN ── [org_gmv_tier]        (当日)                │
                                  直播GMV百分位分层                            │
                                        │                                    │
                                        ▼                                    │
                          INSERT OVERWRITE                                   │
                   dim_streamer_new_old_tag (PARTITION local/region/date) ◄──┘
                   (Spark/Hive SQL, 写入 Parquet)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `dim_streamer` | `livestream.ls_mart_dim_streamer`（当日） | 提取主播基础信息、首末直播日期、今日/本月是否有直播标记 |
| `streamer_per` | `dws_advertiser_livestream_performance_1d` + `dim_advertiser` | 取当日有广告投放的店铺集合，并补充店铺品类信息 |
| `ls_streamer` | `dim_streamer` FULL JOIN `streamer_per` | 合并直播维表与广告侧店铺，以 shop_id 为桥接，COALESCE 处理字段优先级 |
| `streaming_date_ytd` | `ls_mart_dim_streamer`（**T-1 日**） | 判断主播在过去 90 天内是否有直播记录，用于识别"今日新主播" |
| `revenue_td` | `dws_advertiser_livestream_revenue_td`（当日） | 提供首末投流日期、当日/本月是否有投流收入 |
| `rev_date_ytd` | `dws_advertiser_livestream_revenue_td`（**T-1 日**） | 判断店铺过去 365 天是否有广告收入，用于"今日新广告主"判断 |
| `rev_date_last_month` | `dws_advertiser_livestream_revenue_td`（**上月末日**） | 判断上月及过去 12 月是否有广告收入，用于"本月新广告主"状态计算 |
| `rev_tier` | `dws_advertiser_livestream_revenue_1d`（当日） | 按地区内当日投放金额 `PERCENT_RANK()` 计算广告主收入分层 |
| `gmv_tier` | `mp_order.dws_seller_gmv_nd`（当日） | 按近 30 日 GMV 绝对值区间划分店铺规模层级 |
| `org_gmv_tier` | `dws_streamer_livestream_org_performance_1d`（当日） | 按地区内当日直播带货 GMV `PERCENT_RANK()` 计算主播 GMV 分层 |

### 注意事项

1. **多快照日期依赖**：本表 ETL 同时依赖当日、T-1 日、上月末日三个不同时间点的上游分区数据。若任一分区数据延迟或缺失，将导致新老标签逻辑判断偏差（尤其是 `new_ls_streamer_status` 和 `month_new_advertiser_status`）。

2. **FULL JOIN 导致主键扩展**：`ls_streamer` CTE 使用 `dim_streamer` FULL JOIN `streamer_per`，意味着：即使某主播当日未出现在直播维表中（仅有广告侧记录），仍会被纳入本表；反之，有直播但无广告投放的主播也会保留，相关广告字段为 NULL。

3. **`today_new_advertiser_status` 类型陷阱**：DDL 声明为 string，但 ETL CASE WHEN 逻辑中混用了整数（`0`、`1`）和字符串（`'Not Applicable Today'`），实际写入均转为 string。查询时务必用字符串比较：`today_new_advertiser_status = '1'`。

4. **百分位分层的地区隔离性**：`advertiser_rev_tier` 和 `advertiser_ls_gmv_tier` 的百分位均在 `PARTITION BY grass_region` 范围内计算，**跨地区比较无意义**，同一 `shop_id` 在不同地区的分层结果相互独立。

5. **`gmv_tier` 无主播直接关联**：`advertiser_gmv_tier` 基于 `shop_id` 关联 GMV 数据，若主播与店铺关系缺失，将 COALESCE 填充为 `'micro seller'`，并非真实 GMV 数据支撑的分层结果。

6. **`advertiser_ls_gmv_tier` 仅计算有 GMV 主播**：`org_gmv_tier` CTE 过滤了 `gmv_rcmd_usd > 0` 的记录，无当日直播 GMV 的主播不参与排名，最终 COALESCE 填充为 `'Not Applicable Today'`。

---

*文档生成时间：2026-04-22*