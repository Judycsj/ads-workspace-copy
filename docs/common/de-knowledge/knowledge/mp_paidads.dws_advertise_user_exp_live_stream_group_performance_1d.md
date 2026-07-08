<!-- ads-workspace-gdoc-sync: gdoc_id=1QVT90uS9Tv0DWj2pcoFyvx6jhivlq3WCkpdLxmbcPi4 gdoc_url=https://docs.google.com/document/d/1QVT90uS9Tv0DWj2pcoFyvx6jhivlq3WCkpdLxmbcPi4/edit -->

# mp_paidads.dws_advertise_user_exp_live_stream_group_performance_1d

**分层：** DWS（数据汇总层）
**主键：** `group_id` + `grass_region` + `grass_date` + `tz_type`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（T+1）
**引用频次：** 0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表记录**直播广告用户实验（A/B Test）各实验分组**在每日维度下的广告投放绩效汇总数据，是付费广告团队评估直播广告产品实验效果的核心数仓表。数据来源于直播广告曝光、点击、成交等行为明细，并与 AB 实验分组映射表关联，将广告用户行为聚合至实验组粒度，支持实验组间各项指标的横向对比。

核心使用场景包括：实验组 GMV、收入、订单转化率等核心指标的差异分析；不同实验组在曝光、点击、观看深度（location 分布）等漏斗环节的对比；以及广告主收入结构（免费额度 / 付费额度）的拆解分析。

本表覆盖直播广告场景，按本地时区（`tz_type='local'`）分区写入，各地区按各自本地时区参数化调度，数据口径统一，可直接用于跨地区实验效果横向比较和产品决策支撑。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前写入分区固定为 `'local'`（本地时区），查询时必须指定此字段过滤 |
| `grass_region` | string | 地区代码（大写），如 `'ID'`、`'TH'`、`'MY'` 等，各地区按本地时区参数化调度 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD` |

---

### 维度：主键与实验分组属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_id` | bigint | 用户实验分组 ID，来源于 `dim_live_stream_abtest_group`，是本表核心分析维度，用于区分 AB 实验中的不同分组 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp_cnt` | bigint | 广告曝光次数（Impression Count） |
| `ads_deduct_imp_cnt` | bigint | 扣费曝光次数，即实际产生计费的曝光量，与 `ads_imp_cnt` 含义不同，用于核对收入口径 |
| `ads_view_cnt` | bigint | 广告观看次数（View Count），与曝光有区分，指用户实际观看行为 |
| `ads_view_uu` | bigint | 产生观看行为的唯一用户数（去重） |
| `ads_view_duration` | bigint | 广告观看总时长（单位：秒，具体单位以上游字段为准） |
| `ads_raw_click_cnt` | bigint | 原始点击次数（含重复点击，未去重） |
| `ads_raw_click_uu` | bigint | 产生原始点击的唯一用户数（去重） |
| `ads_product_clk_cnt` | bigint | 商品点击次数（去重后的有效商品点击） |
| `ads_product_clk_uu` | bigint | 产生商品点击的唯一用户数（去重） |
| `expected_cpm` | decimal(25,10) | 预期 CPM（每千次曝光成本），计算方式：`SUM(expected_ads_rev) / SUM(impression_cnt) / 1000`，由分组级别聚合后再计算。⚠️ 为派生比率字段，不可直接 SUM，跨组合并时需用分子（`expected_ads_rev` 之和）除以分母（`ads_imp_cnt` 之和）再除以 1000 重新计算 |

---

### 指标：观看位置分布

| 字段 | 类型 | 说明 |
|------|------|------|
| `view1_5` | bigint | 直播流中位置（location）在 0~4 区间的观看次数（即直播列表前 5 位） |
| `view6_10` | bigint | 直播流中位置在 5~9 区间的观看次数 |
| `view11_15` | bigint | 直播流中位置在 10~14 区间的观看次数 |
| `view16_20` | bigint | 直播流中位置在 15~19 区间的观看次数 |
| `view21_25` | bigint | 直播流中位置在 20~24 区间的观看次数 |
| `view26_30` | bigint | 直播流中位置在 25~29 区间的观看次数 |
| `view30_plus` | bigint | 直播流中位置 ≥ 30 的观看次数 |

---

### 指标：订单与转化

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_direct_order_cnt` | bigint | 直接订单数：用户在 7 天内有对该订单商品的广告点击行为所产生的订单 |
| `ads_direct_order_uu` | bigint | 产生直接订单的唯一用户数（去重） |
| `ads_broad_order_cnt` | bigint | 泛化订单数：用户在 7 天内对同一店铺有广告点击（点击不必须在订单商品上）所产生的订单 |
| `ads_broad_order_uu` | bigint | 产生泛化订单的唯一用户数（去重） |
| `ads_direct_item_sold_cnt` | bigint | 直接订单中的商品销售件数 |
| `ads_direct_item_sold_uu` | bigint | 产生直接商品销售的唯一用户数（去重） |
| `ads_broad_item_sold_cnt` | bigint | 泛化订单中的商品销售件数 |
| `ads_broad_item_sold_uu` | bigint | 产生泛化商品销售的唯一用户数（去重） |
| `ads_daily_item_sold_cnt` | bigint | Daily 口径商品销售件数（源字段 `daily_item_sold_cnt`，含义与 Daily GMV 口径对应） |
| `ads_daily_item_sold_uu` | bigint | Daily 口径下产生商品销售的唯一用户数（去重） |
| `checkout_cnt` | bigint | 宽口径结算订单数：订单内任意商品在 7 天内有泛化广告点击即计入，通过 `count distinct order_id` 计算 |

---

### 指标：GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_direct_gmv` | decimal(25,10) | 直接订单 GMV（本地货币） |
| `ads_direct_gmv_usd` | decimal(25,10) | 直接订单 GMV（USD），由 `ads_order_gmv_local / exchange_rate` 计算得出。⚠️ 为派生字段，跨分区或跨地区汇总时需注意汇率口径一致性，不可直接与本地货币字段混用 |
| `ads_direct_gmv_usd_500` | decimal(25,10) | 直接订单 GMV（USD），单用户贡献上限 500 USD。⚠️ 为截断处理后的汇总值，不可直接 SUM 后与无截断字段进行口径对比；跨组合并时可直接 SUM |
| `ads_direct_gmv_usd_200` | decimal(25,10) | 直接订单 GMV（USD），单用户贡献上限 200 USD。⚠️ 同上，为截断处理后的汇总值 |
| `ads_broad_gmv` | decimal(25,10) | 泛化订单 GMV（本地货币） |
| `ads_broad_gmv_usd` | decimal(25,10) | 泛化订单 GMV（USD），由 `broad_gmv_amt_local / exchange_rate` 计算得出。⚠️ 为派生字段，注意汇率口径 |
| `ads_daily_gmv` | decimal(25,10) | Daily 口径订单 GMV（本地货币） |
| `ads_daily_gmv_usd` | decimal(25,10) | Daily 口径订单 GMV（USD）。⚠️ 为派生字段，注意汇率口径 |
| `ads_daily_gmv_usd_500` | decimal(25,10) | Daily 口径 GMV（USD），单用户贡献上限 500 USD。⚠️ 为截断处理后的汇总值，不可与无截断字段混用 |
| `ads_daily_gmv_usd_200` | decimal(25,10) | Daily 口径 GMV（USD），单用户贡献上限 200 USD。⚠️ 为截断处理后的汇总值 |

---

### 指标：广告收入与费用结构

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_revenue` | decimal(25,10) | 广告收入（本地货币），即广告主的实际支出总额 |
| `ads_revenue_usd` | decimal(25,10) | 广告收入（USD），由 `ads_rev / exchange_rate` 计算得出。⚠️ 为派生字段，汇率为当日汇率，跨日或跨地区汇总需注意汇率一致性 |
| `rev_free_credit_with_expiry` | decimal(25,10) | 免费额度（有过期限制）抵扣的广告费用 |
| `rev_free_credit_without_expiry` | decimal(25,10) | 免费额度（无过期限制）抵扣的广告费用 |
| `rev_paid_credit_with_expiry` | decimal(25,10) | 付费额度（有过期限制）抵扣的广告费用 |
| `rev_paidcredit_without_expiry` | decimal(25,10) | 付费额度（无过期限制）抵扣的广告费用 |

---

### 指标：代理人（Agent）相关

| 字段 | 类型 | 说明 |
|------|------|------|
| `agent_order_cnt` | bigint | Agent 订单数：订单内任意商品有 1 天内 Agent 点击即计入，参考 Confluence 文档定义 |
| `agent_item_cnt` | bigint | Agent 订单中的商品销售件数 |
| `agent_checkout` | bigint | Agent 结算订单数，通过 `count distinct order_id` 计算（订单内任意商品有 1 天内 Agent 点击即计入） |
| `agent_gmv_amt_local` | decimal(25,10) | Agent 订单 GMV（本地货币） |
| `agent_gmv_amt_usd` | decimal(25,10) | Agent 订单 GMV（USD），由 `agent_gmv_amt_local / exchange_rate` 计算得出。⚠️ 为派生字段，注意汇率口径 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**指定以下分区字段，否则将触发全表扫描，导致查询超时并产生不必要的计算资源消耗：

| 分区字段 | 推荐过滤方式 | 遗漏后果 |
|----------|-------------|---------|
| `tz_type` | 固定写 `tz_type = 'local'` | 当前仅写入 `local` 分区，遗漏会导致分区裁剪失效，扫描无效分区 |
| `grass_region` | 指定目标地区，如 `grass_region = 'ID'` | 遗漏将跨地区全量扫描，数据量倍增 |
| `grass_date` | 指定目标日期，如 `grass_date = '2026-04-21'` | 遗漏将全量历史数据扫描，严重影响性能 |

**示例过滤条件：**
```sql
WHERE tz_type = 'local'
  AND grass_region = 'ID'
  AND grass_date = '2026-04-21'
```

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|-------------|
| `expected_cpm` | 派生比率字段，由 `SUM(expected_ads_rev) / SUM(impression_cnt) / 1000` 预计算得出 | 跨 `group_id` 或跨日期聚合时，需对源数据重新计算：`SUM(expected_cpm * ads_imp_cnt) / SUM(ads_imp_cnt)` 是近似做法，精确做法需回溯上游明细 |
| `ads_revenue_usd` | 由本地货币 `ads_revenue` 除以当日汇率得出，汇率非线性 | 跨地区汇总时，应使用各自地区的 USD 字段直接 SUM，不可用本地货币字段换算后加总 |
| `ads_direct_gmv_usd` | 同上，派生汇率换算字段 | 跨地区直接 SUM 该 USD 字段即可；但不可用 `ads_direct_gmv`（本地货币）汇总后再换算 |
| `ads_broad_gmv_usd` | 同上 | 同 `ads_direct_gmv_usd` |
| `ads_daily_gmv_usd` | 同上 | 同 `ads_direct_gmv_usd` |
| `agent_gmv_amt_usd` | 同上 | 同 `ads_direct_gmv_usd` |
| `ads_direct_gmv_usd_500` | 用户级别 500 USD 截断后聚合，已非原始 GMV | 与无截断字段混用会导致口径不一致；截断字段本身可以跨组 SUM，但不能与 `ads_direct_gmv_usd` 直接比较绝对值 |
| `ads_direct_gmv_usd_200` | 用户级别 200 USD 截断后聚合 | 同上 |
| `ads_daily_gmv_usd_500` | 同上（500 USD 截断） | 同上 |
| `ads_daily_gmv_usd_200` | 同上（200 USD 截断） | 同上 |

### 时效性说明

本表为 **T+1** 写入，每日分区数据对应前一天的业务数据。查询最新数据时应取 `MAX(grass_date)` 或指定 `grass_date = CURRENT_DATE - 1`。本表无 YTD/TD 累计字段，所有指标均为**当日增量**，如需累计值需在查询层自行 SUM 多日分区。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告行为明细数据，提供曝光、点击、观看、GMV、订单、代理人等所有广告绩效原始指标 |
| `mp_paidads.dim_live_stream_abtest_group__reg_s0_live` | 直播广告 AB 实验分组维表，提供用户与实验分组（`group_id`）的映射关系 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供当日各地区本地货币对 USD 的汇率，用于本地货币转 USD 换算 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live
  （直播广告行为明细，过滤 grass_date / grass_region / tz_type='local'）
          │
          │ LEFT JOIN
          ▼
mp_order.dim_exchange_rate__reg_s0_live
  （当日汇率，用于预计算 USD 截断 GMV）
          │
          ▼
  [CTE: ads_performance_base]
  按 (grass_region, user_id) 聚合广告行为指标
  计算用户级别 500/200 USD 截断 GMV
          │
          │ INNER JOIN
          ▼
mp_paidads.dim_live_stream_abtest_group__reg_s0_live
  （AB 实验分组映射，过滤 grass_date / grass_region）
          │
          ▼
  [CTE: live_stream_group_performance]
  按 (grass_region, group_id) 聚合
  计算 UU 去重指标（count distinct user_id）
          │
          │ LEFT JOIN
          ▼
mp_order.dim_exchange_rate__reg_s0_live
  （再次 JOIN 汇率，用于最终本地货币 → USD 转换）
          │
          ▼
dws_advertise_user_exp_live_stream_group_performance_1d
  PARTITION (tz_type='local', grass_region, grass_date)
  INSERT OVERWRITE 写入
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `ads_performance_base` | `dwd_livestream_performance_di`（主）+ `dim_exchange_rate`（汇率） | 按 `(grass_region, user_id)` 聚合广告行为原始指标；在用户粒度预计算 500/200 USD 截断 GMV，为后续分组聚合提供用户级中间结果 |
| `live_stream_group_performance` | `ads_performance_base`（主）+ `dim_live_stream_abtest_group`（实验分组） | INNER JOIN 实验分组映射，按 `(grass_region, group_id)` 聚合；计算各指标的 UU 去重值（`count distinct user_id WHERE metric > 0`） |

### 注意事项

1. **汇率 JOIN 发生两次**：第一次在 `ads_performance_base` 中用于用户级别 500/200 USD 截断 GMV 的预计算；第二次在最终 INSERT 中将分组级本地货币汇总值统一转换为 USD。两次均使用 `LEFT OUTER JOIN`，当汇率缺失时 USD 相关字段将为 `NULL`，需关注数据完整性。

2. **INNER JOIN 实验分组导致数据过滤**：`ads_performance_base` 与 `dim_live_stream_abtest_group` 采用 INNER JOIN，未在实验分组中的用户数据将被排除。因此本表数据量 ≤ 上游直播广告数据量，不可用于全量广告效果分析。

3. **`expected_cpm` 的计算时序问题**：`expected_cpm` 在 INSERT 阶段以 `expected_ads_rev / impression_cnt / 1000`（分组级别）计算写入，分子分母均为分组聚合后的值，精度较高；但若 `impression_cnt = 0` 将产生除零异常，查询时需注意空值处理。

4. **UU 指标的计算口径**：所有 `_uu` 字段在 `live_stream_group_performance` CTE 中以 `count distinct user_id WHERE metric > 0` 计算，基于实验组内去重，**不可跨组直接加总**（同一用户可能分属不同分组边界，实验设计上应互斥，但数据使用时需确认实验分组是否互斥）。

5. **各地区按本地时区参数化调度**：ETL 中 `grass_region`、`grass_date`、`region` 均为调度参数，覆盖所有支持地区，文档中出现的具体地区代码仅为示例，不代表单地区覆盖。

---

*文档生成时间：2026-04-22*