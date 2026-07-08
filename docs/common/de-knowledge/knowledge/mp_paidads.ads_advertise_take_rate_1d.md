<!-- ads-workspace-gdoc-sync: gdoc_id=1fyQfZU8w1PRpf2ekcIrcIjjsuLeFyULM69htoUthlw8 gdoc_url=https://docs.google.com/document/d/1fyQfZU8w1PRpf2ekcIrcIjjsuLeFyULM69htoUthlw8/edit -->

# mp_paidads.ads_advertise_take_rate_1d

**分层**：ADS（应用数据服务层）
**主键**：`grass_region` + `grass_date` + `tz_type` + `entry_point` + `pricing_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是广告变现核心日报宽表，聚合各广告入口（Search、Daily Discover、You May Also Like、Livestream 等）及定价类型维度下的广告绩效指标（展示、点击、订单、GMV、收入）与平台大盘流量/GMV 指标，用于计算广告占比（Take Rate）、广告渗透率等关键经营指标。

主要使用场景包括：广告变现团队日常经营看板、广告收入归因分析、各入口流量与广告效率对比（广告展示渗透率 = `ads_imp / platform_imp`、广告 Take Rate = `ads_rev_usd / platform_gmv`）、以及各地区广告收入趋势监控。

表中同时存储广告侧指标（`ads_*` 字段）与平台大盘指标（`platform_*` 字段），两类指标口径不同，需结合具体分析场景分别使用，不可混合 SUM 后再比较。各地区按本地时区参数化调度，通常以 `tz_type = 'local'` 分区写入，保证日期口径统一。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型标识。当前写入值为 `'local'`（各地区按本地时区参数化调度）。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将全量扫描多个时区分区，导致数据重复或全表扫描 |
| `grass_region` | string | 国家/地区代码（大写），如 `'MY'`、`'TH'` 等。各地区独立调度写入 |
| `grass_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`。为主要时间分区键，每次查询必须指定 |

### 维度：主键与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `entry_point` | string | 广告入口点分类，如 `'Search'`、`'Daily Discover'`、`'You May Also Like'`、`'Livestream Streaming Room'`、`'Display'`、`'Shop'`、`'Game'` 等。由 ETL 中的多路映射逻辑（feature_mapping + omimi_mapping）派生，不能从原始日志直接获得。⚠️ 值 `'exclued'`（原始拼写）为被排除的流量，统计大盘时应过滤 |
| `pricing_type` | int | 广告定价类型编码（如 CPC、CPM、CPS 等）。ETL 中 `placement = 40` 时强制映射为 `11`；Display 广告固定为 `6`。⚠️ 同一 `entry_point` 下存在多个 `pricing_type` 行，聚合收入时需注意不要按 entry_point 单独 SUM 而漏掉分组 |

### 指标：广告流量与效果

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `entry_point_imp` | bigint | 平台大盘在该入口的自然展示次数（包含广告与非广告）。来自 `traffic.dwd_impression_hi__reg_live`，video 入口取自 `video_mart_dws_user_watch_basic_aggr_1d`。⚠️ 与 `ads_imp` 分母/分子关系用于计算广告渗透率，不可与 `platform_imp` 混用 |
| `entry_point_click` | bigint | 平台大盘在该入口的自然点击次数（包含广告与非广告）。来自 `traffic.dwd_click_hi__reg_live`。⚠️ 仅部分入口（Search、Daily Discover 等）有值，Game/Shop Game 入口使用 `ads_click` 填充 |
| `ads_imp` | bigint | 广告展示次数。来自 `mp_paidads.ods_log_ads_report_hi__reg_s0_live`，video 入口取 `is_item_ads=1` 的播放量 |
| `ads_click` | bigint | 广告点击次数。计算逻辑因 `pricing_type` 不同而有差异：`pricing_type in (9,10,14,19)` 使用 `raw_click`，`pricing_type = 20` 使用 `cps_dedup_click`，其余使用 `click`。⚠️ 为多逻辑合并值，跨 pricing_type 聚合时需确认口径一致性 |
| `ads_order` | bigint | 广告带来的订单量 |
| `ads_gmv_usd` | double | 广告归因的商品交易总额（USD）。原始金额除以汇率 `mp_order.dim_exchange_rate__reg_s0_live` 换算 |
| `raw_ads_rev_usd` | double | 广告原始收入（含税，USD）。为扣费日志汇总值，未做 VAT 税率剔除 |
| `ads_rev_usd` | double | 广告净收入（税后，USD）。计算方式：`ads_rev_usd = raw_ads_rev_usd / (1 + vat_rate)`，税率区分跨境店（`cb_tax`）与本地店（`local_tax`）。⚠️ 已为预计算派生值，跨行 SUM 合法，但若需重算税率口径须回溯 `raw_ads_rev_usd` 与 `regbida_keyreports.dim_vat_rate` |

### 指标：平台大盘 GMV 与流量

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `platform_imp` | bigint | 平台全量大盘展示次数（不含 `'exclued'` 入口），为全平台汇总值。⚠️ 该字段在每行均冗余存储同一地区同一日期的汇总值，直接按 `entry_point` / `pricing_type` SUM 会导致严重重复计算，需先 `GROUP BY grass_region, grass_date` 取单值后再使用 |
| `platform_gmv` | double | 平台大盘 GMV（USD）。计算口径：`buyer_paid_shipping_fee + merchandise_subtotal_amt + tax_payable + insurance_subtotal_amt + buyer_txn_fee + buyer_service_fee - promotion_fees`，包含测试订单。⚠️ 同 `platform_imp`，全行冗余存储，不可直接 SUM |
| `platform_gmv_excl_testorder` | double | 平台大盘 GMV（USD），排除测试订单（`is_bi_excluded = 0`）。⚠️ 同 `platform_imp`，全行冗余存储，不可直接 SUM |
| `platform_nmv` | double | 平台大盘净商品价值 NMV（USD），反映平台整体收入健康度。⚠️ 同 `platform_imp`，全行冗余存储，不可直接 SUM |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下分区条件，否则将触发全表扫描，造成性能问题或数据重复：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区，数据重复 |
| `grass_region` | `grass_region = 'MY'`（按需指定） | 全地区扫描，数据量剧增 |
| `grass_date` | `grass_date = '2025-01-01'` 或区间 | 全量历史扫描，严重影响性能 |

示例：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2025-01-01'
```

此外，计算平台大盘指标（`platform_imp`/`platform_gmv` 等）时，建议额外过滤 `entry_point != 'exclued'`，并注意这些字段的去重逻辑（见下节）。

### 不可直接 SUM 的字段

| 字段 | 问题描述 | 正确用法 |
|------|----------|----------|
| `platform_imp` | 每个 `(entry_point, pricing_type)` 行均冗余存储同一地区同日的全平台汇总值，直接 SUM 会成倍放大 | 先按 `(grass_region, grass_date, tz_type)` 取一行（如 `MAX` 或子查询去重），再使用 |
| `platform_gmv` | 同上 | 同上 |
| `platform_gmv_excl_testorder` | 同上 | 同上 |
| `platform_nmv` | 同上 | 同上 |
| `ads_rev_usd` | 已完成 VAT 税后计算，跨 pricing_type SUM 合法，但不可与 `raw_ads_rev_usd` 混加 | 直接按业务维度 SUM，勿与 raw 字段相加 |
| `ads_click` | 不同 `pricing_type` 使用不同点击计数口径（raw_click / cps_dedup_click / click），跨 pricing_type 聚合需谨慎 | 明确 pricing_type 范围后再聚合，或按业务定义选取特定 pricing_type |

**Take Rate 计算示例**（正确写法）：
```sql
-- 广告 Take Rate = 广告净收入 / 平台 GMV
WITH base AS (
  SELECT
    grass_region, grass_date,
    SUM(ads_rev_usd) AS total_ads_rev_usd,
    MAX(platform_gmv_excl_testorder) AS platform_gmv_excl_testorder  -- 取单值，避免重复
  FROM mp_paidads.ads_advertise_take_rate_1d
  WHERE tz_type = 'local'
    AND grass_region = 'MY'
    AND grass_date = '2025-01-01'
  GROUP BY grass_region, grass_date
)
SELECT total_ads_rev_usd / NULLIF(platform_gmv_excl_testorder, 0) AS take_rate
FROM base;
```

### 时效性说明

本表为 T+1 日更新，每日调度生成前一自然日（本地时区）数据。使用时取 `grass_date = CURRENT_DATE - 1` 作为最新数据分区；若需确认数据是否已就绪，可检查对应分区是否存在。ETL 中广告日志过滤条件同时使用 `grass_date` 和 `timestamp` 双重限定，以确保本地时区日期准确性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `traffic.dwd_impression_hi__reg_live` | 平台大盘展示日志，用于计算各入口 `entry_point_imp` 及 `platform_imp` |
| `traffic.dwd_click_hi__reg_live` | 平台大盘点击日志，用于计算各入口 `entry_point_click` |
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 广告投放报告日志，提供广告展示、点击、GMV、订单等核心绩效数据 |
| `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` | 广告主扣费明细，提供广告实际收入（`ads_rev_usd`、`raw_ads_rev_usd`）数据 |
| `mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live` | Display 广告收入数据，补充品牌展示广告的指标 |
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | 广告事务日志，用于识别视频广告 sub_entrance（310103） |
| `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 订单明细，提供平台大盘 GMV/NMV 数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，将广告 GMV 换算为 USD |
| `mp_foa.dim_search_domain_map__reg_live` | 搜索场景映射维表，将 `scenario_key` 映射为 `mapped_page_type` |
| `mp_foa.dim_feature_map__reg_s0_live` | 功能特征映射维表，将 `feature_detail` 映射为 `feature_group` 和 `feature` |
| `traffic_omni_oa.dim_atlas_feature_business_details_map__reg_live` | Atlas 业务线映射维表，用于识别 Daily Discover 等业务线流量 |
| `mp_paidads.dim_entry_point_mapping` | 广告入口映射维表，将 `entrance`/`sub_entrance` 映射为 `entry_point` 标签 |
| `regbida_keyreports.dim_vat_rate` | VAT 税率维表，区分跨境店与本地店税率，用于计算税后净收入 |
| `mp_user.dim_shop__reg_s0_live` | 店铺维表，提供 `is_cb_shop`（跨境店标识）用于选取税率 |
| `video.video_mart_dws_user_watch_basic_aggr_1d` | 视频播放聚合表，提供视频入口的展示量及广告展示量 |

---

## ETL 逻辑摘要

### 数据流

```
traffic.dwd_impression_hi__reg_live ─────────────────┐
traffic.dwd_click_hi__reg_live ───────────────────────┤
mp_foa.dim_search_domain_map__reg_live ───────────────┤──► [bi_imp / bi_click]
mp_foa.dim_feature_map__reg_s0_live ─────────────────┤       (平台入口展示/点击)
traffic_omni_oa.dim_atlas_feature_business_details ──┘
                                                          │
                                                          ▼
                                                    [platform_imp]
                                                    [entry_point_imp]
                                                    [entry_point_click]

mp_paidads.ods_log_ads_report_hi__reg_s0_live ───────┐
mp_order.dim_exchange_rate__reg_s0_live ──────────────┤──► [performance_di]
                                                          │       (广告展示/点击/GMV)
mp_paidads.dwd_advertiser_deduction_di__reg_s0_live ─┐   │
mp_paidads.ods_log_translog_event_hi__reg_s0_live ───┤──► [deduction_amt]
                                                      │       (广告收入)
                                                      │
                                          [performance_di] + [deduction_amt]
                                                      │
                                                      ▼
                                              [ads_revenue]
                                                      │
                                   + mp_paidads.dim_entry_point_mapping
                                                      │
                                                      ▼
                                          [ads_revenue_entry_point]
                                                      │
                               + mp_user.dim_shop + regbida_keyreports.dim_vat_rate
                                                      │
                                                      ▼
                                                [ads_vat]
                                                      │
mp_paidads.dws_advertise_display_ads_revenue ─────────┤
                                                      ▼
                                              [ads_metrics]  ←── UNION ALL display
                                                      │
                          ┌───────────────────────────┼───────────────────────────┐
                          ▼                           ▼                           ▼
                   [entry_point_imp]           [entry_point_click]           [platform_gmv]
                          │                           │         (mp_order.dwd_order_item...)
                          └───────────────────────────┘
                                                      │
                    video.video_mart_dws_user_watch ──┤
                                                      ▼
                              INSERT OVERWRITE ads_advertise_take_rate_1d
                              (partition: tz_type='local' / grass_region / grass_date)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|---------------|--------|------|
| `page_mapping` | `mp_foa.dim_search_domain_map__reg_live` | 将搜索 `scenario_key` 映射为 `mapped_page_type`，取最新分区 |
| `feature_mapping` | `mp_foa.dim_feature_map__reg_s0_live` | 将 `feature_detail` 映射为 `feature_group` / `feature`，用于入口分类 |
| `omimi_mapping` / `omimi_mapping_1` | `traffic_omni_oa.dim_atlas_feature_business_details_map__reg_live` | Atlas 业务线与模块映射，用于识别 Daily Discover、Homepage 等，分 page_section 精确/宽松两档 |
| `bi_imp` | `traffic.dwd_impression_hi__reg_live` + 维表 | 全平台各入口展示量（Cached），含复杂入口分类 CASE WHEN 逻辑 |
| `bi_click` | `traffic.dwd_click_hi__reg_live` + 维表 | 全平台各入口点击量（Cached），逻辑与 `bi_imp` 对称 |
| `platform_imp` | `bi_imp` | 汇总全平台展示量（排除 `'exclued'` 入口） |
| `platform_gmv` | `mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live` | 计算平台 GMV、NMV 及排除测试订单的 GMV |
| `performance_di` | `mp_paidads.ods_log_ads_report_hi__reg_s0_live` + 汇率表 | 广告曝光、点击、GMV、订单绩效，含 placement→pricing_type 映射 |
| `deduction_di` / `deduction_amt` | `mp_paidads.dwd_advertiser_deduction_di__reg_s0_live` + `video_sub_entrance` | 广告扣费金额，关联视频 sub_entrance 以正确归因视频广告收入 |
| `ads_revenue` | `performance_di` FULL JOIN `deduction_amt` | 合并绩效与收入，以 FULL OUTER JOIN 防止数据丢失 |
| `ads_revenue_entry_point` | `ads_revenue` + `dim_entry_point_mapping` | 将 entrance/sub_entrance 映射为业务入口标签 `entry_point` |
| `ads_vat` | `ads_revenue_entry_point` + `dim_shop` + `dim_vat_rate` | 按跨境/本地店税率扣税，产出 `ads_rev_usd`（税后）和 `raw_ads_rev_usd`（税前） |
| `display_ads_metrics` | `mp_paidads.dws_advertise_display_ads_revenue__reg_s0_live` | Display 品牌广告指标，`pricing_type` 固定为 6，费用单位为 USD/1000 |
| `ads_metrics` | `ads_vat` UNION ALL `display_ads_metrics` | 合并搜索/推荐广告与 Display 广告的全量指标 |
| `entry_point_imp` | `bi_imp` + `ads_metrics` | 分入口展示量，Game/Shop Game 入口以广告展示量替代 |
| `entry_point_click` | `bi_click` + `ads_metrics` | 分入口点击量，Game/Shop Game 入口以广告点击量替代 |
| `video_vv` | `video.video_mart_dws_user_watch_basic_aggr_1d` | 视频入口播放量及视频广告展示量 |
| `video_sub_entrance` | `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | 识别视频广告 sub_entrance=310103，用于收入归因 |
| `sub_entrance_mapping` / `entrance_mapping` | `mp_paidads.dim_entry_point_mapping` | 两级入口映射：优先匹配 sub_entrance，其次匹配 entrance |
| `tax` | `regbida_keyreports.dim_vat_rate` | 按地区获取跨境店和本地店 VAT 税率，取最新分区 |
| `dim_shop` | `mp_user.dim_shop__reg_s0_live` | 获取店铺类型（跨境/官方/托管），用于选择税率 |

### 注意事项

1. **`platform_*` 字段全行冗余**：`platform_imp`、`platform_gmv`、`platform_gmv_excl_testorder`、`platform_nmv` 是地区+日期级别的汇总值，在每条 `(entry_point, pricing_type)` 记录中均以相同值重复存储。查询时**必须先按 `(grass_region, grass_date)` 聚合取单值**（如 `MAX()` 或子查询），再进行跨表计算，直接对明细行 SUM 会产生成倍错误。

2. **广告日志双重时间过滤**：`performance_di` 和 `deduction_di` 均使用 `grass_date` 分区范围（当日和次日）+ `timestamp` 转换后再过滤，目的是应对日志跨天写入问题，确保本地时区日期准确归属。

3. **placement 到 pricing_type 的映射**：`placement = 40` 统一映射为 `pricing_type = 11`；`placement = 9` 被全局排除（广告主测试流量）。

4. **FULL OUTER JOIN 设计**：`ads_revenue` 使用 FULL OUTER JOIN 合并绩效与扣费数据，以保证仅有绩效、仅有扣费或两者都有的广告均被覆盖。最终写入时 `ads_metrics` 与 `entry_point_imp` 也使用 FULL OUTER JOIN，防止某入口仅有流量无广告（或反之）时丢失记录。

5. **入口分类中的 `'exclued'` 值**：ETL 中拼写为 `'exclued'`（非 `'excluded'`），为系统既有值，业务统计时应过滤此值。`platform_imp` 的计算已在 `platform_imp` CTE 中排除，但写入最终表的明细行仍可能包含该值。

6. **Display 广告费用单位**：`dws_advertise_display_ads_revenue` 中 `expense_amt_usd` 单位为"千分之一 USD"，ETL 中已除以 1000.0 换算，最终写入值已为标准 USD，无需再次换算。

7. **维表取最新分区**：`page_mapping`、`feature_mapping`、`tax` 均通过子查询 `max(grass_date)` 取最新分区数据，而非固定日期，可能引入维表更新时的微小口径变化。

---

*文档生成时间：2026-04-22*