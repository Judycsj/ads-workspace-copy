<!-- ads-workspace-gdoc-sync: gdoc_id=1LFUcWTKNTH0QoSMvrAFQwkJZ_ptv7eS8fV1ZXjOR4oI gdoc_url=https://docs.google.com/document/d/1LFUcWTKNTH0QoSMvrAFQwkJZ_ptv7eS8fV1ZXjOR4oI/edit -->

# mp_paidads.ads_advertise_alarm_key_metrics_1d

**分层：** ADS（应用数据服务层）
**主键：** `shop_id` + `campaign_id` + `ads_id` + `item_id` + `pricing_type` + `placement` + `product_type` + `sub_product_type` + `traffic_type` + `entry_point` + `entrance` + `tz_type` + `grass_region` + `grass_date`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日一次（T+1）
**引用频次：** 0（末端 ADS 层表，不被其他候选表引用）

---

## 业务描述

本表为付费广告**广告主预警监控**场景提供每日关键指标快照，聚合维度覆盖广告（`ads_id`）、推广活动（`campaign_id`）、店铺（`shop_id`）三个层级。表中同时保存了广告投放绩效指标（曝光、点击、消耗、GMV、订单）、预算执行情况（有效预算、账户余额）以及两个预警标志位（活动预算达量标志 `if_campaign_hit`、活动浪费标志 `if_campaign_waste`），可用于运营或系统自动触发预警规则，识别"预算跑满"、"有消耗无转化"等异常广告活动。

本表是广告运营报警系统的基础数据源，适用于：日常广告健康度巡检、活动级别预算耗尽检测、无效投放（浪费）识别、广告主分层监控等场景。数据在广告（ads_id）粒度存储的同时，通过窗口函数预计算了 campaign 级与 shop 级的汇总消耗，下游应用可直接使用，无需二次聚合。

各地区按本地时区参数化调度，写入对应 `grass_region` 分区，实现多地区统一数据模型覆盖。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前 ETL 仅写入 `'local'`（本地时区）分区；查询时**必须**指定此字段过滤 |
| `grass_region` | string | 地区代码，大写，如 `'MX'`、`'BR'` 等，各地区独立调度写入 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD` |

---

### 维度：主键与广告层级属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主的唯一标识 |
| `campaign_id` | bigint | 推广活动 ID |
| `ads_id` | bigint | 广告 ID，数据存储的最细粒度 |
| `item_id` | bigint | 推广商品 ID |

---

### 维度：广告主与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_name` | string | 店铺名称，来源于 `dim_shop_info` |
| `advertiser_tier` | string | 广告主分层标签（如头部/腰部/长尾等） |
| `seller_tier` | string | 卖家分层标签 |
| `shop_level1_global_be_category` | string | 店铺全球一级类目 |
| `shop_level2_global_be_category` | string | 店铺全球二级类目 |

---

### 维度：广告产品与投放属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `pricing_type` | int | 计价方式，如 CPC / CPM 等对应的枚举值 |
| `placement` | int | 广告位类型枚举值 |
| `main_product_type` | string | 主广告产品类型 |
| `product_type` | string | 广告产品类型 |
| `sub_product_type` | string | 广告产品子类型 |
| `traffic_type` | string | 流量类型（如站内/站外等） |
| `entry_point` | string | 广告入口点 |
| `entrance` | int | 广告入口枚举值 |

---

### 指标：广告绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_rev_usd_1d` | double | 单条广告当日消耗金额（USD），来自 `ads_advertise_mkt_1d` 中 `ads_expenditure_amt_usd` 的汇总 |
| `ads_impression_1d` | bigint | 单条广告当日曝光次数 |
| `ads_click_1d` | bigint | 单条广告当日点击次数 |
| `cps_dedup_click_cnt_1d` | bigint | CPS 去重点击数，用于 CPS 类广告的点击计量 |
| `direct_order_1d` | bigint | 当日直接归因订单数 |
| `broad_order_1d` | bigint | 当日宽泛归因订单数（含间接转化） |
| `direct_gmv_usd_1d` | double | 当日直接归因 GMV（USD） |
| `broad_gmv_usd_1d` | double | 当日宽泛归因 GMV（USD） |

---

### 指标：Campaign 与 Shop 汇总消耗

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_ads_rev_usd_1d` | double | Campaign 级当日总消耗（USD）。由窗口函数 `sum(ads_rev_usd_1d) over(partition by campaign_id)` 预计算，同一 campaign 下所有行该值相同。⚠️ 为预聚合派生字段，在 campaign 粒度外直接 SUM 会导致重复计算，应先按 campaign_id 去重后再聚合 |
| `shop_ads_rev_usd_1d` | double | Shop 级当日总消耗（USD）。由窗口函数 `sum(ads_rev_usd_1d) over(partition by shop_id)` 预计算，同一 shop 下所有行该值相同。⚠️ 为预聚合派生字段，在 shop 粒度外直接 SUM 会导致重复计算，应先按 shop_id 去重后再聚合 |

---

### 指标：预算与账户余额

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_valid_budget_usd_1d` | double | Campaign 级有效预算（USD），来源于 `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live`。⚠️ 同一 campaign 下所有 ads 行该值相同，直接 SUM 会导致重复计算 |
| `shop_valid_budget_usd_1d` | double | Shop 级有效预算汇总（USD），为 shop 下所有 campaign 有效预算之和。⚠️ 同一 shop 下所有行该值相同，直接 SUM 会导致重复计算 |
| `budget_usd` | double | Campaign 设置的预算金额（USD），来源于 `ads_campaign_valid_budget_1d` |
| `account_balance_usd` | double | 广告账户余额（USD），来源于 `ads_campaign_valid_budget_1d` |

---

### 指标：预警标志

| 字段 | 类型 | 说明 |
|------|------|------|
| `if_campaign_hit` | tinyint | Campaign 预算达量标志。当 `round(campaign_ads_rev_usd_1d, 5) / round(campaign_valid_budget_usd_1d, 5) >= 1` 时为 `1`，否则为 `0`。⚠️ 为派生布尔标志，不可直接 SUM 用于比率计算；需重新用分子/分母字段计算；当 `campaign_valid_budget_usd_1d = 0` 时存在除零风险，ETL 中未做特殊处理 |
| `if_campaign_waste` | tinyint | Campaign 浪费标志。过去 14 天（含当日）内，campaign 有广告消耗（`ads_expenditure_amt_usd > 0`）但直接订单数为 0 时标记为 `1`，否则为 `0`。⚠️ 为 14 日滚动窗口计算的派生标志，时效性与单日数据不同；不可直接 SUM |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，避免全表扫描：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 当前数据仅有 `local` 分区；若未来扩展其他时区类型，遗漏将导致数据重复或全表扫描 |
| `grass_region` | `grass_region = 'MX'`（按需替换） | 遗漏将扫描全部地区分区，产生大量不必要的 I/O |
| `grass_date` | `grass_date = '2026-04-21'` | 遗漏将扫描历史全量数据，极易超时或产生错误结果 |

> 示例：
> ```sql
> WHERE tz_type = 'local'
>   AND grass_region = 'MX'
>   AND grass_date = '2026-04-21'
> ```

---

### 不可直接 SUM 的字段

以下字段为预聚合或派生计算结果，直接 `SUM` 会导致重复计算或语义错误：

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|--------------|
| `campaign_ads_rev_usd_1d` | 窗口函数预计算，同一 campaign 下所有 ads 行重复存储该值 | 需先按 `campaign_id` 去重（`MAX` 或 `FIRST`），再在 campaign 粒度聚合 |
| `shop_ads_rev_usd_1d` | 窗口函数预计算，同一 shop 下所有 ads 行重复存储该值 | 需先按 `shop_id` 去重（`MAX` 或 `FIRST`），再在 shop 粒度聚合；或直接用 `SUM(ads_rev_usd_1d)` 在 shop 粒度自行汇总 |
| `campaign_valid_budget_usd_1d` | 同一 campaign 下所有 ads 行重复存储 | 按 `campaign_id` 去重后使用，如 `SUM(DISTINCT campaign_valid_budget_usd_1d)` 不可靠，推荐子查询去重 |
| `shop_valid_budget_usd_1d` | 同一 shop 下所有 ads 行重复存储 | 按 `shop_id` 去重后使用 |
| `budget_usd` | Campaign 维度预算，在 ads 粒度重复 | 按 `campaign_id` 去重后聚合 |
| `account_balance_usd` | Shop/账户维度，在 ads 粒度重复 | 按 `shop_id` 去重后聚合 |
| `if_campaign_hit` | 预警标志位（0/1），SUM 无实际业务意义 | 用 `MAX(if_campaign_hit)` 在 campaign 粒度取值，或直接 `COUNT(IF(if_campaign_hit=1, 1, NULL))` 统计达量活动数 |
| `if_campaign_waste` | 预警标志位（0/1），SUM 无实际业务意义 | 同上，用 `MAX` 或 `COUNT(IF(...))` |

---

### 时效性说明

- `if_campaign_waste` 基于**过去 14 天滚动窗口**计算，并非当日单日口径，查询时需注意其时效语义与其他单日指标不同。
- 其余指标均为 `grass_date` 对应的**单日（1d）**口径，取最新分区即可获取最近一日数据。
- 建议始终取 **T-1** 日（即昨日）的 `grass_date` 分区，确保数据已完成写入。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 广告日粒度市场投放明细，提供曝光、点击、消耗、订单、GMV 等核心绩效指标；同时用于 14 日滚动窗口计算 `if_campaign_waste` |
| `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | Campaign 级有效预算、账户余额、预算金额，提供 `campaign_valid_budget_usd`、`account_balance_usd`、`budget_usd` |
| `mp_paidads.dim_shop_info__reg_s0_live` | 店铺维度信息，提供 `seller_name`、`shop_level1/2_global_be_category` |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_advertise_mkt_1d__reg_s0_live
  │
  ├──[当日数据，按 shop/campaign/ads 等维度聚合]──► CTE: ads_perf
  │     (sum: 消耗、曝光、点击、订单、GMV、CPS去重点击)
  │
  └──[近14日数据，按 campaign 聚合判断有无订单]──► CTE: campaign_waste
        (标记 if_campaign_waste)

mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live
  │
  ├──────────────────────────────────────────────► CACHE: valid_budget
  │     (campaign_valid_budget_usd, account_balance_usd, budget_usd)
  │
  └──[按 shop_id 汇总 campaign 有效预算]──────────► 子查询: shop_valid_budget

mp_paidads.dim_shop_info__reg_s0_live
  │
  └──────────────────────────────────────────────► CTE: shop_info
        (seller_name, shop level1/2 category)

ads_perf
  LEFT JOIN valid_budget        (on shop_id + campaign_id)
  LEFT JOIN shop_info           (on shop_id)
  LEFT JOIN campaign_waste      (on campaign_id)
  LEFT JOIN shop_valid_budget   (on shop_id)
  │
  [窗口函数预计算 campaign/shop 级消耗汇总]
  [COALESCE 补零]
  │
  ▼
mp_paidads.ads_advertise_alarm_key_metrics_1d__reg_s0_live
  PARTITION(tz_type='local', grass_region, grass_date)
  INSERT OVERWRITE
```

---

### 关键 CTE 说明

| CTE / 视图名 | 来源表 | 作用 |
|-------------|--------|------|
| `ads_perf` | `ads_advertise_mkt_1d__reg_s0_live` | 过滤当日活跃广告（`is_ads_active=1 OR has_performance=1`），按广告维度聚合消耗、曝光、点击、订单、GMV、CPS去重点击 |
| `valid_budget`（CACHE） | `ads_campaign_valid_budget_1d__reg_s0_live` | 获取 campaign 级有效预算、账户余额、预算金额；显式 CACHE 到内存+磁盘以支持两次 JOIN（campaign 级和 shop 级汇总） |
| `shop_info` | `dim_shop_info__reg_s0_live` | 获取店铺名称与类目标签 |
| `campaign_waste` | `ads_advertise_mkt_1d__reg_s0_live` | 过去 14 天滚动窗口，判断 campaign 是否存在"有消耗无订单"浪费情况 |
| `shop_valid_budget`（子查询） | `valid_budget`（CACHE） | 将 campaign 级有效预算按 shop_id 汇总，生成 shop 级有效预算 `shop_valid_budget_usd_1d` |

---

### 注意事项

1. **活跃广告过滤**：`ads_perf` 和 `campaign_waste` 均过滤 `is_ads_active = 1 OR has_performance = 1`，即只保留当前有效或有历史投放记录的广告，非活跃且无绩效的广告不进入本表。

2. **`if_campaign_hit` 除零风险**：ETL 中直接用 `round(campaign_ads_rev_usd_1d,5) / round(campaign_valid_budget_usd,5)` 计算，当 `campaign_valid_budget_usd = 0` 时将产生 `NULL` 或除零异常，导致该条记录 `if_campaign_hit` 为 `0`（`case when` 条件不成立），使用时需知晓此边界情况。

3. **`if_campaign_waste` 为 14 日滚动口径**：其统计窗口为 `[grass_date - 13, grass_date]`，与其他所有 `_1d` 字段的单日口径不同，不可混用于同一时间维度的比率计算。

4. **写入模式为 INSERT OVERWRITE**：每次调度覆盖写入当日分区，数据幂等，重跑安全；但历史分区一经覆盖不可恢复，需注意回刷历史时的影响范围。

5. **`cps_dedup_click_cnt_1d` 字段命名**：DDL 中字段名为 `cps_dedup_click_cnt_1d`，但 ETL SELECT 列表中对应列名为 `cps_dedup_click_cnt`（无 `_1d` 后缀），已通过列位置顺序对应写入，使用时以表字段名 `cps_dedup_click_cnt_1d` 为准。

6. **多地区参数化调度**：`${region}`、`${grass_date}`、`${timezone}` 均为调度系统注入的模板参数，各地区独立调度，写入各自 `grass_region` 分区，本表覆盖所有已接入的付费广告地区。

---

*文档生成时间：2026-04-22*