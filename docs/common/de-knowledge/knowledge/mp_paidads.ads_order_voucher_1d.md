<!-- ads-workspace-gdoc-sync: gdoc_id=16WAQBAA2gNjUcumu-a94KzrYUNEkxzxCaavIN0FLljY gdoc_url=https://docs.google.com/document/d/16WAQBAA2gNjUcumu-a94KzrYUNEkxzxCaavIN0FLljY/edit -->

# mp_paidads.ads_order_voucher_1d

**分层**：ADS（应用数据服务层）
**主键**：`order_id` + `item_id` + `user_id` + `shop_id` + `ads_voucher_id`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1）
**引用频次**：3 次（候选表范围内）

---

## 业务描述

本表以订单商品粒度记录广告关联优惠券的详细信息，是付费广告（Paid Ads）ROI 分析和优惠券归因的核心 ADS 层宽表。每行对应一个订单商品的优惠券使用快照，涵盖卖家优惠券（Seller Voucher）、广告优惠券（Ads Voucher）、平台优惠券（Platform Voucher）、免运费优惠券（FSV）四类券种的金额及来源明细，并通过广告点击归因模型将最近一次有效点击事件的信息关联至该优惠券。

表的核心使用场景包括：广告 ROI 报表（广告带动的 GMV 与券后实际成本核算）、Ads Voucher 归因分析（将哪个广告主/广告计划的点击激活了券核销）、卖家套餐（Package）广告费用分摊分析，以及多种优惠券补贴来源（Shopee 平台、卖家、外部）的资金流向追踪。

各地区按本地时区参数化调度，每日覆盖当天下单且包含有效优惠券核销金额的订单商品数据，下游 BI 报表与 ADS 聚合层直接依赖本表进行日粒度指标计算。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型。当前写入分区固定为 `'local'`（本地时区），查询时须指定此值以避免全表扫描 |
| `grass_region` | string | 大写地区代码（如 `'MY'`、`'TH'`），各地区按本地时区参数化调度 |
| `grass_date` | date | 数据日期，对应订单下单日期（本地时区），格式 `YYYY-MM-DD` |

### 维度：主键与订单基础信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `order_id` | bigint | 订单 ID，与 `item_id` / `user_id` / `shop_id` / `ads_voucher_id` 联合构成主键 |
| `item_id` | bigint | 商品 ID，订单中对应的具体商品 |
| `shop_id` | bigint | 店铺 ID，订单商品所属的店铺 |
| `user_id` | bigint | 买家用户 ID |
| `order_place_datetime` | string | 订单下单时间，格式 `YYYY-MM-DD HH:mm:ss`（本地时区） |
| `order_paid_datetime` | string | 订单付款完成时间，格式 `YYYY-MM-DD HH:mm:ss`（本地时区） |

### 维度：优惠券 ID 与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_voucher_id` | bigint | 卖家优惠券 Promotion ID，唯一标识该订单商品关联的卖家券活动 |
| `ads_voucher_id` | bigint | 广告优惠券 ID。仅当该卖家券被标记为 `ADS-ROI` 类型时不为 NULL；作为广告归因键关联点击流 |
| `fsv_voucher_id` | bigint | 免运费优惠券 Promotion ID |
| `platform_voucher_id` | bigint | 平台优惠券 Promotion ID，标识 Shopee 平台发放的券 |
| `ads_id` | bigint | 订单归因广告的广告 ID（来自广告绩效宽表，`placement in (40,50)` 且有成交） |
| `pricing_type` | int | 广告计价模式（如 CPC、CPM 等） |
| `placement` | bigint | 广告位 ID |
| `entrance` | bigint | 订单归因的广告入口 |
| `non_ads_type` | tinyint | 套餐非广告类型标记：`1` = 套餐提名非广告（在活动有效期内），`2` = 有机非广告；仅在对应广告为 `pricing_type=29` 时有值 |
| `package_request_id` | bigint | 套餐申请 ID；仅 `non_ads_type = 1` 时有值，其余为 NULL ⚠️ 业务含义仅在 `non_ads_type = 1` 场景下有效，聚合前须先按此条件过滤 |
| `ab_sign` | string | 订单归因广告所属的 AB 实验签名 |
| `plan_bucket_list` | array\<bigint\> | 广告计划所属实验分组 BucketID 列表，JSON 数组格式 ⚠️ 数组类型，不可直接 SUM/GROUP，需用 `EXPLODE` 展开后使用 |
| `item_price_usd` | bigint | 商品 USD 价格（来自近三日最新价格快照，以分为单位）⚠️ 为时间点快照，非订单实付价格，且取数逻辑最多回溯 3 天，存在数据缺失风险 |

### 维度：优惠券点击归因信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `match_voucher_click_ads_id` | bigint | 归因至该优惠券的广告 ID（来自点击流归因，48 小时窗口内最近一次点击） |
| `match_voucher_click_pricing_type` | int | 归因至该优惠券的广告计价模式 |
| `match_voucher_click_placement` | bigint | 归因至该优惠券的广告位 |
| `match_voucher_click_ab_sign` | string | 归因至该优惠券的 AB 实验签名 |
| `match_voucher_click_entrance` | bigint | 归因至该优惠券的广告入口 |
| `match_voucher_click_entrance_group` | string | 归因至该优惠券的广告入口分组 ⚠️ DDL 及 ETL SQL 中未显式写入，字段值可能全为 NULL，使用前请验证 |
| `match_voucher_click_page_type` | string | 归因至该优惠券的页面类型 ⚠️ 同上，ETL SQL 中未显式写入，字段值可能全为 NULL |
| `match_voucher_click_page_section` | string | 归因至该优惠券的页面区域 ⚠️ 同上，ETL SQL 中未显式写入，字段值可能全为 NULL |
| `match_voucher_click_target_type` | string | 归因至该优惠券的定向类型 ⚠️ 同上，ETL SQL 中未显式写入，字段值可能全为 NULL |
| `match_voucher_click_campaign_id` | bigint | 归因至该优惠券的广告计划 ID ⚠️ 同上，ETL SQL 中未显式写入，字段值可能全为 NULL |
| `match_voucher_click_algo_json_data` | string | 归因至该优惠券的算法 JSON 数据 ⚠️ 同上，ETL SQL 中未显式写入，字段值可能全为 NULL |
| `match_voucher_click_datetime` | string | 归因点击的发生时间（取 `deduct_timestamp` 或 `timestamp` 中较新者），格式 `YYYY-MM-DD HH:mm:ss` |
| `voucher_cofund_ratio` | double | 优惠券共担比例，从 `bid_rerank_trace.platform_spend_ratio` 解析而来 ⚠️ 为比率字段（0~1），不可直接 SUM；若需计算分摊金额应以金额字段乘以此比率 |
| `package_co_fund_ratio` | double | 套餐共担比例（`co_fund_ratio / 100000`）；仅 `non_ads_type = 1` 时有值 ⚠️ 为比率字段，不可直接 SUM；且仅在 `non_ads_type = 1` 场景下有业务含义 |
| `oa_event_source` | string | OA 事件来源 ⚠️ ETL SQL 中未显式写入，字段值可能全为 NULL |

### 维度：优惠券详情与竞价追踪

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `voucher_details_json` | string | 优惠券详情 JSON，结构：`{"promotion_id": ..., "voucher_code": ..., "groups": [...], "reward_discount": ...}`。其中 `promotion_id + voucher_code` 为券唯一标识，`groups` 为券标签（如 `["ADS-ROI"]`），`reward_discount` 为静态折扣金额（不受退款影响）⚠️ JSON 字符串，需用 `get_json_object` 解析后使用 |
| `bid_rerank_trace` | string | 在线竞价过程中间字段值，JSON 格式，含模型预估得分等。`voucher_cofund_ratio` 即从此字段解析 ⚠️ JSON 字符串，直接使用需调用 `get_json_object`；原始字段保留供二次解析 |

### 指标：广告优惠券金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_voucher_amt_usd` | decimal(25,10) | 广告优惠券核销金额（USD）。仅当 `ads_voucher_id IS NOT NULL` 时有值（即卖家券属于 ADS-ROI 类型），否则为 NULL ⚠️ 非所有行均有值，统计 Ads Voucher 金额前须过滤 `ads_voucher_id IS NOT NULL` |
| `ads_voucher_amt_local` | decimal(25,10) | 广告优惠券核销金额（本地币种），口径同上 ⚠️ 同上 |

### 指标：卖家优惠券金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_voucher_amt_usd` | decimal(25,10) | Shopee 通过卖家优惠券向买家提供的净返利金额（USD），受取消/无效/退货影响 |
| `seller_voucher_amt_local` | decimal(25,10) | 同上，本地币种 |
| `net_sv_rebate_by_seller_amt_usd` | decimal(25,10) | 卖家自行承担的卖家券净返利金额（USD），净值（受退款影响） |
| `net_sv_rebate_by_seller_amt_local` | decimal(25,10) | 同上，本地币种 |
| `net_sv_rebate_by_external_amt_usd` | decimal(25,10) | 外部方通过卖家券承担的净返利金额（USD） |
| `net_sv_rebate_by_external_amt_local` | decimal(25,10) | 同上，本地币种 |
| `gross_ads_voucher_amt` | decimal(25,10) | Shopee 按比例分摊的卖家券返利净额（本地币种），用于广告 ROI 核算中的补贴成本分摊 ⚠️ ETL SQL 中未显式计算写入，字段口径待确认，使用前请核实是否由下游写入或当前为空 |
| `gross_ads_voucher_amt_usd` | decimal(25,10) | 同上，USD 版本 ⚠️ 同上 |

### 指标：平台优惠券金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `platform_voucher_amt_usd` | decimal(25,10) | Shopee 通过平台优惠券向买家提供的净返利金额（USD） |
| `platform_voucher_amt_local` | decimal(25,10) | 同上，本地币种 |
| `net_pv_rebate_by_seller_amt_usd` | decimal(25,10) | 卖家通过平台优惠券向买家提供的净返利金额（USD），净值（受退款影响） |
| `net_pv_rebate_by_seller_amt_local` | decimal(25,10) | 同上，本地币种 |
| `net_pv_rebate_by_external_amt_usd` | decimal(25,10) | 外部方通过平台优惠券向买家提供的净返利金额（USD） |
| `net_pv_rebate_by_external_amt_local` | decimal(25,10) | 同上，本地币种 |

### 指标：免运费优惠券金额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `fsv_voucher_amt_usd` | decimal(25,10) | 免运费券净核销金额（USD），汇总了 Shopee 实际运费补贴 + 三方物流卖家折扣 + 卖家运费补贴三部分 |
| `fsv_voucher_amt_local` | decimal(25,10) | 同上，本地币种 |

### 指标：平台大盘 GMV

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `platform_order_gmv_amt_usd` | decimal(25,10) | 订单商品维度的平台 GMV（USD），来源于订单明细表的 `gmv_usd` 字段汇总 |
| `platform_order_gmv_amt_local` | decimal(25,10) | 同上，本地币种 |
| `seller_gmv_amt_usd` | decimal(25,10) | 卖家维度 GMV（USD）⚠️ ETL SQL 中未显式写入，字段口径待确认，使用前请核实是否为空 |
| `seller_gmv_amt` | decimal(25,10) | 卖家维度 GMV（本地币种）⚠️ 同上 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全分区扫描，造成资源浪费并可能返回多地区/多时区的重复数据：

```sql
WHERE tz_type      = 'local'          -- 当前仅写入 local 分区，遗漏将扫描所有 tz_type
  AND grass_region = 'XX'             -- 替换为目标地区大写代码，如 'MY'、'TH'、'SG'
  AND grass_date   = '2024-01-01'     -- 或使用日期范围 BETWEEN，遗漏将全量扫描历史分区
```

- `tz_type`：ETL 固定写入 `'local'` 分区，**必须**指定此值
- `grass_region`：各地区独立调度，**必须**按需指定，否则会跨地区混算
- `grass_date`：日分区，**必须**指定，遗漏将导致全量历史扫描，性能极差

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确用法 |
|------|------|----------|
| `voucher_cofund_ratio` | 比率字段（0~1），直接 SUM 无业务意义 | 以对应金额字段（如 `ads_voucher_amt_usd`）乘以此比率计算分摊金额 |
| `package_co_fund_ratio` | 比率字段，且仅 `non_ads_type = 1` 时有效 | 先过滤 `non_ads_type = 1`，再乘以金额字段计算分摊 |
| `plan_bucket_list` | 数组类型，不可 SUM/GROUP BY | 使用 `LATERAL VIEW EXPLODE(plan_bucket_list)` 展开后按 BucketID 分析 |
| `voucher_details_json` / `bid_rerank_trace` | JSON 字符串 | 使用 `get_json_object(voucher_details_json, '$.promotion_id')` 等方式解析 |
| `ads_voucher_amt_usd` / `ads_voucher_amt_local` | 非 ADS-ROI 券的行此字段为 NULL，直接 SUM 会漏掉 NULL 处理逻辑 | 统计广告券金额时须明确过滤 `ads_voucher_id IS NOT NULL`，或使用 `COALESCE(ads_voucher_amt_usd, 0)` |
| `item_price_usd` | 来自近三日最新快照，非订单实付价格 | 仅作参考价，不可用于金额类加总计算 |

### 时效性说明

- 本表以 `grass_date`（订单**下单日期**）分区，ETL 每日 T+1 更新。查询时应取 **昨日或更早日期** 的分区，当日分区数据未写入。
- `item_price_usd` 取数逻辑最多回溯 3 天（`dt >= date_sub(grass_date, 3)`），若商品价格表近三日均无记录，该字段将为 NULL。
- 点击归因窗口为**下单时间前 48 小时内**的最近一次有效点击（`deduct_timestamp`），超出窗口的点击不会关联，`match_voucher_click_*` 字段将为 NULL。
- `match_voucher_click_datetime` 对应的点击数据来源覆盖 `grass_date` 前 3 天，因此跨日归因场景下，点击事件日期可能早于 `grass_date`。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_order.dwd_order_item_all_ent_df` | 订单商品明细，提供订单基础信息、各类优惠券 Promotion ID、各类券金额、GMV、FSV 金额等 |
| `mkplpaidads_data.item_price__reg_s0_live` | 商品价格快照（近三日最新），提供 `item_price_usd` |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效明细，双重用途：① 提供订单成交归因的广告属性（`order_voucher` CTE）；② 提供点击流归因数据（`click_oa` CTE） |
| `mp_voucher.dim_voucher__reg_live` | 优惠券维表，通过 `voucher_groups` 字段判断是否为 `ADS-ROI` 类型卖家券，用于标记 `ads_voucher_id` |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，提供套餐广告（`pricing_type=29`）的 `non_ads_type`、`is_nominated_for_package_non_ads` 等属性 |
| `mp_paidads.shopee_ads_${region}_${db_type}__ads_voucher_package_tab__reg_continuous_s0_live` | 广告券套餐信息表，提供 `package_request_id`、`co_fund_ratio`、套餐有效期等，用于计算 `package_co_fund_ratio` |

---

## ETL 逻辑摘要

### 数据流

```
mp_order.dwd_order_item_all_ent_df
  （订单商品明细，过滤含有效券核销金额的行）
           │
           ├──── LEFT JOIN ──── mkplpaidads_data.item_price__reg_s0_live
           │                    （近3日最新价格快照，补充 item_price_usd）
           │
           ├──── LEFT JOIN ──── mp_paidads.dwd_advertise_performance_di__reg_s0_live
           │                    （广告绩效，placement IN (40,50)，有成交，补充 ab_sign/ads_id 等）
           │
           └──── LEFT JOIN ──── mp_voucher.dim_voucher__reg_live
                                （券维表，过滤 ADS-ROI 卖家券，标记 ads_voucher_id）
                         │
                         ▼
                   [CTE: order_voucher]
                   订单-券宽表（含基础信息、各类券金额、广告属性）
                         │
                         │  LEFT JOIN（点击归因窗口：下单前48h内最近点击，ROW_NUMBER取rn=1）
                         │
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  （click_cnt/impression 过滤，回溯3天，提取点击归因字段）
         │
         ▼
   [CTE: click_oa]
   点击归因快照（含 voucher_cofund_ratio、bid_voucher_id 等）
         │
         ▼
   [主查询：order_voucher LEFT JOIN click_oa]
   ROW_NUMBER 去重（同一订单商品取最近点击）
         │
         │  LEFT JOIN
         │
mp_paidads.dim_advertise__reg_s0_live
  （pricing_type=29，套餐广告过滤）
         │
         └──── LEFT JOIN ──── shopee_ads_*__ads_voucher_package_tab__reg_continuous_s0_live
                              （套餐信息，补充 package_request_id / co_fund_ratio）
                       │
                       ▼
                [CTE: voucher_package_info]
                套餐广告共担信息
                       │
                       ▼
         ads_order_voucher_1d__reg_s0_live
         （INSERT OVERWRITE，分区：tz_type='local' / grass_region / grass_date）
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `order_voucher` | `mp_order.dwd_order_item_all_ent_df` + `item_price__reg_s0_live` + `dwd_advertise_performance_di` + `dim_voucher` | 以订单商品为粒度汇总各类券金额及广告归因属性；仅保留含有效 Shopee 补贴金额的订单商品；通过 `dim_voucher` 的 `ADS-ROI` 标签判断是否为广告券 |
| `click_oa` | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 从广告绩效明细中提取有效点击/展现事件，回溯 `grass_date` 前3天，解析 `bid_rerank_trace` 得到 `voucher_cofund_ratio` 和 `bid_voucher_id`，为订单归因做准备 |
| `voucher_package_info` | `mp_paidads.dim_advertise__reg_s0_live` + `shopee_ads_*__ads_voucher_package_tab` | 筛选套餐广告（`pricing_type=29`），结合套餐活动有效期判断 `non_ads_type`，计算 `package_co_fund_ratio = co_fund_ratio / 100000` |

### 注意事项

1. **广告券金额口径**：`ads_voucher_amt_usd/local` 的来源是 `seller_voucher_amt`，但仅当 `ads_voucher_id IS NOT NULL`（即该卖家券被 `dim_voucher` 标记为 `ADS-ROI` 类型）时才赋值，否则为 NULL。统计广告券 GMV 时务必注意此口径，不能直接等同于卖家券总金额。

2. **点击归因窗口与去重**：点击归因采用"下单时间前 48 小时内"的滑动窗口，通过 `order_place_timestamp - deduct_timestamp BETWEEN 0 AND 48*3600` 匹配，并以 `ROW_NUMBER() OVER (PARTITION BY order_id, item_id, user_id, shop_id, ads_voucher_id ORDER BY deduct_timestamp DESC)` 取最近一次点击（`rn = 1`）。若无匹配点击，`match_voucher_click_*` 字段全为 NULL。

3. **FSV 金额构成**：`fsv_voucher_amt` 由三部分相加：`actual_shipping_rebate_by_shopee`（Shopee 运费补贴）+ `shipping_discount_by_3pl_to_seller`（三方物流给卖家折扣）+ `actual_shipping_rebate_by_seller`（卖家自承担运费），使用 `COALESCE(x, 0)` 处理 NULL，可直接 SUM。

4. **package_co_fund_ratio 精度**：原始 `co_fund_ratio` 以整数存储（如 `50000` 表示 50%），ETL 已除以 `100000` 转换为小数比率（如 `0.5`），注意与其他系统对接时的精度换算。

5. **套餐有效期判断**：`non_ads_type = 1` 的判断依赖套餐的 `campaign_start_time` / `campaign_end_time`，时间戳从 SGT（`Asia/Singapore`）转换为各地区本地时区后与 `grass_date` 比较，跨时区场景需注意边界日期的归属。

6. **DDL 与 ETL 字段差异**：`match_voucher_click_entrance_group`、`match_voucher_click_page_type`、`match_voucher_click_page_section`、`match_voucher_click_target_type`、`match_voucher_click_campaign_id`、`match_voucher_click_algo_json_data`、`oa_event_source`、`gross_ads_voucher_amt`、`gross_ads_voucher_amt_usd`、`seller_gmv_amt`、`seller_gmv_amt_usd` 等字段在 DDL 字段列表中存在，但当前 ETL SQL 中未见显式写入，实际数据可能全为 NULL，使用前建议先验证非空率。

---

*文档生成时间：2026-05-20*