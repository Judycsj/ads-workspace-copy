<!-- ads-workspace-gdoc-sync: gdoc_id=1Gb9zdZkkj8sQ3w0NSuj8Daj5L2MuS53w0zv9yy9oqQU gdoc_url=https://docs.google.com/document/d/1Gb9zdZkkj8sQ3w0NSuj8Daj5L2MuS53w0zv9yy9oqQU/edit -->

# Columns: srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h

## Column Usage Notes

### Non-Additive Fields

以下 JSON/Struct 字段不能跨行简单 SUM，需要按行解析后分别聚合：

- `ads_recall_ext` (JSON) -- 召回阶段扩展信息，包含 ab_sign, item_id, ads_id, pricing_type, lite_pcr, lite_pctr, prerank_score 等
- `ads_info_ext` (JSON) -- 信息处理阶段扩展信息，field 结构与 ads_recall_ext 相似
- `ads_bid_ext` (JSON) -- 出价阶段扩展信息，包含 pctr, pcr, broad_pcr, rank_bid, algo_ext.{pid_coef, pgmv, ...} 等
- `ads_deduct_ext` (JSON) -- 扣费阶段扩展信息，包含 rank_score, ecpm, deduction_price 等

跨维度聚合这些字段时，必须先按行用 `get_json_object()` / `json_extract_scalar()` / `json_parse()` / `CAST(... AS ROW(...))` 提取子字段，再对子字段做 SUM/AVG。

### Enum Value Mappings (Value Mappings)

**item_type -> product_type:**

| Column | Value | Meaning |
|--------|-------|---------|
| item_type | TARGET_ROI2 | roi2 |
| item_type | SIMPLE_ROI2 | simple_roi2 |
| item_type | ROI1 | manual |
| item_type | (other) | other |

**entrance -> scene (推荐/RCMD side):**

| Column | Value | Meaning |
|--------|-------|---------|
| entrance | daily_discover_main | dd (Daily Discover) |
| entrance | product_detail_page | ymal (You May Also Like) |
| entrance | orderpaid_discover | pp (Post-Purchase) |
| entrance | shoppingcart | pp (Post-Purchase) |
| entrance | my_purchases_page_ymal | pp (Post-Purchase) |
| entrance | order_detail_page_ymal | pp (Post-Purchase) |
| entrance | me_page_ymal | pp (Post-Purchase) |
| entrance | (other) | other |

**recall_type:**

| Column | Value | Meaning |
|--------|-------|---------|
| recall_type | 1 | Ads-only recall |
| recall_type | 2 | Organic-only recall |
| recall_type | 3 | Both Ads + Organic recall |

### Common WHERE Filter Values

- `country`: 'ID','TH','PH','VN','MY','TW','SG' -- 东南亚 7 国（标准集）
- `regional_date`: `DATE('${1_DAYS_AGO}')` / `DATE('${TODAY}')` -- 按时间变量参数化
- `regional_hour`: '00' (日级别汇总时取午夜) / '${hour}' (小时级别）
- `item_type`: 'TARGET_ROI2','SIMPLE_ROI2' -- ROI2 出价类型（搜广最常用）
- `is_sampled`: true -- 采样数据过滤（几乎所有查询都过滤采样数据）
- `request_id is not null` -- 有效请求过滤
- `user_id > 0` -- 有效用户过滤
- `ads_id > 0` -- 有效广告过滤
- `shop_id > 0` -- 有效店铺过滤

## All Columns

*Note: DDL not found in codebase. Column names inferred from SQL references. Types marked as "-". Run `--source from-di` to get complete column metadata.*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| regional_date | - | 分区日期 (hourly) | - | - |
| regional_hour | - | 分区小时 | - | - |
| country | - | 国家/地区 (SG/ID/MY/PH/TH/TW/VN) | - | - |
| ads_real_item_id | - | 广告真实商品 ID（Search 侧用于 GROUP BY） | - | - |
| item_id | - | 商品 ID（RCMD 侧使用） | - | - |
| ads_id | - | 广告 ID | - | - |
| shop_id | - | 店铺 ID | - | - |
| user_id | - | 用户 ID | - | - |
| request_id | - | 请求 ID | - | - |
| session_id | - | Session ID | - | - |
| item_type | - | 出价类型 (TARGET_ROI2/SIMPLE_ROI2/ROI1) | - | - |
| entrance | - | 入口场景 (daily_discover_main/product_detail_page/...) | - | - |
| is_recall | - | 是否进入召回阶段 | - | - |
| is_prerank | - | 是否进入预排序阶段 | - | - |
| is_rank | - | 是否进入排序阶段 | - | - |
| is_mixrank | - | 是否进入混排阶段 | - | - |
| is_dispatch | - | 是否进入分发阶段 | - | - |
| is_sampled | - | 是否采样数据 | - | - |
| recall_type | - | 召回类型 (1=ads-only, 2=organic-only, 3=both) | - | - |
| ab_sign | - | AB 实验分流标识 | - | - |
| query | - | 搜索查询词 | - | - |
| ads_recall_ext | - | 召回阶段扩展 JSON (ab_sign, item_id, ads_id, pricing_type, lite_pcr, lite_pctr, prerank_score, prerank_bid, ...) | - | - |
| ads_info_ext | - | 信息处理阶段扩展 JSON (结构与 ads_recall_ext 相似) | - | - |
| ads_bid_ext | - | 出价阶段扩展 JSON (pctr, pcr, broad_pcr, org_ecpm, rank_bid, target_cir, algo_ext.{pid_coef, pgmv, ...}) | - | - |
| ads_deduct_ext | - | 扣费阶段扩展 JSON (rank_score, ecpm, deduction_price, ...) | - | - |
| prerank_score | - | 预排序分数 | - | - |
| prerank_pctr | - | 预排序 pCTR 预估 | - | - |
| prerank_pcr | - | 预排序 pCVR 预估 | - | - |
| prerank_position | - | 预排序位置 | - | - |
| rank_pctr | - | 排序阶段 pCTR 预估 | - | - |
| rank_pcr | - | 排序阶段 pCVR 预估 | - | - |
| rank_broad_pcr | - | 排序阶段 broad pCVR 预估 | - | - |
| rank_ecpm | - | 排序阶段 eCPM | - | - |
| rank_score | - | 排序阶段分数 | - | - |
| rank_position | - | 排序阶段位置 | - | - |
| rank_item_price | - | 排序阶段商品价格 | - | - |
| rank_relevance_score | - | 排序阶段相关性分数 | - | - |
| mixrank_score | - | 混排阶段分数 | - | - |
| mixrank_pctr | - | 混排阶段 pCTR | - | - |
| mixrank_pcr | - | 混排阶段 pCVR | - | - |
| mixrank_position | - | 混排阶段位置 | - | - |
| mixrank_estimated_gmv | - | 混排阶段预估 GMV | - | - |
| mixrank_ecpm | - | 混排阶段 eCPM | - | - |
