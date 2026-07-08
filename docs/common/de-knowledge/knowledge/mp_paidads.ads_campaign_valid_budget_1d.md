<!-- ads-workspace-gdoc-sync: gdoc_id=11JuOH3gSsg3fCqn6wEodRZ55EU0BbX-qyV2lfMKNm5c gdoc_url=https://docs.google.com/document/d/11JuOH3gSsg3fCqn6wEodRZ55EU0BbX-qyV2lfMKNm5c/edit -->

# mp_paidads.ads_campaign_valid_budget_1d

**分层：** ADS（应用数据服务层）
**主键：** `campaign_id`（+ `tz_type` + `grass_region` + `grass_date`）
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日一次（T+1 调度，各地区按本地时区参数化调度）
**引用频次：** 30 次（候选表范围内）

---

## 业务描述

本表是付费广告（Paid Ads）体系中的**广告活动（Campaign）有效预算日汇总表**，每日产出各地区所有活跃 Campaign 的有效预算快照。其核心目标是将广告主的账户余额、当日消耗、设置预算等多维信息综合计算，得出每个 Campaign 在账户余额约束下的**实际可用有效预算**（`campaign_valid_budget_usd`）以及账户层面的有效预算（`account_valid_budget_usd`），为后续 ROI 分析、预算健康度监控、投放策略优化等场景提供标准化、可信赖的数据基础。

本表特别针对**直播广告（Live Ads）**额外引入了策略级有效预算字段（`campaign_strategy_valid_budget_usd`），结合配额分割（quota_split）和系统默认上限（default_cap）进行精细化计算，满足直播广告差异化的预算管控需求。当账户下多个 Campaign 的有效预算之和超过账户可用余额时，ETL 会触发迭代式预算分摊算法，确保各 Campaign 的有效预算总额与账户实际可用额精准对齐。

下游主要使用场景包括：①广告主账户健康度与充值/到期监控；②Campaign 粒度的预算利用率分析；③ROI 模型训练与归因；④运营看板与大盘预算报告。本表被下游候选表引用 **30 次**，是付费广告数据体系中的高频核心宽表。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型。ETL 当前仅写入 `local`（本地时区）分区，查询时**必须指定** `tz_type = 'local'` |
| `grass_region` | string | 地区编码（如 `MY`、`TH`、`VN` 等），各地区独立调度写入 |
| `grass_date` | date | 数据业务日期（本地时区），分区键，格式 `yyyy-MM-dd` |

---

### 维度：主键与广告活动属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `campaign_id` | bigint | 广告活动唯一标识，本表主键 |
| `shop_id` | bigint | 广告主店铺 ID |
| `campaign_status` | tinyint | 广告活动状态枚举值（详见系统 Enumeration 文档，如 1=启用）|
| `has_ads_active` | tinyint | 该 Campaign 下是否有活跃广告位（1=是，0=否），取来源表 `is_ads_active` 的 MAX 值 |
| `campaign_start_datetime` | string | Campaign 开始时间（字符串格式，源自 `mp_paidads.ads_advertise_mkt_1d`）|
| `campaign_end_datetime` | string | Campaign 结束时间（字符串格式）。ETL 过滤条件：仅保留 `campaign_end_datetime >= grass_date` 的记录，即当日仍有效的 Campaign ⚠️ 存储为字符串，日期比较需显式转换 `date(campaign_end_datetime)` |
| `pricing_type` | int | 计费类型枚举值，取 Campaign 下广告位的 MAX 值。Live Ads 对应 `pricing_type IN (9, 10, 14, 19)` |
| `main_product_type` | string | 广告主产品主类型 |
| `product_type` | string | 广告产品类型 |
| `sub_product_type` | string | 广告产品子类型 |

---

### 维度：广告主与卖家属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `advertiser_tier` | string | 广告主分级（Tier），来源于广告主维表 ⚠️ 当前 DDL 有此字段但 ETL SQL 未见显式赋值，可能为空或由分区表默认填充，使用前建议验证非空率 |
| `seller_tier` | string | 卖家分级 |
| `seller_type` | string | 卖家类型（如本地卖家、跨境卖家等）|
| `seller_type_1p` | string | 1P（自营）卖家类型标识 |
| `is_cb_seller` | tinyint | 是否跨境卖家（1=是，0=否）|
| `is_cb_sip_affiliated` | tinyint | 是否关联跨境 SIP（Shopee International Platform）|
| `is_local_sip_affiliated` | tinyint | 是否关联本地 SIP |
| `is_auto_topup_enabled` | tinyint | 广告主账户是否开启自动充值（取自 `mp_paidads.dim_advertiser`）|
| `shop_level0_global_be_category` | string | 店铺一级全球后端类目 |
| `shop_level1_global_be_category` | string | 店铺二级全球后端类目 |

---

### 指标：Campaign 预算与消耗

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `budget_usd` | double | Campaign 日预算（USD）。计算逻辑：若 `campaign_daily_quota_usd > 0` 取日预算；若日预算为 0 且总预算 > 0 且有结束时间，则按总预算÷投放天数摊算；否则取 9999999999（无限制）⚠️ 该字段为派生计算值，不等同于后台配置的原始日预算字段，不可与原始预算字段直接比较 |
| `campaign_total_budget_usd` | double | Campaign 总预算（USD），0 表示"不限"⚠️ 0 不代表没有预算，而是"无上限"，过滤时需注意 |
| `ads_expenditure_usd` | double | 当日 Campaign 级广告消耗汇总（USD），来源于 `ads_advertise_mkt_1d` |
| `campaign_valid_budget_usd` | double | **Campaign 级有效预算（USD）**，核心指标。计算逻辑：`GREATEST(LEAST(ads_expenditure_usd + account_balance_usd, budget_usd), ads_expenditure_usd)`，当账户余额不足时会触发迭代分摊算法重新计算 ⚠️ 为复杂派生指标，不可直接 SUM 跨 Campaign 得到账户有效预算，应使用 `account_valid_budget_usd` |
| `campaign_strategy_valid_budget_usd` | double | **Campaign 策略级有效预算（USD）**，仅 Live Ads 有意义。计算逻辑：`GREATEST(ads_expenditure_usd, IF(sys_budget_usd > 0, LEAST(sys_budget_usd, campaign_valid_budget_usd), campaign_valid_budget_usd))`，其中 `sys_budget_usd` 来自 `dim_campaign` 的 `quota_splits.daily_available_quota`（Live Ads 无日预算时取 `default_cap_usd`）⚠️ 非 Live Ads Campaign 此字段等于 `campaign_valid_budget_usd`，使用前需结合 `pricing_type` 判断 |

---

### 指标：账户余额与资金流水

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `account_balance_usd` | double | 当日日终账户余额（USD），取自 `dws_advertiser_balance_td` 的 `total_eod_balance_usd_td` |
| `account_balance_last1d_usd` | double | 前一日日终账户余额（USD），取自 `dws_advertiser_balance_td` 的前一天分区 |
| `account_expenditure_usd` | double | 广告主账户维度的当日总消耗（USD），为该账户下所有 Campaign 的 `ads_expenditure_usd` 之和 ⚠️ 为账户级聚合值，同一 shop_id 下所有 Campaign 行该字段值相同，对 Campaign 维度分析时请勿再次 SUM |
| `account_valid_budget_usd` | double | **账户级有效预算（USD）**，核心指标。计算逻辑：`GREATEST(LEAST(account_available_fees, agg_campaign_valid_budget), account_expenditure_usd)`，其中 `account_available_fees = account_expenditure_usd + account_balance_usd` ⚠️ 同一 shop_id 下所有 Campaign 行该字段值相同，统计账户数时需 `GROUP BY shop_id` 后取 MAX 或 ANY，不可直接 SUM |
| `topup_amt_usd` | double | 当日账户充值金额（USD），取自 `dwd_advertiser_credit_topup_df`，按充值创建日期过滤 ⚠️ 同一 shop_id 下所有 Campaign 行该字段值相同，统计账户充值时需去重 |
| `expired_amt_usd` | double | 当日账户信用额度到期金额（USD），按 `credit_topup_expiry_end_datetime = grass_date` 过滤 ⚠️ 同一 shop_id 下所有 Campaign 行该字段值相同，统计时需去重 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区过滤，避免全表扫描导致查询超时或资源浪费：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | ETL 仅写入 `local` 分区，不加过滤等同于无效扫描，且可能与其他系统时区数据混用导致重复计数 |
| `grass_region` | `grass_region = 'XX'`（按业务需求指定） | 触发全地区扫描，数据量翻倍，且各地区日期语义不同（本地时区）|
| `grass_date` | `grass_date = '2024-01-01'` 或范围过滤 | 触发全量历史扫描，严重影响查询性能 |

**示例：**
```sql
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2024-01-01'
```

---

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确计算方式 |
|------|------|-------------|
| `campaign_valid_budget_usd` | 各 Campaign 行独立计算，SUM 不等于账户有效预算 | 账户有效预算请使用 `account_valid_budget_usd`（取 shop_id 维度的 MAX 或 DISTINCT 值）|
| `account_valid_budget_usd` | 同一 shop_id 下所有 Campaign 行值相同，直接 SUM 会 N 倍重复计数 | `SELECT shop_id, MAX(account_valid_budget_usd) FROM ... GROUP BY shop_id` |
| `account_expenditure_usd` | 同一 shop_id 下所有 Campaign 行值相同，直接 SUM 会 N 倍重复计数 | 同上，按 shop_id 去重后取值 |
| `topup_amt_usd` | 同一 shop_id 下所有 Campaign 行值相同，直接 SUM 会 N 倍重复计数 | 按 shop_id 去重后聚合 |
| `expired_amt_usd` | 同上 | 按 shop_id 去重后聚合 |
| `account_balance_usd` | 同上 | 按 shop_id 去重后聚合 |
| `account_balance_last1d_usd` | 同上 | 按 shop_id 去重后聚合 |
| `budget_usd` | 派生计算值（日预算/摊算/9999999999），不代表后台原始配置 | 仅用于有效预算比较场景，不作为"广告主设置的预算"对外展示 |
| `campaign_strategy_valid_budget_usd` | 非 Live Ads 时含义与 `campaign_valid_budget_usd` 相同，混用会误导分析 | 使用前需 `pricing_type IN (9,10,14,19)` 过滤 Live Ads |

---

### 时效性说明

- 本表为 **T+1** 更新，`grass_date` 分区对应**前一自然日**（本地时区）的业务数据。
- `account_balance_usd` 为**日终余额**（EOD），反映当日结束时刻的余额，不代表日中实时余额。
- `account_balance_last1d_usd` 为前一日日终余额，两字段对比可推算当日余额变动：`account_balance_usd - account_balance_last1d_usd + account_expenditure_usd ≈ topup_amt_usd - expired_amt_usd`（受到期/系统调整影响，可能存在小额差异）。
- 查询最新数据应取**最近已落盘的 `grass_date`** 分区，避免查询当天分区（数据可能尚未产出）。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 提供 Campaign 基础信息、广告消耗、预算配置、卖家属性、产品类型等核心字段；作为主驱动表 |
| `mp_paidads.dim_campaign__reg_s0_live` | 提供 Live Ads Campaign 的配额分割明细（`quota_splits.daily_available_quota`），用于计算 `sys_budget_usd` |
| `mp_order.dim_exchange_rate__reg_s0_live` | 提供各地区汇率，将本地货币预算/配额转换为 USD |
| `mp_paidads.dim_live_ads_default_cap__reg_s0_live` | 提供 Live Ads 无日预算时的系统默认消耗上限（`default_cap`）|
| `mp_paidads.dim_advertiser__reg_s0_live` | 提供广告主维度属性，包括 `is_auto_topup_enabled` |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 提供账户充值记录，用于计算 `topup_amt_usd`（当日充值）和 `expired_amt_usd`（当日到期）|
| `mp_paidads.dws_advertiser_balance_td__reg_s0_live` | 提供广告主账户日终余额（`total_eod_balance_usd_td`），分别取当日和前一日分区 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_advertise_mkt_1d__reg_s0_live  ──────────────────────────────┐
   (Campaign消耗、预算、卖家属性)                                              │
                                                                              ▼
mp_paidads.dim_campaign__reg_s0_live  ──────────────────────────┐      [CTE: campaign]
mp_order.dim_exchange_rate__reg_s0_live  ───────────────────────┤  (Campaign级汇总，含 budget_usd 派生)
mp_paidads.dim_live_ads_default_cap__reg_s0_live  ──────────────┤            │
mp_paidads.dim_advertiser__reg_s0_live  ────────────────────────┤            ▼
mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live  ────────┤      [baseDF]
mp_paidads.dws_advertiser_balance_td__reg_s0_live (当日)  ──────┤  (LEFT JOIN账户余额、充值到期、配额)
mp_paidads.dws_advertiser_balance_td__reg_s0_live (前一日)  ────┘  (计算 campaign_valid_budget_usd)
                                                                              │
                                                          ┌───────────────────┴───────────────────┐
                                                          ▼                                       ▼
                                               [processedDF]                           [unprocessedDF]
                                     (账户余额充足，无需分摊)                     (账户余额不足，需分摊)
                                               │                                       │
                                               │                              [迭代分摊: collectValidBudget]
                                               │                           (按 account_campaign_cnt 均分剩余余额)
                                               │                           (循环至所有 Campaign 处理完毕)
                                               │                                       │
                                               └───────────────────┬───────────────────┘
                                                                   ▼
                                                           [resultDF (mergeDF)]
                                              JOIN campaignDF 补全 campaign_start/end_datetime 等字段
                                                                   │
                                                    Spark写入 Parquet（按 tz_type/grass_region/grass_date 分区）
                                                                   │
                                                    ALTER TABLE ADD PARTITION（注册 Hive 元数据）
                                                                   ▼
                                      mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live
```

> **计算引擎：** Apache Spark（Scala）；**写入方式：** Overwrite 模式写入 HDFS Parquet，之后通过 `ALTER TABLE ADD IF NOT EXISTS PARTITION` 注册到 Hive Metastore。

---

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|---------------|--------|------|
| `campaign`（Spark TempView） | `ads_advertise_mkt_1d__reg_s0_live` | Campaign 级汇总：聚合消耗、派生 `budget_usd`、标记 `is_live_ads`、过滤当日有效 Campaign |
| `baseDF` 内嵌子查询 `account` | `campaign` TempView | 按 `shop_id` 汇总账户级消耗（`account_expenditure_usd`）和 Campaign 数量（`account_campaign_cnt`）|
| `baseDF` 内嵌子查询 `dim_campaign` | `dim_campaign__reg_s0_live` + `dim_exchange_rate` | 解构 `quota_splits` 数组，计算 Live Ads 的系统预算 `sys_budget_usd`（USD）|
| `baseDF` 内嵌子查询 `default_cap` | `dim_live_ads_default_cap__reg_s0_live` + `dim_exchange_rate` | 计算 Live Ads 无日预算时的系统默认上限 `default_cap_usd`（USD）|
| `baseDF` 内嵌子查询 `dim_advertiser` | `dim_advertiser__reg_s0_live` | 补全广告主 `is_auto_topup_enabled` 属性 |
| `baseDF` 内嵌子查询 `credit_expiry` | `dwd_advertiser_credit_topup_df__reg_s0_live` | 计算当日充值金额（`topup_amt_usd`）和当日到期金额（`expired_amt_usd`）|
| `balance` | `dws_advertiser_balance_td__reg_s0_live`（当日分区）| 取当日日终余额 `account_balance_usd` |
| `balance_last1d` | `dws_advertiser_balance_td__reg_s0_live`（前一日分区）| 取前日日终余额 `account_balance_last1d_usd` |
| `unprocess_table`（迭代 TempView） | `unprocessedDF` 递归传入 | 迭代分摊算法中的未处理 Campaign 集合，每轮将已处理 Campaign 的预算从账户余额中扣除，继续为剩余 Campaign 分配 |

---

### 注意事项

1. **迭代预算分摊算法**：当账户下所有 Campaign 的有效预算之和（`agg_campaign_valid_budget`）超过账户可用余额（`account_available_fees`）时，ETL 启动 `collectValidBudget` 递归函数。每轮迭代将"能足额满足的 Campaign"（`split_budget >= GREATEST(budget_usd, ads_expenditure_usd)`）先行处理，剩余余额再均分给其他 Campaign，直至全部 Campaign 处理完毕。**该算法导致同一 shop_id 下各 Campaign 的 `campaign_valid_budget_usd` 不能简单相加**，整体账户有效预算请使用 `account_valid_budget_usd`。

2. **`remainning_available_fees >= 0` 过滤**：ETL 在 `baseDF` 最后一步过滤 `remainning_available_fees >= 0`（即 `account_expenditure_usd + account_balance_usd >= 0`），余额为负的账户下的 Campaign 不出现在本表中。下游分析账户覆盖率时需注意此口径。

3. **Live Ads 特殊逻辑**：`campaign_strategy_valid_budget_usd` 仅对 `pricing_type IN (9, 10, 14, 19)` 的 Campaign 有实际业务含义（Live Ads）。对非 Live Ads Campaign，该字段值与 `campaign_valid_budget_usd` 相同。Live Ads 的 `sys_budget_usd` 来源于 `dim_campaign.quota_splits.daily_available_quota`（策略层配额），若配额为 0 则取 `default_cap_usd` 兜底。

4. **`budget_usd` 的 9999999999 含义**：当 Campaign 无日预算且无法按总预算摊算时，`budget_usd` 被设为 `9999999999`（表示无限制），此时 `campaign_valid_budget_usd` 的上界由账户余额决定。下游过滤"有预算限制的 Campaign"时应排除此值。

5. **数据覆盖范围**：仅包含满足以下条件的 Campaign：当日有曝光、点击、消耗，**或** `campaign_status = 1 AND is_ads_active = 1`；且 Campaign 未到期（`campaign_end_datetime >= grass_date`）。纯休眠/已结束的 Campaign 不在本表中。

6. **汇率精度**：配额转换采用 `cast(daily_available_quota as bigint) * 1.00000 / 100000 / exchange_rate`，其中 `100000` 为本地货币单位换算因子（分 → 元/基本单位），精度保留 5 位小数。

---

## 数据来源（汇总）

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | Campaign 主驱动表，提供消耗、预算、广告活跃状态、卖家属性 |
| `mp_paidads.dim_campaign__reg_s0_live` | Live Ads 配额分割，计算策略预算 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率转换（本地货币 → USD）|
| `mp_paidads.dim_live_ads_default_cap__reg_s0_live` | Live Ads 系统默认消耗上限 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主属性（自动充值开关等）|
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 账户充值与到期记录 |
| `mp_paidads.dws_advertiser_balance_td__reg_s0_live` | 广告主账户日终余额（当日及前一日）|

---

*文档生成时间：2026-04-22*