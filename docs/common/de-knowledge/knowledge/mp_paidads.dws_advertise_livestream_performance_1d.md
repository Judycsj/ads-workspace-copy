<!-- ads-workspace-gdoc-sync: gdoc_id=1cm5L5bRmBTDFuG_r_Yp4pTw2Ok_5xSETWurSHWXw5xo gdoc_url=https://docs.google.com/document/d/1cm5L5bRmBTDFuG_r_Yp4pTw2Ok_5xSETWurSHWXw5xo/edit -->

# mp_paidads.dws_advertise_livestream_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`ads_id` + `placement` + `shop_id` + `pricing_type` + `campaign_id` + `entrance` + `item_id` + `target_affiliate_id` + `streamer_id` + `sub_entrance` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆盖（T+1）
**引用频次**：0（末端 ADS 层输出表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告（Paid Ads）直播场景的**每日广告绩效汇总宽表**，以广告维度（广告 ID、投放位、店铺、定价类型、推广计划、入口、商品、联盟目标、主播）为粒度，聚合当日曝光、点击、观看、下单、GMV、广告花费等核心指标，同时补充了跨日的 YTD 已支付订单与已确认订单量。每行记录代表特定广告在某地区某日的投放表现快照。

本表主要服务于广告主运营分析、直播广告效果归因、ROI 核算及报表看板等场景。使用者可通过本表快速评估直播广告的曝光效率（CPM）、点击转化（CTR）、成交转化（CVR）、广告花费回报（ROAS）等关键指标，是付费广告直播业务的核心数据资产。

各地区按本地时区参数化调度，`tz_type` 字段用于区分本地时区与区域时区两套统计口径，查询时应明确指定以避免数据重复或混淆。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，区分本地时区（`local`）与区域时区（`regional`）。⚠️ 每次查询必须指定此字段进行过滤，否则同一数据会被双倍计入 |
| `grass_region` | string | 大写地区代码，如 `ID`、`TH`、`VN` 等，标识广告数据归属地区 |
| `grass_date` | date | 数据日期（本地日历日），为主要分区键。⚠️ 每次查询必须指定，避免全表扫描 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一条广告投放记录 |
| `campaign_id` | bigint | 推广计划 ID，广告所属推广计划 |
| `placement` | int | 广告版位，标识广告展示的具体位置 |
| `pricing_type` | int | 定价类型，如 CPM、CPC、CPT 等计费方式编码 |
| `entrance` | int | 广告入口类型编码，标识用户进入直播间的流量入口 |
| `sub_entrance` | bigint | 广告子入口类型编码，对 `entrance` 的进一步细分 |
| `item_id` | bigint | 商品 ID；对于直播广告（live ads），该字段为 NULL ⚠️ 直播广告场景下此字段恒为 NULL，不可用于商品维度分组 |
| `target_affiliate_id` | bigint | 广告投放目标联盟成员的 user_id（ads user's user_id） |

---

### 维度：店铺与账户信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `account_id` | bigint | 广告主的用户 ID（ads owner's user_id），由 ETL 中 `max(account_id)` 聚合得到 |
| `shop_id` | bigint | 广告主的店铺 ID（ads owner's shop_id） |

---

### 维度：主播属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `streamer_id` | bigint | 直播主播的用户 ID（ads user's user_id），关联主播维表获取主播属性 |
| `streamer_type` | int | 主播类型编码，来源于主播维表 `ls_mart_dim_streamer`，标识主播业务类型 |

---

### 指标：曝光与流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 广告曝光次数（原始） |
| `deduct_impression_cnt` | bigint | 扣除后的曝光次数，经过异常流量扣减处理 |
| `non_fraud_impression_cnt` | bigint | 非欺诈曝光次数，排除作弊流量后的有效曝光 |
| `click_cnt` | bigint | 广告点击次数（raw click） |
| `product_click_cnt` | bigint | 商品点击次数，在直播间内点击具体商品的次数 |
| `view_cnt` | bigint | 直播间观看次数 |
| `effective_view_cnt` | bigint | 有效观看次数，由 ETL 中 `count(distinct case when view > 0 then concat(request_id, ads_id))` 计算，去重后的实际有效观看请求数。⚠️ 基于 request_id + ads_id 去重，多次跨批次 SUM 可能存在重叠，建议在已聚合分区粒度上直接使用 |
| `view_duration` | bigint | 累计观看时长（单位：秒），所有观看用户的观看时长加总 |

---

### 指标：转化漏斗

| 字段 | 类型 | 说明 |
|------|------|------|
| `add_to_cart_cnt` | bigint | 加购次数 |
| `checkout_cnt` | bigint | 结算（发起下单）次数 |
| `order_cnt` | bigint | 下单数（广告归因） |
| `paid_order_cnt` | bigint | 已支付订单数（当日事件时间口径），广告归因范围内 |
| `confirmed_order_cnt` | bigint | 已确认订单数（当日事件时间口径），广告归因范围内 |
| `ads_items_sold_cnt` | bigint | 广告直接归因的商品售出件数 |
| `broad_order_cnt` | bigint | 泛归因订单数，归因范围更宽泛（如含点击后更长时间窗口） |
| `broad_item_sold_cnt` | bigint | 泛归因商品售出件数 |

---

### 指标：YTD 跨日订单

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_ytd_cnt` | bigint | 前一自然日（grass_date - 1）产生事件时间的已支付订单数，用于跨日归因补充。⚠️ 该字段统计的是 `grass_date - 1` 日的事件时间数据，与 `paid_order_cnt`（当日口径）不可直接相加，需明确归因窗口后使用 |
| `confirmed_order_ytd_cnt` | bigint | 前一自然日（grass_date - 1）产生事件时间的已确认订单数。⚠️ 同上，为跨日补充字段，不可与当日 `confirmed_order_cnt` 直接叠加汇总 |

---

### 指标：GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_gmv_amt` | double | 广告直接归因 GMV（本地货币，含税） |
| `ads_gmv_amt_usd` | double | 广告直接归因 GMV（美元） |
| `broad_ads_gmv_amt` | double | 泛归因 GMV（本地货币），归因口径更宽泛 |
| `broad_ads_gmv_amt_usd` | double | 泛归因 GMV（美元） |

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure` | double | 广告花费（本地货币，不含增值税） |
| `ads_expenditure_usd` | double | 广告花费（美元，不含增值税） |
| `ads_expenditure_vat_local` | double | 广告花费（本地货币，含增值税 VAT） |
| `ads_expenditure_vat_usd` | double | 广告花费（美元，含增值税 VAT） |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `grass_date` | `WHERE grass_date = '2024-01-01'` | 触发全分区扫描，读取所有历史数据，性能极差并导致结果错误 |
| `tz_type` | `AND tz_type = 'local'`（推荐）或 `'regional'` | 同一天数据会同时存在 `local` 和 `regional` 两个分区，若不过滤将导致数据翻倍计算 |
| `grass_region` | `AND grass_region = 'ID'` | 若需查询单一市场，必须指定；否则会跨地区汇总数据，结果可能无业务意义且查询性能下降 |

> **说明**：`tz_type` 分区存储了 `local`（按地区本地时区统计）和 `regional`（按区域时区统计）两套口径，日常分析报表通常使用 `tz_type = 'local'`；如对 `tz_type` 不过滤，则所有指标将被重复统计一次。

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|--------------|
| `effective_view_cnt` | ETL 中通过 `COUNT(DISTINCT concat(request_id, ads_id))` 计算，已完成去重聚合；跨多个分区/维度再次 SUM 会导致重复统计 | 仅在与 ETL 粒度一致时直接使用；若需跨日聚合，应回溯至 DWD 层重新去重计算 |
| `paid_order_ytd_cnt` | 统计口径为前一日（grass_date-1）事件时间的支付订单，与当日 `paid_order_cnt` 时间窗口不同，不可简单相加 | 明确归因时间窗口后，根据业务规则决定是否合并使用；若需计算"含跨日归因"的总支付订单，需明确定义口径后再合并 |
| `confirmed_order_ytd_cnt` | 同 `paid_order_ytd_cnt`，为前一日事件时间的确认订单，与当日确认订单存在时间窗口差异 | 同上 |
| `ads_gmv_amt` / `broad_ads_gmv_amt` 等 GMV 字段 | 本地货币字段跨地区 SUM 无意义，不同地区货币单位不同 | 跨地区汇总时请使用 `_usd` 后缀字段（美元口径） |

---

### 时效性说明

- **YTD 字段**（`paid_order_ytd_cnt`、`confirmed_order_ytd_cnt`）：记录的是 **`grass_date - 1` 日**事件时间范围内的支付/确认订单。该数据来自前一日数据切片（ETL 中取 `grass_date-2` 至 `grass_date-1` 的分区，事件时间对应前一日），用于补全前日广告归因中延迟入账的订单，**不代表当日的累计值**。
- **当日数据**：取 `grass_date = <目标日期>` 且 `tz_type = 'local'` 即为该地区当日本地时区口径数据。由于 T+1 调度，实际可用数据通常为昨日数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告明细事件流水表（DWD 层），提供广告曝光、点击、观看、下单、GMV、花费等所有原始明细指标；本表所有核心指标均由此表聚合得到 |
| `livestream.ls_mart_dim_streamer` | 主播维度表，提供 `streamer_type`（主播类型）等主播属性字段，通过 `streamer_id` + `grass_region` + `grass_date` 关联 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live
    │
    ├─── [当日事件时间过滤]  grass_date = T, event_timestamp ∈ [T, T+1)
    │         │
    │         ▼
    │    CTE: ls_performance
    │    (按广告维度 GROUP BY，聚合曝光/点击/观看/转化/GMV/花费)
    │
    └─── [前日事件时间过滤]  grass_date ∈ [T-2, T-1], event_timestamp ∈ [T-1, T)
              │
              ▼
         CTE: ls_order_ytd
         (按广告维度 GROUP BY，聚合 YTD 支付/确认订单)

livestream.ls_mart_dim_streamer
    │
    [grass_region = ${region}, grass_date = T, tz_type = 'local']
    │
    ▼
CTE: dim_ls
(主播类型维表)

         ls_performance
              │ LEFT JOIN ls_order_ytd  (on ads_id/placement/shop_id/pricing_type/campaign_id/entrance/streamer_id/sub_entrance)
              │ LEFT JOIN dim_ls        (on streamer_id)
              │
              ▼
         CTE: output（最终宽表）
              │
              ├─→ INSERT OVERWRITE dws_advertise_livestream_performance_1d__reg_s0_live
              │        PARTITION(tz_type='regional', grass_region, grass_date)
              │
              └─→ ALTER TABLE dws_advertise_livestream_performance_1d__${region}_s0_live
                       ADD PARTITION(grass_date = "${grass_date}")
                       [指向 local 分区路径，作为快捷入口]
```

> **调度引擎**：Hive SQL，写入方式为 `INSERT OVERWRITE` 覆盖写，按 `(tz_type, grass_region, grass_date)` 分区存储，格式为 Parquet。

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `ls_performance` | `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 过滤当日事件时间范围内的直播广告明细，按广告多维度 GROUP BY，汇总曝光、点击、观看、转化漏斗、GMV、花费等所有当日指标；含 `effective_view`（`request_id + ads_id` 去重计数）和 `view_duration` |
| `ls_order_ytd` | `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 过滤前一自然日事件时间范围的数据，按广告维度 GROUP BY，汇总跨日归因的已支付（`paid_order_ytd_cnt`）和已确认订单（`confirmed_order_ytd_cnt`），仅保留 `paid_order > 0 OR confirmed_order > 0` 的行 |
| `dim_ls` | `livestream.ls_mart_dim_streamer` | 取当日 `tz_type = 'local'` 的主播维表快照，提供主播类型（`streamer_type`）用于关联 |
| `output` | 以上三个 CTE | `ls_performance` LEFT JOIN `ls_order_ytd` + `dim_ls`，拼接所有维度与指标，形成最终输出宽表；同时附加 `grass_region` 和 `grass_date` 常量列 |

---

### 注意事项

1. **双分区写入机制**：ETL 同时写 `tz_type = 'regional'` 分区（通过 `INSERT OVERWRITE`）并通过 `ALTER TABLE ADD PARTITION` 将 `__${region}_s0_live` 表指向 `local` 分区路径。`regional` 与 `local` 两套分区使用同一份聚合数据，时区口径差异体现在 DWD 层的事件时间过滤上，上层使用时须通过 `tz_type` 严格区分。

2. **`effective_view_cnt` 去重口径**：在 DWD 层明细基础上以 `concat(request_id, ads_id)` 为 Key 去重计数，已是聚合后的去重值，跨日或跨维度二次聚合时不可 SUM，须回源 DWD 重算。

3. **`item_id` 恒为 NULL**：直播广告（live ads）不绑定具体商品，`item_id` 在所有直播广告行中均为 NULL，不可用于商品维度分析。

4. **YTD 字段归因口径**：`paid_order_ytd_cnt` 和 `confirmed_order_ytd_cnt` 的事件时间窗口为 `[grass_date - 1, grass_date)`，即前一日产生的归因动作，用于补充前日延迟上报的订单。业务分析若需"完整归因总量"时，需与产品侧对齐归因窗口定义后再决定是否合并当日字段。

5. **VAT 含税与不含税并存**：`ads_expenditure` / `ads_expenditure_usd` 为不含税金额，`ads_expenditure_vat_local` / `ads_expenditure_vat_usd` 为含税金额，报表中请勿混用，确认业务口径后统一选择。

6. **跨地区 GMV 汇总**：本地货币 GMV 字段（`ads_gmv_amt`、`broad_ads_gmv_amt`）不同地区单位不同，跨地区汇总必须使用 `_usd` 字段（美元口径）。

---

*文档生成时间：2026-04-22*