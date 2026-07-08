<!-- ads-workspace-gdoc-sync: gdoc_id=1IWK3lNSejlcQp74f8kvGMpV22Z3zjOxS5wkcw_VjS44 gdoc_url=https://docs.google.com/document/d/1IWK3lNSejlcQp74f8kvGMpV22Z3zjOxS5wkcw_VjS44/edit -->

# Columns: mkplpaidads_search_ads_ads_debug.ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live

## Key Columns

| # | Column Name | Type | Description | Query Note |
|---|---|---|---|---|
| 1 | `grass_date` | Date | 本地业务日期，也是 ClickHouse 分区字段。 | 必须作为核心过滤条件。 |
| 2 | `grass_region` | String | 地区。 | 常用值：`ID`, `TH`, `VN`, `MY`, `SG`, `PH`, `TW`。 |
| 3 | `exp_tag` | String | 实验分组标签；`all` 表示整体大盘，其他值表示具体实验桶 / 分组。 | 实验桶之间不可直接相加，除非实验流量设计允许。 |
| 4 | `entrance` | Int64 | 流量入口分组，来自 performance 的 `algo_json_data.entrance_group_idx`；非广告订单使用 `-1`。 | 可用于入口维度下钻。 |
| 5 | `pricing_type` | Int32 | 广告计费类型，来自 performance 的 `pricing_type`；非广告订单使用 `-1`。 | 可用于产品 / 计费类型下钻。 |
| 6 | `local_hour` | Integer | 区域本地业务小时 0-23（KP1 v2 新增本地小时拆分维度）。 | 可用于分时段下钻；`local_hour BETWEEN 0 AND 23`。 |

## Metric Columns

| Column Name | Type | Description |
|---|---|---|
| `imp` | Int64 | 广告曝光数，来自 performance.`impression_cnt`，按 perf 日志直接聚合。 |
| `clk` | Int64 | 广告扣费点击数，来自 performance.`click_cnt`，按 perf 日志直接聚合。 |
| `broad_order` | Int64 | broad 归因订单数，表示较宽归因口径下的广告带动订单。 |
| `direct_order` | Int64 | direct 归因订单数，表示广告直接归因订单。 |
| `broad_gmv` | Float64 | broad 归因 GMV，USD 口径。 |
| `direct_gmv` | Float64 | direct 归因 GMV，USD 口径。 |
| `advv` | Float64 | 广告主价值，USD 口径；`pricing_type IN (1,2,3,13,16)` 时使用 `expenditure_amt_usd`，其他计费类型使用 `broad_gmv_amt_usd * target_cir`。 |
| `cost` | Float64 | 广告消耗，USD 口径，来自 performance.`expenditure_amt_usd`。 |
| `ads_voucher_imp` | Int64 | 广告券流量曝光数，按 `bid_rerank_trace.bid_voucher_id > 0` 判断是否为带券流量。 |
| `ads_voucher_clk` | Int64 | 广告券流量扣费点击数。 |
| `ads_voucher_order` | Int64 | 广告券流量 direct 归因订单数。 |
| `ads_voucher_gmv` | Float64 | 广告券流量 direct 归因 GMV，USD 口径。 |
| `ads_voucher_advv` | Float64 | 广告券流量广告主价值，USD 口径，公式与 `advv` 一致。 |
| `ads_voucher_ads_cost` | Float64 | 广告券流量广告消耗，USD 口径。 |
| `ads_voucher_claim` | Int64 | 广告券领取数，直接使用 performance.`ads_voucher_auto_claimed` 作为 proxy 聚合。 |
| `platform_order_cnt` | Int64 | 平台订单数，来自 unified order 固定 `ORDER_STATUS_PLACED` 后的订单聚合。 |
| `ads_order_cnt` | Int64 | 广告订单数，通过 `user_id + order_id` 将 unified order 回连 performance 后标记。 |
| `platform_gmv` | Float64 | 平台 GMV，USD 口径，来自 unified order。 |
| `ads_platform_gmv` | Float64 | 广告订单对应的平台 GMV，USD 口径。 |
| `ads_voucher_redeem` | Int64 | 广告券核销订单数，按 unified order.`ads_voucher_id > 0` 判断。 |
| `ads_voucher_cost` | Float64 | 广告券真实核销成本，USD 口径，来自 unified order.`sv_rebate_by_shopee_amt_usd / 1e5`。 |
| `ads_voucher_platform_gmv` | Float64 | 广告券核销订单对应的平台 GMV，USD 口径。 |
| `total_redeem` | Int64 | 任意优惠券核销订单数，包含广告券和非广告券。 |
| `total_voucher_cost` | Float64 | 任意优惠券 Shopee 补贴成本，USD 口径，包含 seller/shop voucher 与 platform voucher 对应补贴。 |
| `total_voucher_platform_gmv` | Float64 | 任意优惠券核销订单对应的平台 GMV，USD 口径。 |

## Derived Metric Hints

| Derived Metric | Formula | Meaning |
|---|---|---|
| `click_ctr` | `sum(clk) / sum(imp)` | 广告点击率。 |
| `direct_cvr` | `sum(direct_order) / sum(clk)` | 点击到 direct order 转化率。 |
| `broad_roi` | `sum(broad_gmv) / sum(cost)` | broad GMV / 广告消耗。 |
| `direct_roi` | `sum(direct_gmv) / sum(cost)` | direct GMV / 广告消耗。 |
| `advv_roi` | `sum(advv) / sum(cost)` | 广告主价值 / 广告消耗。 |
| `ads_voucher_cost_rate` | `sum(ads_voucher_cost) / sum(ads_voucher_platform_gmv)` | 广告券核销成本占对应平台 GMV 比例。 |
| `ads_voucher_redeem_rate` | `sum(ads_voucher_redeem) / sum(total_redeem)` | 广告券核销订单在全部券核销订单中的占比。 |

## Notes

- This ClickHouse table mirrors the Hive table `mkplpaidads_search_ads.ads_roi3_strategy_algo_metrics_1d__reg_s0_live`.
- Hive is the source of truth. ClickHouse is used for low-latency query and report serving.
- Always query with `cluster(...)`; direct local table query may return partial shard data.
