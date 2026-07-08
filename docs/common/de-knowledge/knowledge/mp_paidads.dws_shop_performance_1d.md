<!-- ads-workspace-gdoc-sync: gdoc_id=1jDMQOe4H6BPoZ6aY9rOcNZqt_-7vg_Dva4AOu72K9lY gdoc_url=https://docs.google.com/document/d/1jDMQOe4H6BPoZ6aY9rOcNZqt_-7vg_Dva4AOu72K9lY/edit -->

# mp_paidads.dws_shop_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`shop_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表以店铺（Shop）为粒度，汇总每日的广告投放绩效与经营核心指标，覆盖订单量、GMV、广告花费、广告带单、SKU 投放渗透率等多个维度，是付费广告业务分析的核心宽表之一。

表中同时保留**当日（1d）**和**月累计（MTD，Month-To-Date）**两类口径的指标，可支持日粒度趋势分析、月度达成监控、广告 ROI 评估等多种场景，适用于广告产品团队、商家运营团队及数据分析师进行跨店铺的广告健康度诊断与对标。

核心价值在于将搜索广告（Search）与展示广告（Discovery / Display）的花费统一口径合并，并与店铺整体 GMV、活跃 SKU 数关联，直接输出广告 Take Rate、SKU 投放渗透率等派生指标，为广告变现率监控和商家分层提供底层数据支撑。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，写入时固定为 `'local'`（各地区按本地时区参数化调度）。查询时**必须**指定此字段以避免全表扫描。 |
| `grass_region` | string | 地区编码（大写），如 `'MX'`、`'BR'` 等，通过调度参数 `${regions}` 参数化覆盖所有地区。 |
| `grass_date` | date | 数据日期，格式 `yyyy-MM-dd`，对应业务当日（本地时区）。 |

---

### 维度：主键与店铺标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺唯一标识，为本表的业务主键。由五张 CTE 的 `shop_id` 通过 `COALESCE` 合并，确保任意数据来源出现的店铺均被保留。 |

---

### 指标：当日订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_order_cnt` | bigint | 当日店铺总订单数（去重 `order_id`，仅统计 `is_placed=1` 的已下单订单）。 |
| `total_gmv` | decimal(38,10) | 当日店铺总 GMV（`seller_gmv` 口径，仅含已下单订单）。 |
| `checkout_cnt` | bigint | 当日广告结算数（来源于广告绩效表 `checkout_cnt` 汇总）。 |

---

### 指标：当日广告带单绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `direct_ads_order` | bigint | 当日直接广告带单数（搜索广告直接转化订单数，来源 `order_cnt`）。 |
| `direct_ads_gmv` | decimal(38,10) | 当日直接广告带单 GMV（本地币种，来源 `ads_order_gmv_local`）。 |
| `broad_ads_order` | bigint | 当日泛广告带单数（宽泛匹配广告带单，来源 `broad_order_cnt`）。 |
| `broad_ads_gmv` | decimal(38,10) | 当日泛广告带单 GMV（本地币种，来源 `broad_gmv_amt_local`）。 |
| `ads_expense` | decimal(38,10) | 当日广告总花费（本地币种），= 搜索广告花费（`expenditure_amt_local`）+ 展示广告花费（按 `cpm × impression_cnt / 100000 / 1000` 计算，仅限 `placement=9` 且 `slot_id is not null` 的展位）。⚠️ 为两类广告花费之和，不可与单一广告类型字段直接相加，避免重复计算。 |

---

### 指标：月累计（MTD）广告与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expense_mtd` | decimal(38,10) | 当月累计广告总花费（从月初到 `grass_date`，口径同 `ads_expense`）。⚠️ 为月累计存储值，跨分区直接 SUM 会导致重复累加，同一店铺同一月份应取最新分区的值。 |
| `take_rate_mtd` | decimal(38,10) | 当月广告 Take Rate，= `ads_expense_mtd / shop_total_gmv_mtd`。⚠️ 为预计算比率，不可直接 SUM；若需汇总多店铺，应用 `SUM(ads_expense_mtd) / SUM(shop_total_gmv_mtd)` 重新计算。 |
| `sku_with_ads_expense_mtd` | bigint | 当月有广告花费的 SKU 数（去重 `item_id`，`expenditure_amt_local > 0`）。⚠️ 为月累计存储值，跨分区 SUM 会导致重复计算。 |
| `sku_with_ads_expense_ratio_mtd` | decimal(38,10) | 当月有广告花费 SKU 占活跃 SKU 的比率，= `sku_with_ads_expense_mtd / active_item_cnt`。⚠️ 为预计算比率，不可直接 SUM；多店铺汇总需用 `SUM(sku_with_ads_expense_mtd) / SUM(active_item_cnt)` 重新计算。 |
| `sku_with_ads_expense_search_mtd` | bigint | 当月在搜索广告（`entrance in (1, 23)`）场景下有花费的 SKU 数（去重）。⚠️ 为月累计存储值，跨分区 SUM 会导致重复计算。 |
| `sku_with_ads_expense_discovery_mtd` | bigint | 当月在发现广告（Discovery，`entrance in (3,4,7,8,9,10,11,20,14,15,16,17,18,19,22,31,32,33,34,29,41,25)`）场景下有花费的 SKU 数（去重）。⚠️ 为月累计存储值，跨分区 SUM 会导致重复计算。 |
| `shop_total_gmv_mtd` | decimal(38,10) | 当月店铺累计 GMV（`seller_gmv` 口径，月初至 `grass_date`，`is_placed=1`）。⚠️ 为月累计存储值，跨分区直接 SUM 会导致重复累加，应取目标月最新分区的值。 |

---

### 指标：店铺活跃商品

| 字段 | 类型 | 说明 |
|------|------|------|
| `active_item_cnt` | bigint | 当日店铺活跃商品数（来源于 `mp_item.dws_shop_listing_td__reg_s0_live`，为快照值，反映当日在架活跃 SKU 数量）。⚠️ 为当日快照存储值，跨多日 SUM 无意义，应按日取值或取某一日的快照。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**在 `WHERE` 子句中指定以下分区条件，否则将触发全分区扫描，导致查询超时或产生巨额计算费用：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 本表写入时固定为 `'local'`，缺少此条件将扫描所有 tz_type 分区 |
| `grass_region` | `grass_region = 'MX'`（按实际地区指定） | 必须大写；缺少此条件将扫描全部地区分区 |
| `grass_date` | `grass_date = '2025-04-01'` 或 `grass_date BETWEEN ... AND ...` | 缺少此条件将扫描全部历史日期分区 |

**遗漏后果**：跨分区全表扫描，数据量可能达数百亿行，严重影响集群稳定性并产生不必要的资源消耗。

---

### 不可直接 SUM 的字段

以下字段为预计算派生值或月累计存储值，**不可直接跨行 SUM**，需按正确方式使用：

| 字段 | 问题原因 | 正确计算方式 |
|------|----------|-------------|
| `take_rate_mtd` | 预计算比率字段 | 多店铺汇总：`SUM(ads_expense_mtd) / NULLIF(SUM(shop_total_gmv_mtd), 0)` |
| `sku_with_ads_expense_ratio_mtd` | 预计算比率字段 | 多店铺汇总：`SUM(sku_with_ads_expense_mtd) / NULLIF(SUM(active_item_cnt), 0)` |
| `ads_expense_mtd` | 月累计存储值，同一店铺在同一月份的多个 `grass_date` 分区中均存有该月的累计值 | 同一月份仅取最新 `grass_date` 分区，再对店铺维度 SUM |
| `shop_total_gmv_mtd` | 月累计存储值，同上 | 同一月份仅取最新 `grass_date` 分区，再对店铺维度 SUM |
| `sku_with_ads_expense_mtd` | 月累计存储值，同上 | 同一月份仅取最新 `grass_date` 分区 |
| `sku_with_ads_expense_search_mtd` | 月累计存储值，同上 | 同一月份仅取最新 `grass_date` 分区 |
| `sku_with_ads_expense_discovery_mtd` | 月累计存储值，同上 | 同一月份仅取最新 `grass_date` 分区 |
| `active_item_cnt` | 当日快照值，多日 SUM 无业务含义 | 按单日或取某一日的快照值使用 |
| `ads_expense` | 包含搜索广告 + 展示广告两部分，不可与子类型字段叠加 | 直接使用此字段作为总花费，勿与 `expenditure_amt_local`（原始表字段）再次相加 |

---

### 时效性说明

- **MTD 字段**（`ads_expense_mtd`、`shop_total_gmv_mtd`、`sku_with_ads_expense_mtd` 等）在每日分区中滚动累计，若需获取某月最终的月累计值，应查询该月最后一个已产出的 `grass_date` 分区（通常为月末或当前最新分区），而非对多个 `grass_date` 分区直接 SUM。
- 表为 T+1 调度，`grass_date = CURRENT_DATE` 的分区在当日日终 ETL 完成前不可用，建议查询 `grass_date <= CURRENT_DATE - 1`。
- 若在月初查询上月 MTD，应确认上月最后一个分区已成功产出，避免数据缺失。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 提供店铺维度的订单数、当日 GMV（`total_order_cnt`、`total_gmv`）及月累计 GMV（`shop_total_gmv_mtd`） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供广告结算数、带单订单数、带单 GMV、搜索广告花费、展示广告展示次数及 CPM（用于计算展示广告花费），同时提供 MTD 维度的广告花费与 SKU 投放数 |
| `mp_item.dws_shop_listing_td__reg_s0_live` | 提供店铺当日活跃商品数快照（`active_item_cnt`） |

---

## ETL 逻辑摘要

### 数据流

```
mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
    │
    ├──[当日, is_placed=1]──────────────────────► shop_all_order
    │                                              (total_order_cnt, total_gmv)
    │
    └──[MTD, is_placed=1]──────────────────────► shop_total_gmv_mtd
                                                   (shop_total_gmv_mtd)

mp_paidads.dwd_advertise_performance_di__reg_s0_live
    │
    ├──[当日, 全 placement]─────────────────────► shop_ads_performance (part A)
    │   (checkout_cnt, direct_ads_order/gmv,        搜索广告花费 ads_expense
    │    broad_ads_order/gmv, expenditure_amt_local)
    │
    ├──[当日, placement=9 & slot_id is not null]─► shop_ads_performance (part B)
    │   (cpm × impression_cnt → display_ads_expense) 展示广告花费
    │   └── A LEFT JOIN B ──────────────────────► shop_ads_performance
    │                                              (ads_expense = search + display)
    │
    ├──[MTD, 全 placement]──────────────────────► shop_ads_performance_mtd (part A)
    │   (ads_expense_mtd, sku_with_ads_expense_mtd,
    │    sku_with_ads_expense_search/discovery_mtd)
    │
    └──[MTD, placement=9 & slot_id is not null]─► shop_ads_performance_mtd (part B)
        (display_ads_expense_mtd)
        └── A LEFT JOIN B ──────────────────────► shop_ads_performance_mtd
                                                   (ads_expense_mtd = search + display)

mp_item.dws_shop_listing_td__reg_s0_live
    │
    └──[当日快照]──────────────────────────────► shop_active_item_cnt
                                                   (active_item_cnt)

shop_all_order
    FULL JOIN shop_ads_performance
    FULL JOIN shop_active_item_cnt
    FULL JOIN shop_total_gmv_mtd
    FULL JOIN shop_ads_performance_mtd
    │
    ├── 派生: take_rate_mtd = ads_expense_mtd / shop_total_gmv_mtd
    ├── 派生: sku_with_ads_expense_ratio_mtd = sku_with_ads_expense_mtd / active_item_cnt
    │
    └──────────────────────────────────────────► dws_shop_performance_1d__reg_s0_live
                                                  PARTITION(tz_type='local', grass_region, grass_date)
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `shop_all_order` | `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 统计店铺当日总订单数（去重 `order_id`）与当日总 GMV（`seller_gmv`），仅含 `is_placed=1` 的已下单记录 |
| `shop_ads_performance` | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 汇总当日广告结算数、带单数/GMV（直接 + 泛匹配），并合并搜索广告花费与展示广告估算花费（CPM 模型） |
| `shop_active_item_cnt` | `mp_item.dws_shop_listing_td__reg_s0_live` | 获取店铺当日活跃上架商品数快照 |
| `shop_total_gmv_mtd` | `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 汇总店铺月初至当日的累计 GMV（MTD 口径） |
| `shop_ads_performance_mtd` | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 汇总店铺月初至当日的累计广告花费（含展示广告估算），及按 entrance 分类的有花费 SKU 数（搜索 / 发现）MTD 值 |

---

### 注意事项

1. **展示广告花费计算逻辑**：展示广告（Display Ads）花费通过 CPM 模型估算：`display_ads_expense = ROUND(cpm × impression_cnt / 100,000 / 1,000, 2)`，仅统计 `placement = 9` 且 `slot_id IS NOT NULL` 的展位，与搜索广告花费（`expenditure_amt_local`）相加后得到 `ads_expense` / `ads_expense_mtd`。

2. **FULL JOIN 兜底逻辑**：最终写入使用五张 CTE 的 FULL JOIN，`shop_id` 通过 `COALESCE(a.shop_id, b.shop_id, c.shop_id, d.shop_id, e.shop_id)` 取第一个非空值，确保在任何一个数据源中出现的店铺均不会被丢失。

3. **MTD 字段月内滚动覆盖**：`ads_expense_mtd`、`shop_total_gmv_mtd`、`sku_with_ads_expense_*_mtd` 在每个 `grass_date` 分区中存储的均是月初至当日的累计值（非增量），跨分区 SUM 必然产生重复计算，分析月度数据时务必只取目标月的**最新分区**。

4. **sku_with_ads_expense_search_mtd 与 discovery_mtd 的 entrance 口径**：搜索场景为 `entrance in (1, 23)`；发现场景为 `entrance in (3,4,7,8,9,10,11,20,14,15,16,17,18,19,22,31,32,33,34,29,41,25)`。两者之和不一定等于 `sku_with_ads_expense_mtd`（因为存在不属于任一分类的 entrance 值，且 SKU 可能同时出现在多个场景中，去重逻辑各自独立计算）。

5. **分区写入固定 tz_type**：ETL 采用 `INSERT OVERWRITE ... PARTITION(tz_type='local', ...)` 硬编码写入，本表目前只有 `tz_type = 'local'` 分区，查询时直接等值过滤即可。

6. **各地区按本地时区参数化调度**：ETL 中出现的具体地区代码（如 `upper('mx')`）为调度模板的参数化实例，实际通过 `${regions}`、`${grass_date}` 等参数覆盖全部地区，非单一地区固定跑批。

---

*文档生成时间：2026-04-22*