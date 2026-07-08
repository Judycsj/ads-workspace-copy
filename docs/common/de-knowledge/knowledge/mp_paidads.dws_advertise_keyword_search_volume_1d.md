<!-- ads-workspace-gdoc-sync: gdoc_id=1IIjTVNAq6gvEnXUIzSaPQ74Ya3Pih8JYD4fTYS07LYM gdoc_url=https://docs.google.com/document/d/1IIjTVNAq6gvEnXUIzSaPQ74Ya3Pih8JYD4fTYS07LYM/edit -->

# mp_paidads.dws_advertise_keyword_search_volume_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `grass_date` + `tz_type` + `keyword`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日一次（T+1 调度）
**引用频次：** 0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表记录各地区每日粒度的**广告关键词搜索量汇总数据**，核心指标包括关键词在 App 端的搜索请求次数（`search_volume`）、带有广告曝光的搜索请求数（`req_w_ads_imp_cnt`）及其占比（`req_w_ads_imp_pct`），同时为每个关键词附加分位段标签（`search_volume_percentile`），便于快速感知关键词热度在全局分布中的相对位置。

本表主要服务于付费广告智能投放场景。关键词选词工具、广告主洞察报告、流量预算评估等业务场景均可基于本表评估目标关键词的搜索量规模及广告流量渗透率，辅助广告主制定关键词出价策略与预算分配决策。

数据来源于移动端（iOS & Android App）搜索曝光行为，过滤了非自然搜索请求（排除 DS2 实验组），保证口径聚焦于真实用户意图驱动的搜索流量，具有较高的业务可信度。各地区按本地时区参数化调度，覆盖 Shopee 全站运营地区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前写入值固定为 `'local'`，表示按各地区本地时区统计。查询时**必须**指定此字段以避免全表扫描 |
| `grass_region` | string | 地区编码，大写，如 `'ID'`、`'TH'`、`'MY'` 等，代表 Shopee 各运营地区。各地区独立分区存储 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD`。每日刷新，查询时**必须**指定 |

### 维度：关键词属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 用户在 App 搜索框输入的搜索关键词原始文本，从搜索曝光日志中提取；为分组聚合维度，区分大小写 |
| `search_volume_percentile` | string | 关键词搜索量在当日、当地区内的**分位段标签**，取值为 `'p0'`、`'p10'`、`'p20'`、`'p30'`、`'p40'`、`'p50'`、`'p60'`、`'p70'`、`'p80'`、`'p90'`、`'p95'`、`'p99'`，基于 `PERCENT_RANK()` 窗口函数计算后映射为离散区间。⚠️ 为预计算的分位段标签，跨日期或跨地区汇总时无法直接比较或聚合，需回溯原始 `search_volume` 重新计算分位 |

### 指标：搜索量与广告渗透

| 字段 | 类型 | 说明 |
|------|------|------|
| `search_volume` | bigint | 当日该关键词的**去重搜索请求数**（`COUNT(DISTINCT request_id)`），统计范围为 iOS & Android App 端，排除 DS2 实验组流量，代表关键词的真实搜索热度 |
| `req_w_ads_imp_cnt` | bigint | 当日该关键词搜索结果中**包含至少一次广告曝光的去重搜索请求数**，即存在广告展示的搜索会话数量 |
| `req_w_ads_imp_pct` | double | 广告渗透率，等于 `req_w_ads_imp_cnt / search_volume`，表示该关键词搜索请求中有广告曝光的比例，取值范围 `[0.0, 1.0]`。⚠️ 为预计算比率，不可直接 SUM / AVG；多关键词或多日汇总时需用 `SUM(req_w_ads_imp_cnt) / SUM(search_volume)` 重新计算；缺失值已用 `0.0` 填充（`COALESCE` 处理） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，消耗大量计算资源并拖慢查询：

| 分区字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区，当前虽只写入 `local`，但未来扩展后将导致重复计数 |
| `grass_region` | `grass_region = 'ID'` | 扫描全部地区数据，严重影响性能且结果混入多地区数据 |
| `grass_date` | `grass_date = '2026-04-21'` | 扫描全部历史分区，极大增加 I/O 开销 |

**标准查询模板：**
```sql
SELECT *
FROM mp_paidads.dws_advertise_keyword_search_volume_1d
WHERE tz_type      = 'local'
  AND grass_region = 'ID'
  AND grass_date   = '2026-04-21';
```

### 不可直接 SUM 的字段

| 字段 | 错误用法 | 正确用法 |
|------|---------|---------|
| `req_w_ads_imp_pct` | `SUM(req_w_ads_imp_pct)` / `AVG(req_w_ads_imp_pct)` | `SUM(req_w_ads_imp_cnt) * 1.0 / SUM(search_volume)`，需确保分母不为零 |
| `search_volume_percentile` | 直接对分位段标签进行排序或汇总比较 | 应使用原始 `search_volume` 进行排序或重新计算分位；该字段仅适用于单日单地区内的分层筛选 |

### 时效性说明

本表为 T+1 调度，`grass_date` 分区对应前一自然日（本地时区）的数据。查询最新数据时，应取**当前日期减 1** 的分区：

```sql
-- 取最新可用数据
WHERE grass_date = DATE_SUB(CURRENT_DATE, 1)
```

请勿查询当天（`CURRENT_DATE`）分区，该分区在调度完成前不存在或数据不完整。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_foa.dwd_eventid_impress_di__reg_s0_live` | 提供 App 端搜索曝光明细日志，包含地区、关键词、请求 ID、广告曝光标识、AB 实验分组等原始行为数据，是本表唯一上游来源 |

---

## ETL 逻辑摘要

### 数据流

```
mp_foa.dwd_eventid_impress_di__reg_s0_live
  │
  │  过滤条件：
  │  - grass_date = ${grass_date}
  │  - grass_region = UPPER('${region}')
  │  - platform IN ('ios_app', 'android_app')
  │  - step1_feature_detail IN ('global_search-item',
  │      'search_in_pdp-item', 'search_in_subcategory-item')
  │  - get_full_signature_udf(ab_test) != 'DS2'（排除 DS2 实验组）
  │  - target_type = 'item'
  │  - user_id > 0（过滤匿名用户）
  │
  ▼
[layer_a] 提取关键词 & 请求维度数据
  解析 step1_data JSON → keyword, request_id
  解析 is_ads 标识，计算 ads_imp（广告曝光次数）
  GROUP BY grass_region, keyword, request_id
  │
  ▼
[layer_t] 关键词级聚合
  COUNT(DISTINCT request_id)                   → search_volume
  COUNT(DISTINCT CASE WHEN ads_imp > 0 ...)    → req_w_ads_imp_cnt
  GROUP BY grass_region, keyword
  │
  ▼
[search_volume] 窗口函数计算分位
  PERCENT_RANK() OVER (PARTITION BY grass_region ORDER BY search_volume ASC)
                                               → search_volume_percentile (0~1)
  req_w_ads_imp_cnt / search_volume            → req_w_ads_imp_pct
  │
  ▼
[output] 分位段映射 & 空值处理
  CASE WHEN ... → search_volume_percentile 离散标签 (p0~p99)
  COALESCE(req_w_ads_imp_pct, 0.0)
  │
  ▼
dws_advertise_keyword_search_volume_1d__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date)
  存储格式：PARQUET
  │
  ▼（软链接/目录别名）
dws_advertise_keyword_search_volume_1d__${region}_s0_live
  PARTITION (grass_date)
  路径：.../tz_type=local/grass_region=${upper_region}
```

### 关键 CTE 说明

本 ETL 使用嵌套子查询而非显式 CTE，各层逻辑说明如下：

| 子查询别名 | 来源表 | 作用 |
|-----------|--------|------|
| `a`（最内层） | `mp_foa.dwd_eventid_impress_di__reg_s0_live` | 解析 JSON 提取关键词、请求 ID、广告标识，按 `(grass_region, keyword, request_id)` 聚合计算每次搜索请求的广告曝光总次数 `ads_imp` |
| `t` | 子查询 `a` | 按 `(grass_region, keyword)` 聚合，计算去重搜索量 `search_volume` 与含广告曝光的去重请求数 `req_w_ads_imp_cnt` |
| `search_volume` | 子查询 `t` | 使用 `PERCENT_RANK()` 窗口函数计算各关键词搜索量在地区内的连续分位值，并计算广告渗透率 `req_w_ads_imp_pct` |
| `output` | 子查询 `search_volume` | 将连续分位值映射为离散分位段标签，填充空值，准备写入分区 |

### 注意事项

1. **AB 实验组过滤**：ETL 通过自定义 UDF `get_full_signature_udf` 解析 `ab_test` 字段签名，过滤掉 `DS2` 实验组用户，确保搜索量口径不受特定实验干扰。若该 UDF 逻辑调整，历史数据口径会发生变化。

2. **搜索量口径限定**：仅统计移动端（iOS & Android App）用户、已登录（`user_id > 0`）、在以下三个搜索入口发生的商品曝光：`global_search-item`（全局搜索）、`search_in_pdp-item`（商品页内搜索）、`search_in_subcategory-item`（子类目内搜索），不包含 Web 端及其他入口，数据与 PC 端有口径差异。

3. **地区级分位计算**：`search_volume_percentile` 的 `PERCENT_RANK()` 窗口函数按 `grass_region` 分区计算，因此同一关键词在不同地区的分位段标签含义不可横向比较。

4. **双表写入机制**：ETL 同时维护两张物理表——`__reg_s0_live`（全地区统一大表，含 `tz_type`/`grass_region` 分区）和 `__${region}_s0_live`（各地区独立表，映射到大表对应目录路径）。两张表共享同一份 PARQUET 文件，通过 Hive 元数据分区定义区分，避免数据重复存储。

5. **空值处理**：`req_w_ads_imp_pct` 在 `search_volume` 为 0 时理论上会产生除零异常，ETL 通过 `COALESCE(..., 0.0)` 兜底处理，实际查询中该字段不会出现 NULL，但分母为 0 的场景下该值为 0.0 而非真实比率，使用时需留意。

---

*文档生成时间：2026-04-22*