<!-- ads-workspace-gdoc-sync: gdoc_id=1y6MBZQQHihgku9oV8JSS0D8aHm86ke9kNYKUqj2ys5E gdoc_url=https://docs.google.com/document/d/1y6MBZQQHihgku9oV8JSS0D8aHm86ke9kNYKUqj2ys5E/edit -->

# mp_paidads.ads_advertise_shop_ads_exp_performance_1d

**分层**：ADS（应用数据服务层）
**主键**：`exp_id` + `placement` + `pricing_type` + `platform` + `entrance` + `location` + `shop_recall_type` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表面向**店铺广告（Shop Ads）A/B 实验分析**场景，以实验号（`exp_id`）为核心维度，按天汇总各实验分组在不同广告位（`placement`）、计费方式（`pricing_type`）、平台（`platform`）、入口（`entrance`）、位置（`location`）、召回类型（`shop_recall_type`）下的广告绩效指标，供算法与产品团队衡量各 A/B 实验方案的效果差异。

核心价值体现在三个维度：**流量漏斗**（曝光→点击→加购→结算→成单）、**GMV 贡献**（直接归因与广义归因）、以及**广告相关性质量**（基于热门关键词与非热门关键词的相关/somewhat/不相关曝光量分类统计）。相关性指标可辅助评估实验方案在广告质量层面的影响，是业务策略迭代的重要参考。

表的写入逻辑采用 `insert overwrite partition` 方式，各地区按本地时区参数化调度，覆盖全量地区；仅写入 `tz_type='local'` 分区，使用时应固定该值以确保查询准确性和效率。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `tz_type` | string | 时区类型，当前写入值固定为 `'local'`（本地时区）。⚠️ 查询时必须显式过滤 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 地区/市场代码（大写），如 `'ID'`、`'TH'`、`'MY'` 等，各地区按调度参数独立写入 |
| `grass_date` | date | 数据统计日期（本地时区），格式 `yyyy-MM-dd` |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_id` | string | A/B 实验号，从广告请求的 `ab_sign` 字段中解析展开得到，一条广告记录可能对应多个实验 ID（EXPLODE 展开）。⚠️ 因 EXPLODE 展开，汇总全局指标时需注意去重或仅在同一 exp_id 维度下聚合，避免重复计数 |
| `placement` | int | 广告位编码，本表仅覆盖店铺广告相关位置（3、2003、2030、20） |
| `pricing_type` | int | 计费类型编码，如 CPC（1）、CPM（2）等 |
| `platform` | string | 流量平台，如 `'ios'`、`'android'`、`'web'` 等 |
| `entrance` | int | 广告入口编码 |
| `location` | int | 广告展示位置编码（页面内的具体坑位） |
| `shop_recall_type` | bigint | 店铺广告召回类型，标识该广告请求使用的召回策略 |

---

### 指标：流量漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `impression_cnt` | bigint | 广告曝光次数 |
| `click_cnt` | bigint | 广告有效点击次数（去重/过滤后） |
| `raw_click_cnt` | bigint | 广告原始点击次数（未经过滤），通常大于 `click_cnt` |
| `add_to_cart_cnt` | bigint | 加购次数（归因于该广告） |
| `checkout_cnt` | bigint | 结算次数（到达结算页，归因于该广告） |

---

### 指标：广告绩效——直接归因

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_order_cnt` | bigint | 直接归因订单数（用户点击广告后直接产生的订单） |
| `direct_gmv` | decimal(25,10) | 直接归因 GMV（本地货币金额） |
| `direct_gmv_usd` | decimal(25,10) | 直接归因 GMV（美元） |
| `direct_item_sold_cnt` | bigint | 直接归因售出商品件数 |
| `direct_advv_usd` | double | 直接归因广告价值量（USD）；CPC/CPM 类型取广告花费，其余类型取直接 GMV × 目标 CIR。⚠️ 为派生计算字段（含条件分支逻辑），不可与其他金额字段直接 SUM 混用，需理解口径后使用 |

---

### 指标：广告绩效——广义归因

| 字段 | 类型 | 说明 |
|---|---|---|
| `broad_order_cnt` | bigint | 广义归因订单数（包含间接归因的订单） |
| `broad_gmv` | decimal(25,10) | 广义归因 GMV（本地货币金额） |
| `broad_gmv_usd` | decimal(25,10) | 广义归因 GMV（美元） |
| `broad_item_sold_cnt` | bigint | 广义归因售出商品件数 |
| `broad_advv_usd` | double | 广义归因广告价值量（USD）；CPC/CPM 类型取广告花费，其余类型取广义 GMV × 目标 CIR。⚠️ 为派生计算字段（含条件分支逻辑），不可与其他金额字段直接 SUM 混用，需理解口径后使用 |

---

### 指标：广告收入与花费明细

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue` | decimal(25,10) | 广告花费总额（本地货币），对应上游 `expenditure_amt_local` |
| `revenue_usd` | decimal(25,10) | 广告花费总额（美元），对应上游 `expenditure_amt_usd` |
| `rev_free_credit_with_expiry` | decimal(25,10) | 免费额度（有有效期）部分的广告花费 |
| `rev_free_credit_without_expiry` | decimal(25,10) | 免费额度（无有效期）部分的广告花费 |
| `rev_paid_credit_with_expiry` | decimal(25,10) | 付费额度（有有效期）部分的广告花费 |
| `rev_paid_credit_without_expiry` | decimal(25,10) | 付费额度（无有效期）部分的广告花费 |

---

### 指标：广告相关性——热门关键词维度

> 仅统计 **热门关键词**（来自 `shopads_popular_keyword`）下的展示请求，且仅取 top-3 排名商品的相关性评分，满足 `irre_count + somewhat + relevant = 3` 的请求方计入。

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_relevant_impr_cnt` | bigint | 热门关键词下，相关（`final_relevance_score >= max_threshold`）的广告请求数 |
| `shop_somewhat_impr_cnt` | bigint | 热门关键词下，somewhat 相关（`min_threshold ≤ score < max_threshold`）的广告请求数 |
| `shop_irrelevant_impr_cnt` | bigint | 热门关键词下，不相关（`score < min_threshold`）的广告请求数 |

---

### 指标：广告相关性——非热门关键词维度

> 仅统计 **非热门关键词**（不在 `shopads_popular_keyword` 中）下的展示请求，统计规则同上。

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_non_popular_keyword_relevant_impr_cnt` | bigint | 非热门关键词下，相关的广告请求数 |
| `shop_non_popular_keyword_somewhat_impr_cnt` | bigint | 非热门关键词下，somewhat 相关的广告请求数 |
| `shop_non_popular_keyword_irrelevant_impr_cnt` | bigint | 非热门关键词下，不相关的广告请求数 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**在 WHERE 子句中指定以下分区字段，否则将触发全分区扫描，导致查询超时及资源浪费：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|---|---|---|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `local` 分区，不过滤则全量扫描且无实际区分价值 |
| `grass_region` | `grass_region = 'ID'`（按需指定） | 不过滤将扫描所有地区，计算量倍增且结果混合多地区数据 |
| `grass_date` | `grass_date = '2026-04-21'` 或范围限定 | 不过滤将全量读取历史数据，引发严重性能问题 |

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确做法 |
|---|---|---|
| `direct_advv_usd` | 派生字段，含 `pricing_type` 条件分支（CPC/CPM 用花费，其他用 GMV × CIR），语义不同行之间不能简单累加 | 需明确业务口径，按 `pricing_type` 分组分别处理或追溯上游原始字段重算 |
| `broad_advv_usd` | 同上，广义归因版本的派生字段 | 同上 |
| `exp_id` 维度下的所有指标 | `exp_id` 由 EXPLODE 展开，一次广告请求可能出现在多个实验分组中，跨 `exp_id` 汇总会导致重复计数 | 仅在固定 `exp_id` 条件下聚合；若需全局汇总应回溯上游明细表 |
| 相关性系列字段（`shop_*_impr_cnt`） | 统计口径为"满足 top-3 item 且 `irre_count+somewhat+relevant=3`"的请求数，与 `impression_cnt` 分母不同，不可混用做比率计算 | 计算相关率时以各类相关性字段之和为分母，不使用 `impression_cnt` |

### 时效性说明

- 本表为 **T+1** 日调度，`grass_date` 对应统计日（本地时区），数据延迟约 1 天。
- 查询最新数据时应取 `grass_date = CURRENT_DATE - 1`（或确认调度已完成的最近日期）。
- 相关性指标额外依赖 `shopads_popular_keyword` 维表的 `dt` 分区，若维表未及时更新，当日相关性字段可能为 NULL 或偏低，使用时需关注。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 主要事实表，提供广告流量漏斗指标（曝光、点击、加购、成单）、GMV 及花费明细；同时提供 `ab_sign` 用于实验号解析 |
| `mp_paidads.ods_log_trace_shop_ads_hi__reg_s0_live` | 店铺广告原始 trace 日志，提供请求级别的 `ads`、`ab_sign`、`session_id` 等信息，用于构建相关性评分视图 |
| `mkplpaidads_data.dwd_advertise_tracking_shop_hi__reg_s0_live` | 店铺广告 tracking 日志，提供广告请求对应的搜索关键词（`query.keyword`） |
| `mp_paidads.dim_shop_ads_relevance_threshold__reg_s0_live` | 店铺广告相关性阈值维表，提供各地区的 `min`/`max` 相关性分数阈值，用于将 `final_relevance_score` 划分为相关/somewhat/不相关 |
| `mkplpaidads_brand_ads.shopads_popular_keyword` | 热门关键词维表，按天和地区维护热门搜索词列表，用于区分热门/非热门关键词相关性统计 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
   │  (placement in (3,2003,2030,20), 解析 ab_sign→exp_id EXPLODE)
   │
   ├──────────────────────────────────────────────────────────────────────────────┐
   │                                                                              │
   ▼                                                                              ▼
[CTE] shop_ads_exp_base_performance                              [CTE] shop_ads_trace_info
(按维度聚合流量漏斗、GMV、花费指标)                       (join ods_log_trace + dwd_tracking
                                                            获取 keyword、item、ab_sign)
   │                                                                              │
   │                                                         ┌────────────────────┤
   │                                                         │                    │
   │                                              热门关键词过滤              非热门关键词过滤
   │                                   (IN shopads_popular_keyword)  (NOT IN shopads_popular_keyword)
   │                                                         │                    │
   │                                                         ▼                    ▼
   │                                   [CTE] shop_ads_request_rele_score   [CTE] shop_ads_request_rele_score_non_popular_keyword
   │                                   (join dwd_performance, join 阈值维表)   (同左，关键词范围不同)
   │                                                         │                    │
   │                                                         ▼                    ▼
   │                                       [CTE] shop_ads_exp_revelance   [CTE] shop_ads_exp_revelance_non_popular_keyword
   │                                       (按维度汇总 relevant/somewhat/   (按维度汇总非热门关键词
   │                                        irrelevant 曝光计数)             相关性曝光计数)
   │                                                         │                    │
   └──────────────────────────────┬──────────────────────────┘                    │
                                  │     LEFT JOIN (on 全维度 key)                  │
                                  │◄──────────────────────────────────────────────┘
                                  │     LEFT JOIN (on 全维度 key)
                                  ▼
          ads_advertise_shop_ads_exp_performance_1d__reg_s0_live
              (partition: tz_type='local' / grass_region / grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|---|---|---|
| `shop_ads_exp_base_performance` | `dwd_advertise_performance_di__reg_s0_live` | 解析 `ab_sign` 展开 `exp_id`，按 7 个维度聚合流量漏斗、GMV、花费及 advv 指标 |
| `shop_ads_trace_info` | `ods_log_trace_shop_ads_hi__reg_s0_live` + `dwd_advertise_tracking_shop_hi__reg_s0_live` | 关联 trace 日志与 tracking 日志，获取每次广告请求对应的 keyword 及 item 相关性分数原始信息 |
| `shop_ads_request_rele_score` | `shop_ads_trace_info` + `dwd_advertise_performance_di__reg_s0_live` | 筛选**热门关键词**请求，关联 trace 与 performance，取 top-3 item 的 `final_relevance_score`，解析 `exp_id` |
| `shop_ads_exp_revelance` | `shop_ads_request_rele_score` + `dim_shop_ads_relevance_threshold__reg_s0_live` | 基于阈值维表将相关性分数分类，按维度汇总热门关键词下的相关/somewhat/不相关请求数 |
| `shop_ads_request_rele_score_non_popular_keyword` | `shop_ads_trace_info` + `dwd_advertise_performance_di__reg_s0_live` | 同 `shop_ads_request_rele_score`，但筛选**非热门关键词**请求 |
| `shop_ads_exp_revelance_non_popular_keyword` | `shop_ads_request_rele_score_non_popular_keyword` + `dim_shop_ads_relevance_threshold__reg_s0_live` | 基于阈值维表分类，按维度汇总非热门关键词下的相关性请求数 |

### 注意事项

1. **exp_id 展开导致的重复计数**：`ab_sign` 经 `split` 后 `EXPLODE` 展开，同一条广告曝光记录若参与多个实验则会出现在多行。因此，本表中的所有指标仅在**固定 `exp_id`** 的条件下聚合才具有业务意义；跨实验 ID 汇总将导致指标重复计算，严禁此类用法。

2. **相关性指标的过滤口径**：相关性统计仅包含同时满足以下三个条件的请求：① `impression_cnt > 0`；② `item_rank <= 3`（top-3 商品）；③ top-3 商品的 `irre_count + somewhat + relevant == 3`（恰好有 3 个有效评分）。该口径比 `impression_cnt` 更严格，计算相关率时**不能以 `impression_cnt` 作为分母**，应使用 `shop_relevant_impr_cnt + shop_somewhat_impr_cnt + shop_irrelevant_impr_cnt` 作为分母。

3. **advv 字段的计费类型分支**：`direct_advv_usd` 与 `broad_advv_usd` 的计算逻辑依赖 `pricing_type`：当 `pricing_type in (1, 2)`（CPC/CPM）时取广告花费（`expenditure_amt_usd`）；其他计费类型则用 GMV × `target_cir` 估算。此字段在不同 `pricing_type` 下语义不同，混合聚合需谨慎。

4. **时间窗口对齐**：trace 日志与 tracking 日志的过滤均使用本地时区转换后的 Unix 时间戳范围（`${timezone}` 参数），以保证与 `grass_date` 的本地日期对齐；各地区时区参数由调度系统注入，无需手工处理。

5. **写入方式**：使用 `INSERT OVERWRITE` 按天全量覆盖分区，同一分区重跑安全，但历史分区数据一旦覆盖即以最新调度结果为准。

---

*文档生成时间：2026-04-22*