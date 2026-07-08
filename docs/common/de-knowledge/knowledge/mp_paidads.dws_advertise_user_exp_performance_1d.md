<!-- ads-workspace-gdoc-sync: gdoc_id=1hsM8mvH0HhgwgGpPurgnCVEPfGJDFESlwu1jiv6Bnww gdoc_url=https://docs.google.com/document/d/1hsM8mvH0HhgwgGpPurgnCVEPfGJDFESlwu1jiv6Bnww/edit -->

# mp_paidads.dws_advertise_user_exp_performance_1d

**分层**：DWS（数据汇总层）
**主键**：`group_id` + `placement` + `entrance` + `pricing_type` + `location` + `sub_entrance` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表以 **A/B 实验分组（group_id）** 为核心维度，汇总各广告投放实验组在每日维度下的广告曝光、点击、成单、GMV、消耗等核心绩效指标，用于支撑广告投放策略的实验效果评估（A/B Testing）。表中同时涵盖搜索广告和推荐广告（Daily Discover、YMAL 等）两条主要链路，通过不同的用户实验组归因逻辑分别接入。

本表的核心使用场景包括：广告算法团队评估竞价策略、出价模型、流量分配机制的实验效果；广告产品团队对比各 placement/entrance 下实验组的 ROI 表现；数据分析师基于实验粒度拉取广告收入、GMV 及极端用户去除后的稳健指标。

表中提供了多版本的 GMV 指标（含上限截断版本 _200/_500，以及去除极端用户版本 extreme_removed），可有效降低极端大单对实验结论的干扰，是广告实验分析的重要参考口径。各地区按本地时区参数化调度，当前仅包含 `tz_type = 'local'` 分区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前仅写入 `'local'`（各地区按本地时区调度） |
| `grass_region` | string | 地区编码，大写，如 `'MY'`、`'TH'`、`'PH'` 等，对应广告绩效所属地区 |
| `grass_date` | date | 广告绩效日期（本地时区），格式 `yyyy-MM-dd` |

---

### 维度：实验分组与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_id` | bigint | A/B 实验组 ID，来源于实验平台（`dim_sr_data_warehouse_abtest_user_group.exp_group_id`），标识用户所属的实验分组 |
| `placement` | int | 广告位类型编码，标识广告所在页面位置（如搜索结果页、发现页等） |
| `entrance` | int | 广告入口编码，区分搜索广告（entrance not in 3,4,8,9,10,11）与推荐广告（entrance in 3,4,8,9,10,11） |
| `pricing_type` | int | 广告计费模式，如 CPC、CPM 等编码值 |
| `location` | int | 广告展示位置细分编码 |
| `sub_entrance` | bigint | 子入口编码，对 entrance 进行进一步细分 |

---

### 指标：广告基础流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp_cnt` | bigint | 广告曝光次数（impression count） |
| `ads_clk_cnt` | bigint | 广告点击次数（click count）；搜索广告（placement=9）使用原始点击数（raw_click_cnt） |

---

### 指标：广告成单与 GMV（标准口径）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_order_cnt` | bigint | 广告直接带单量（direct order count，归因于广告点击的订单数） |
| `ads_gmv` | decimal(25,10) | 广告直接带单 GMV，本地货币 |
| `ads_gmv_usd` | decimal(25,10) | 广告直接带单 GMV，USD（由本地货币除以汇率换算得出） ⚠️ 由 `ads_gmv_local / exchange_rate` 计算写入，非原始字段，不可跨地区直接 SUM 后再做汇率换算 |
| `ads_item_sold_cnt` | bigint | 广告带单商品件数（ads item sold count） |

---

### 指标：广告收入（消耗）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_revenue` | decimal(25,10) | 广告消耗金额，本地货币（expenditure_amt_local；搜索 CPM 广告按 CPM×曝光折算） |
| `ads_revenue_usd` | decimal(25,10) | 广告消耗金额，USD ⚠️ 由 `expenditure_amt_local / exchange_rate` 换算写入，非原始字段 |
| `expense_free_credit_with_expiry` | decimal(25,10) | 广告消耗中使用有期限免费额度（free credit with expiry）的抵扣金额，本地货币 |
| `expense_free_credit_without_expiry` | decimal(25,10) | 广告消耗中使用无期限免费额度（free credit without expiry）的抵扣金额，本地货币 |

---

### 指标：当日订单口径（Daily Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_daily_order_cnt` | bigint | 当日直接订单数，仅统计点击与下单发生在同一天的订单（与 `ads_order_cnt` 的归因窗口不同） |
| `ads_daily_gmv_usd` | decimal(25,10) | 当日直接订单 GMV，USD（`daily_gmv_amt_local / exchange_rate`） ⚠️ 由换算得出，非原始字段 |
| `ads_daily_gmv_usd_500` | decimal(25,10) | 当日直接订单 GMV（USD，单笔上限 $500）：每笔订单换算 USD 后超过 500 则按 500 计，用于降低超大单影响 ⚠️ 已在 ETL 中按行截断后 SUM，不可再做二次 SUM 后重新截断；跨地区汇总时直接相加即可 |
| `ads_daily_gmv_usd_200` | decimal(25,10) | 当日直接订单 GMV（USD，单笔上限 $200），逻辑同 `ads_daily_gmv_usd_500` ⚠️ 同上，已预先截断聚合 |

---

### 指标：订单 GMV 截断口径（Order GMV Capped）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_order_gmv_usd_500` | decimal(25,10) | 广告直接带单 GMV（USD，单笔上限 $500），截断逻辑与 `ads_daily_gmv_usd_500` 一致，但归因窗口使用全周期（非仅当日） ⚠️ 已预先截断聚合，不可重新截断后二次 SUM |
| `ads_order_gmv_usd_200` | decimal(25,10) | 广告直接带单 GMV（USD，单笔上限 $200） ⚠️ 同上 |

---

### 指标：Broad 广告口径

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_broad_order_cnt` | bigint | Broad 广告带单量（宽泛归因口径下的订单数） |
| `ads_broad_gmv` | decimal(25,10) | Broad 广告带单 GMV，本地货币 |
| `ads_broad_gmv_usd` | decimal(25,10) | Broad 广告带单 GMV，USD（`broad_gmv_amt_local / exchange_rate`） ⚠️ 由换算得出，非原始字段 |

---

### 指标：极端用户去除口径（仅搜索广告）

| 字段 | 类型 | 说明 |
|------|------|------|
| `extreme_removed_ads_orders` | bigint | 去除极端用户后的广告带单量。极端用户定义：搜索广告（placement in 0,4,1000,1200）中单日订单数≥50 或 GMV≥$200 的用户 ⚠️ **仅搜索广告有值**，推荐广告（entrance in 3,4,8,9,10,11）该字段为 NULL |
| `extreme_removed_ads_gmv_usd` | decimal(25,10) | 去除极端用户后的广告带单 GMV（USD） ⚠️ **仅搜索广告有值**，推荐广告该字段为 NULL |
| `advv` | decimal(25,10) | 广告价值量（Ad Value × Volume）：CPC 广告为 `origin_bid_price × raw_click / 100000`，非 CPC 搜索广告为 `raw_expense / 100000`，已换算为 USD ⚠️ **仅搜索广告（placement in 0,4,1000,1200 且 entrance=1）有值**，推荐广告该字段为 NULL；为预计算值，不可与本地货币字段混合聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐值 / 说明 | 遗漏后果 |
|----------|--------------|----------|
| `grass_date` | 指定目标日期，如 `grass_date = '2025-01-01'` | 触发全分区扫描，产生大量不必要 I/O |
| `grass_region` | 指定目标地区大写编码，如 `grass_region = 'MY'` | 读取所有地区数据，结果混合多地区本地货币指标，汇总结果无意义 |
| `tz_type` | **必须固定为 `tz_type = 'local'`** | 当前表仅写入 `local` 分区，遗漏该条件不会多读数据，但建议显式指定以确保语义正确并利用分区裁剪 |

> **重要**：本地货币字段（`ads_gmv`、`ads_revenue`、`ads_broad_gmv` 等）在不同地区单位不同，**跨地区聚合必须先转换为 USD 字段**再 SUM，或限定单一 `grass_region` 查询。

---

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|-------------|
| `ads_gmv_usd` | ETL 已将本地 GMV 除以汇率写入，若跨日期或跨地区 SUM 时汇率不同，直接 SUM 在语义上正确；但**不可**将 USD 字段与本地货币字段混合使用 | 单地区同口径下可直接 SUM；跨地区请确认各地区均已换算为 USD |
| `ads_revenue_usd` | 同上 | 同 `ads_gmv_usd` |
| `ads_daily_gmv_usd` | 同上 | 同 `ads_gmv_usd` |
| `ads_broad_gmv_usd` | 同上 | 同 `ads_gmv_usd` |
| `ads_daily_gmv_usd_500` | 已在 ETL 中**按订单行截断后 SUM**，直接对本表记录求和语义正确；但若尝试从原始明细重新计算需回溯至 DWD 层，**不可**从本表的非截断字段推导截断值 | 直接 SUM 本字段；如需重算请使用 DWD 层原始数据 |
| `ads_daily_gmv_usd_200` | 同上 | 同 `ads_daily_gmv_usd_500` |
| `ads_order_gmv_usd_500` | 同上 | 同 `ads_daily_gmv_usd_500` |
| `ads_order_gmv_usd_200` | 同上 | 同 `ads_daily_gmv_usd_500` |
| `advv` | 仅搜索广告有值（NULL 表示推荐广告），SUM 时会自动忽略 NULL，但分析时需明确筛选 `placement in (0,4,1000,1200) and entrance = 1` | 加上 placement/entrance 过滤后再 SUM |
| `extreme_removed_ads_orders` | 仅搜索广告有值，推荐广告为 NULL | 筛选搜索广告后 SUM；混合场景下用 `SUM(COALESCE(..., 0))` 并注意业务含义 |
| `extreme_removed_ads_gmv_usd` | 同上 | 同上 |

---

### 时效性说明

本表为 T+1 日更新，每次以 `INSERT OVERWRITE` 方式写入当日分区。查询最新数据时应使用 **昨日日期** 的分区（即 `grass_date = current_date - 1`），当日（T+0）数据尚未产出。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告明细层，提供用户级别的曝光、点击、成单、GMV、消耗等原始指标；亦用于 advv 的原始出价和点击数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于本地货币→USD 换算 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维表，提供用户与实验组的归属关系（`exp_group_id`），分搜索和推荐两套归因逻辑 |
| `srdi_mart.dim_sr_data_warehouse_exp` | 实验元数据维表，提供实验场景（scene_id）信息，用于过滤视频类实验的分组归因逻辑 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
    │
    ├──────────────────────────────────────────────────────────┐
    │  (用户级聚合，含汇率换算基础数据)                          │ (placement in 0,4,1000,1200, entrance=1)
    ▼                                                          ▼
ads_performance_base (cache table)              advv_base (搜索广告 advv 计算)
    │                                                          │
    ├── (placement in 0,4,1000,1200 → having 极端用户判定)      │
    ▼                                                          │
ads_search_extreme_users                                       │
    │                                                          │
    └─────────────────┬─────────────────────────────────────── ┘
                      ▼ (left join extreme_user_flag + advv)
              ads_performance_base_new
                      │
          ┌───────────┴────────────────────┐
          │                                │
  entrance NOT IN (3,4,8,9,10,11)   entrance IN (3,4,8,9,10,11)
  (搜索广告)                          (推荐广告: DD/YMAL等)
          │                                │
          ▼                                ▼
    search_group                    dd_ymal_group
 (is_assignment_log=1)          (is_dim_join=1 为主，
 from abtest_user_group          视频实验补充 is_assignment_log=1)
          │  INNER JOIN                    │  INNER JOIN
          ▼                                ▼
search_group_performance      dd_ymal_group_performance
 (有 extreme_removed / advv)   (extreme_removed / advv = NULL)
          │                                │
          └──────────── UNION ALL ──────────┘
                              │
                  LEFT JOIN mp_order.dim_exchange_rate
                  (本地货币 → USD 最终换算)
                              │
                              ▼
    INSERT OVERWRITE dws_advertise_user_exp_performance_1d__reg_s0_live
               partition(tz_type='local', grass_region, grass_date)
```

---

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|--------------|--------|------|
| `ads_performance_base` | `dwd_advertise_performance_di__reg_s0_live` + `dim_exchange_rate` | 用户级广告绩效汇总（含汇率，用于预计算 500/200 截断值）；cache table 提升后续多次引用性能 |
| `ads_search_extreme_users` | `ads_performance_base` | 识别搜索广告极端用户：placement in (0,4,1000,1200)，单日订单数≥50 或 GMV≥$200 |
| `advv_base` | `dwd_advertise_performance_di__reg_s0_live` | 搜索广告 ADVV 计算：CPC 用出价×点击，非 CPC 用原始消耗 |
| `ads_performance_base_new` | `ads_performance_base` + `advv_base` + `ads_search_extreme_users` | 合并极端用户标记和 advv，作为后续分链路处理的统一基础视图 |
| `search_group` | `dim_sr_data_warehouse_abtest_user_group` | 搜索广告实验分组：`is_assignment_log=1` |
| `dd_ymal_group` | `dim_sr_data_warehouse_abtest_user_group` + `dim_sr_data_warehouse_exp` | 推荐广告实验分组：主体用 `is_dim_join=1`；视频实验（scene_id in 588,171）改用 `is_assignment_log=1` |
| `search_group_performance` | `ads_performance_base_new` INNER JOIN `search_group` | 搜索广告链路按实验组汇总，含极端用户去除指标和 advv |
| `dd_ymal_group_performance` | `ads_performance_base_new` INNER JOIN `dd_ymal_group` | 推荐广告链路按实验组汇总，`extreme_removed` 和 `advv` 字段固定为 NULL |

---

### 注意事项

1. **实验分组归因逻辑差异**：搜索广告（entrance not in 3,4,8,9,10,11）和推荐广告（entrance in 3,4,8,9,10,11）使用不同的实验分组表过滤条件（`is_assignment_log` vs `is_dim_join`），两套逻辑 UNION ALL 后写入同一张表，查询时需注意 entrance 口径区分。

2. **极端用户字段仅对搜索广告有意义**：`extreme_removed_ads_orders`、`extreme_removed_ads_gmv_usd`、`advv` 三个字段在推荐广告（dd_ymal_group_performance）中固定为 NULL，使用前务必加 entrance 过滤或做 NULL 处理。

3. **截断 GMV 字段的计算时机**：`_500` / `_200` 截断是在用户行级别（按单笔订单换算 USD 后）执行的，之后再 SUM 至实验组粒度。本表存储的是已截断后的加总值，**不能**从本表的非截断 GMV 字段反推截断版本。

4. **两次汇率换算**：部分 USD 字段在 `ads_performance_base` 阶段已使用汇率预处理（_500/_200 截断），最终写入时又对本地货币字段做了第二次 `/ exchange_rate` 换算（`ads_gmv_usd`、`ads_revenue_usd`、`ads_daily_gmv_usd`、`ads_broad_gmv_usd`、`advv`）。若发现汇率更新导致数据重刷，上述两类字段均需重新计算。

5. **搜索广告 placement=9（CPM）**：消耗金额（`expenditure_amt_local`）由 `cpm × impression_cnt / 100000` 折算，点击数使用 `raw_click_cnt`，与其他 placement 口径不同，分析 CPM 广告时需注意。

6. **调度参数化**：ETL SQL 中 `upper('${region}')`、`date('${grass_date}')` 为模板参数，由调度系统按各地区本地时区逐地区执行，覆盖所有活跃地区，并非仅处理单一地区。

---

*文档生成时间：2026-04-22*