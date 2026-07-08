<!-- ads-workspace-gdoc-sync: gdoc_id=1EpOG4Z8irP4OQXFos7VWzv1mBNR0pCK-i2r29xkEh_Q gdoc_url=https://docs.google.com/document/d/1EpOG4Z8irP4OQXFos7VWzv1mBNR0pCK-i2r29xkEh_Q/edit -->

# mp_paidads.dws_advertiser_balance_td

**分层：** DWS（数据汇总层）
**主键：** `shop_id` + `grass_region` + `grass_date` + `tz_type`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（T+1）
**引用频次：** 1 次（候选表范围内）

---

## 业务描述

本表记录各广告主（店铺维度）截至当日的广告账户余额快照，是付费广告平台（PaidAds）余额监控与风控分析的核心汇总表。表中将广告余额按信用类型（付费信用 / 免费信用）、是否带过期时间、以及广告活动类型（ROI2 / 直播 / 搜索品牌）进行多维度拆分，同时提供当地货币与 USD 双币种口径，满足跨地区统一分析需求。

本表的典型使用场景包括：广告主余额健康度监控（如余额预警）、各类信用余额结构分析（付费 vs 免费、带期 vs 不带期）、账户开始余额与结束余额差异对比（消耗推算）、以及不同广告活动类型的资金使用分布分析。

各地区按本地时区参数化调度，`td` 后缀字段均为截至当日（Till Date）的快照值，每日全量覆盖写入（INSERT OVERWRITE），反映当日结束时点的账户余额状态。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区。固定值为 `'local'`（按各地区本地时区调度），查询时必须指定，否则将触发全表扫描 |
| `grass_region` | string | 地区编码（大写），如 `'MX'`、`'TH'` 等，各地区参数化调度覆盖，查询时建议指定 |
| `grass_date` | date | 数据日期（本地日期），即余额快照所属日期，查询时必须指定具体日期 |

---

### 维度：主键与广告主属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主唯一标识，与 `grass_region` + `grass_date` + `tz_type` 共同构成主键 |

---

### 指标：付费信用余额（当地货币 & USD）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `paid_credit_w_expiry_eod_balance_amt_td` | double | 付费且带过期时间的当日结束余额，单位：当地货币 |
| `paid_credit_w_expiry_eod_balance_amt_usd_td` | double | 付费且带过期时间的当日结束余额，单位：USD。⚠️ 由 `paid_credit_w_expiry_eod_balance_amt_td / exchange_rate` 派生，多行 SUM 后汇率基准不统一，不可直接 SUM，需用本地货币字段除以对应汇率重新计算 |
| `paid_credit_wo_expiry_eod_balance_amt_td` | double | 付费且不带过期时间的当日结束余额，单位：当地货币 |
| `paid_credit_wo_expiry_eod_balance_amt_usd_td` | double | 付费且不带过期时间的当日结束余额，单位：USD。⚠️ 由本地货币字段派生，不可直接 SUM，原因同上 |
| `paid_credit_wo_expiry_sod_balance_amt_td` | double | 付费且不带过期时间的当日**开始**余额（SOD），单位：当地货币。⚠️ 与 EOD 字段口径不同，两者差值可用于推算当日消耗；不可与 EOD 字段混加 |
| `paid_credit_wo_expiry_sod_balance_amt_usd_td` | double | 付费且不带过期时间的当日开始余额（SOD），单位：当地货币（字段 comment 标注为当地货币，实际由本地字段除以汇率派生，含义为 USD）。⚠️ 由本地货币字段派生，不可直接 SUM；注意 comment 中货币单位标注可能有误，请以 `_usd_` 命名为准判断币种 |

---

### 指标：免费信用余额（当地货币 & USD）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `free_credit_w_expiry_eod_balance_amt_td` | double | 免费且带过期时间的当日结束余额，单位：当地货币。⚠️ 已含混合充值（package/voucher topup）中归属免费信用部分的拆分调整量，口径较复杂，不等于原始信用流水简单汇总 |
| `free_credit_w_expiry_eod_balance_amt_usd_td` | double | 免费且带过期时间的当日结束余额，单位：USD。⚠️ 由本地货币字段除以汇率派生，不可直接 SUM |
| `free_credit_wo_expiry_eod_balance_amt_td` | double | 免费且不带过期时间的当日结束余额，单位：当地货币。⚠️ 同样含混合充值拆分调整量 |
| `free_credit_wo_expiry_eod_balance_amt_usd_td` | double | 免费且不带过期时间的当日结束余额，单位：USD。⚠️ 由本地货币字段除以汇率派生，不可直接 SUM |

---

### 指标：总余额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `total_eod_balance_td` | double | 当日结束总余额，单位：当地货币。为四类信用（付费带期、付费不带期、免费带期、免费不带期）及混合充值调整量的加总，是账户余额的综合口径 |
| `total_eod_balance_usd_td` | double | 当日结束总余额，单位：USD。⚠️ 由 `total_eod_balance_td / exchange_rate` 派生，不可直接 SUM，跨地区汇总需用本地货币字段除以各自汇率后再聚合 |

---

### 指标：按广告活动类型分类的余额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi2_eod_balance_amt_td` | double | ROI2 广告活动当日结束余额，单位：当地货币。对应 `effective_type = 1` 的信用记录 |
| `roi2_eod_balance_amt_usd_td` | double | ROI2 广告活动当日结束余额，单位：USD。⚠️ 由本地货币字段除以汇率派生，不可直接 SUM |
| `livestream_eod_balance_amt_td` | double | 直播广告活动当日结束余额，单位：当地货币。对应 `effective_type = 2` 的信用记录 |
| `livestream_eod_balance_usd_amt_td` | double | 直播广告活动当日结束余额，单位：USD。⚠️ 由本地货币字段除以汇率派生，不可直接 SUM |
| `search_brand_eod_balance_amt_td` | double | 搜索品牌广告活动当日结束余额，单位：当地货币。对应 `effective_type = 3` 的信用记录 |
| `search_brand_eod_balance_usd_amt_td` | double | 搜索品牌广告活动当日结束余额，单位：USD。⚠️ 由本地货币字段除以汇率派生，不可直接 SUM |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下分区过滤条件，否则将触发全分区扫描，导致查询性能极差、产生高额计算成本：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 本表当前仅写入 `'local'` 分区，不指定则全扫 |
| `grass_date` | `grass_date = '2024-01-01'` | 必须指定具体日期，td 类快照表每日一份，不加日期过滤将读取全量历史 |
| `grass_region` | `grass_region = 'TH'` | 建议指定，避免跨地区全扫；跨地区汇总时至少列举明确地区列表 |

### 不可直接 SUM 的字段

以下所有 `_usd_` 字段均由 **本地货币字段 ÷ 当日汇率** 派生计算而来，多行直接 `SUM` 会导致跨地区、跨汇率的错误汇总：

- `free_credit_w_expiry_eod_balance_amt_usd_td`
- `free_credit_wo_expiry_eod_balance_amt_usd_td`
- `paid_credit_w_expiry_eod_balance_amt_usd_td`
- `paid_credit_wo_expiry_eod_balance_amt_usd_td`
- `paid_credit_wo_expiry_sod_balance_amt_usd_td`
- `total_eod_balance_usd_td`
- `roi2_eod_balance_amt_usd_td`
- `livestream_eod_balance_usd_amt_td`
- `search_brand_eod_balance_usd_amt_td`

**正确做法**：先对本地货币字段进行 SUM，再 JOIN `mp_order.dim_exchange_rate__reg_s0_live` 获取汇率，统一换算为 USD。

此外，`paid_credit_wo_expiry_sod_balance_amt_td`（当日开始余额）与各 EOD 字段（当日结束余额）**不可混合相加**，两者语义不同，差值才有业务意义（反映当日余额消耗）。

### 时效性说明

- 本表为 `td`（Till Date）快照表，每日全量覆盖（INSERT OVERWRITE）。查询特定日期数据时，指定 `grass_date = '<目标日期>'` 即可获取该日结束时点的余额快照。
- 由于调度为 T+1 执行，当日最新数据通常在次日早间产出，使用前请确认目标分区已就绪，避免读到上一日数据。
- 各地区按本地时区调度，不同地区的 `grass_date` 分区产出时间存在时差，跨地区对比时请注意数据就绪时间一致性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live` | 广告主信用明细流水，提供每笔信用记录的余额（SOD/EOD）、信用类型、过期时间、订单信息等核心字段 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，提供 `user_id` → `shop_id` 的映射关系 |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主充值明细宽表，提供套餐/优惠券充值的金额拆分信息，用于区分混合充值中的付费信用与免费信用部分 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日汇率，用于本地货币→USD 的换算 |

---

## ETL 逻辑摘要

### 数据流

```
mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live   (信用明细流水，按 grass_region/dt 过滤)
        │
        │  LEFT JOIN (user_id + grass_region)
        ▼
mp_paidads.dim_advertiser__reg_s0_live                   (广告主维表，获取 shop_id)
        │
        │  LEFT JOIN (order_id + shop_id + order_type + grass_region + main_type)
        ▼
mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live   (充值明细，获取套餐/优惠券金额拆分)
        │
        └──► [end_balance_view] 临时视图（shop_id 粒度明细，含混合充值标记）
                        │
                        │  GROUP BY shop_id + grass_region
                        │  多路 CASE WHEN 拆分信用类型及 effective_type
                        ▼
                 [内层聚合子查询]  (各类信用 EOD/SOD 余额汇总，单位：原始值 / 100000.0)
                        │
                        │  LEFT JOIN (BROADCAST, grass_region)
                        ▼
        mp_order.dim_exchange_rate__reg_s0_live           (汇率维表)
                        │
                        │  本地货币 ÷ exchange_rate → USD 字段派生
                        ▼
        mp_paidads.dws_advertiser_balance_td__reg_s0_live
        (INSERT OVERWRITE PARTITION tz_type='local' / grass_region / grass_date)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `end_balance_view` | `dwd_advertiser_credit_di` + `dim_advertiser` + `dwd_advertiser_credit_topup_df` | 将信用明细流水与广告主维表、充值明细三表关联，补全 `shop_id`、充值类型标记（`is_package_topup`、`is_voucher_topup`）及充值金额，形成带完整上下文的明细视图，供后续聚合使用 |
| 内层聚合子查询（匿名） | `end_balance_view` | 按 `shop_id + grass_region` 分组，通过多路 `CASE WHEN` 逻辑拆分各类信用余额，并处理混合充值（package/voucher topup）中付费与免费信用的归属，将原始整数余额除以 `100000.0` 还原为实际金额 |

### 注意事项

1. **金额单位缩放**：上游 `dwd_advertiser_credit_di` 中余额字段以整数存储（×100000），ETL 中统一除以 `100000.0` 还原为实际货币金额，下游直接使用本表字段无需再做换算。

2. **混合充值拆分逻辑**：当一笔充值同时包含付费信用和免费信用时（套餐充值 `is_package_topup=1` 或优惠券充值 `is_voucher_topup=1`），ETL 通过复杂 `CASE WHEN` 逻辑将余额拆分至 `mixed_free_credit_w/wo_expiry_to_add` 和 `mixed_paid_credit_w_expiry_to_add` 中间变量，再合并至各信用类型字段。因此，`free_credit_*` 和 `paid_credit_*` 字段并非原始信用流水的简单过滤汇总，而是经过混合充值归因处理后的结果。

3. **USD 字段口径一致性**：所有 `_usd_td` 字段均由同一日期同一地区的 `exchange_rate` 换算，跨地区聚合时请勿直接相加，需分别使用本地货币字段统一换算。

4. **`paid_credit_wo_expiry_sod_balance_amt_usd_td` 字段 comment 疑似有误**：该字段的原始 comment 标注货币单位为"当地货币"，但字段命名含 `_usd_`，且 ETL SQL 中该字段为 `paid_credit_wo_expiry_sod_balance_amt_td / exchange_rate`，实际为 USD 口径，以字段名为准。

5. **有效类型（effective_type）覆盖**：`roi2_eod_balance_amt_td`（effective_type=1）、`livestream_eod_balance_amt_td`（effective_type=2）、`search_brand_eod_balance_amt_td`（effective_type=3）三类余额之和不一定等于 `total_eod_balance_td`，因为 `total_eod_balance_td` 是按信用类型（main_type + expiry 维度）汇总的，两种维度分类方式相互独立。

6. **全量覆盖写入**：采用 `INSERT OVERWRITE` 按分区覆盖，每日重跑安全，无累计叠加问题，但历史分区一旦被覆盖则不可追溯，如需历史快照需依赖外部归档。

---

*文档生成时间：2026-04-22*