<!-- ads-workspace-gdoc-sync: gdoc_id=1xi6PSf84P777VmBAISNTh8u4CI-ZNxfqbvNNASA0Sic gdoc_url=https://docs.google.com/document/d/1xi6PSf84P777VmBAISNTh8u4CI-ZNxfqbvNNASA0Sic/edit -->

# mp_paidads.dwd_advertiser_deduction_di

**分层**：DWD（数据明细层）
**主键**：`deduct_unique_id` + `ads_credit_id` + `grass_region` + `grass_date`（一条扣费事件按充值来源拆分后的最细粒度记录）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日全量覆盖写入（`INSERT OVERWRITE`）
**引用频次**：5 次（候选表范围内）

---

## 业务描述

本表记录广告主广告账户**每笔扣费事件的明细数据**，覆盖 CPC（按点击计费）、CPM（按千次展示计费）及 CPS（按订单计费）三种计价模式下的广告扣费流水。每条记录代表一次扣费事件（`deduct_unique_id`）从特定充值额度（`ads_credit_id`）中扣除的金额，当一次点击/展示同时消耗多个充值资金时，会被拆分为多行。

表的核心价值在于提供广告主消耗的全链路追踪能力：从扣费金额、充值来源类型（付费/免费/有无过期）、扣费前后余额变化，到广告本身的出价策略、计价模式、流量入口、AB 实验标识等，是广告消耗分析、账户资金核对、ROI 归因和充值激励项目效果评估的核心明细表。

本表同时关联了广告主维表（卖家类型）、广告维表（广告状态、类型）、充值流水明细（充值子类型、过期信息、活动归属）及汇率表（USD 换算），实现了跨域信息的预聚合，下游可直接使用，无需二次关联基础维表。各地区按本地时区参数化调度，写入时通过 `tz_type = 'local'` 分区隔离。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 数据日期分区，格式 `YYYY-MM-DD`，对应扣费事件所属的本地日期 |
| `grass_region` | string | 地区分区，如 `ID`、`MY`、`TH` 等，大写国家/地区代码 |
| `tz_type` | string | 时区类型分区，固定写入值为 `local`（本地时区），查询时必须指定 |

---

### 维度：主键与扣费事件标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | bigint | DB 原始行 ID，来源于 translog 表插入时生成。注意：同一 `id` 在本表中可能因充值来源拆分产生多行，`id` 与 `deduct_unique_id` 为 1:1，但本表行数可为 `id` 的 N 倍 ⚠️ 不可作为唯一行标识直接使用，需结合 `ads_credit_id` 等字段 |
| `deduct_unique_id` | bigint | 扣费事件唯一标识，与 `id` 为 1:1 关系，但本表按充值来源展开后一个 `deduct_unique_id` 可对应多行 ⚠️ 不可直接用于去重计数扣费事件数，需额外 DISTINCT 或结合 `ads_credit_id` |
| `ads_credit_id` | bigint | Ads Credit 唯一主键，标识一笔充值（充值、调整、发放等）产生的广告余额记录；扣费时若同时消耗多个 Credit，则拆分为多行。对于账户余额（无过期付费充值），扣费时无 `topup_order_id`，此字段亦可能为 null |
| `request_id` | string | 扣费请求 ID，用于追踪单次扣费请求 |

---

### 维度：广告与活动属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 被扣费广告的 ads_id |
| `campaign_id` | bigint | 广告活动 ID |
| `shop_id` | bigint | 广告主店铺 ID |
| `item_id` | bigint | 广告扣费关联的商品 ID |
| `ads_type` | string | 广告类型（来自广告维表 `dim_advertise`），字段已废弃（deprecated），不建议用于分析 ⚠️ |
| `ads_status` | bigint | 广告状态枚举值：0=已删除、1=正常、2=暂停、3=关闭、4=临时预留、5=已取消、6=已封禁、7=删除隐藏 |
| `placement` | bigint | 广告投放位置 |
| `pricing_type` | int | 广告计价模式枚举：1=手动CPC、2=增强CPC、5=CPT、6=CPM、9=直播最大曝光、10=直播最大GMV、11=ROI_TWO 等，详见枚举定义 |
| `keywords` | string | 导致积分扣减的广告关键词（来源于 translog 的 `keyword` 字段） |
| `brand_max_ads_type` | int | 品牌最大广告类型（来源于维表，comment 为空，具体含义待补充） |

---

### 维度：充值与扣费类型

| 字段 | 类型 | 说明 |
|------|------|------|
| `operation` | int | 事务操作类型，本表来源于 operation IN (1, 11, 15)：1=DEDUCT_CLICK（CPC扣费）、11=DEDUCT_IMP（CPM扣费）、15=DEDUCT_CPS_ORDER（CPS订单扣费） |
| `credit_order_type` | bigint | 充值订单类型枚举（TransOperation），标识充值/扣费的业务场景，详见字段枚举定义。对于无过期付费账户余额扣费，此字段为 null |
| `credit_order_type_name` | string | 充值订单类型名称，`credit_order_type` 的文字描述 |
| `credit_topup_type` | bigint | 充值类型枚举：1=无过期付费充值、2=有过期付费充值、3=无过期免费充值、4=有过期免费充值 |
| `credit_topup_type_name` | string | 充值类型名称，当 `credit_topup_type=1` 时固定为 `'paid credit without expiry'`，其余来自充值明细表 |
| `credit_topup_sub_type_name` | string | 充值子类型名称，对 `sub_type` 的文字描述 |
| `sub_type` | bigint | 手动充值子类别 |
| `consumption_type` | int | 扣费类型：0=普通扣费（General）、1=1:1 credit 扣费 |
| `effective_type` | int | 特定广告类型的 Ads Credit 标识 |
| `topup_order_id` | bigint | 充值订单 ID，唯一标识一次充值行为；对于无过期付费账户余额，扣费时无关联 `topup_order_id`，此字段为 null |
| `is_package_topup` | tinyint | 是否为套餐充值（1=是，0=否） |
| `is_voucher_topup` | tinyint | 是否为优惠券充值（1=是，0=否） |
| `voucher_id` | bigint | 优惠券 ID |
| `credit_program_id` | bigint | 本次充值归属的活动/项目 ID |
| `program_name` | string | 免费积分计划名称/活动名 |
| `credit_operator` | string | 手动充值操作员账号 |
| `credit_reason` | string | 手动充值审批原因 |

---

### 维度：流量与行为属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 触发广告扣费的用户 ID（点击用户）；CPM 场景下 `cpm_fix` 补偿部分此字段为 null |
| `entrance` | int | 广告流量入口 |
| `sub_entrance` | int | 次级广告入口，是 `entrance` 的二级细分，主要应用于 DD 和搜索流量 |
| `traffic_source` | int | 流量来源（如 org、roi1、roi2 等） |
| `match_type` | bigint | 关键词匹配类型：0=精确匹配、1=广泛匹配 |
| `recall_type` | bigint | 召回类型 |
| `sort_type` | bigint | 搜索排序方式，对应前端页面的 relevance / latest / top sales / price 等 |
| `user_query` | string | 导致广告扣费的用户搜索词（来自 `extinfo.query.keyword`） |
| `pdp_item_id` | bigint | 商品详情页的 item_id（来自 `extinfo.query.itemid`） |
| `pdp_shop_id` | bigint | 商品详情页的 shop_id（来自 `extinfo.query.shopid`） |
| `ab_sign` | string | AB 实验标识，来自 `extinfo.deductionInfo.algoName`，用于算法实验追踪 |

---

### 维度：卖家属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_type` | string | 店铺卖家类型，如 MYCB、CNCB、Local 等 |
| `seller_type_1p` | string | Shopee 自营与托管卖家类型：Lovito / SCS / Others / Unknown / Local SCS |

---

### 维度：充值时效属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `topup_create_timestamp` | bigint | 充值事件创建时间戳（Unix 秒） |
| `topup_expiry_start_timestamp` | bigint | 免费/有过期付费 credit 的过期生效时间戳 |
| `topup_expiry_end_timestamp` | bigint | 免费/有过期付费 credit 的过期结束时间戳 |
| `topup_expired_today` | tinyint | 该充值额度是否于当日到期：1=是、0=否 ⚠️ 时效性字段，仅在对应 `grass_date` 分区下有意义，跨日分析不可直接使用 |
| `program_start_timestamp` | bigint | 免费积分计划开始时间戳 |

---

### 指标：扣费金额

| 字段 | 类型 | 说明 |
|------|------|------|
| `deduction_amt` | double | 本次从特定 Ads Credit 中实际扣除的金额（本地货币），单位由原始值除以 100000 得到。CPM 场景下按展示成本比例分摊 ⚠️ 多行表示同一 `deduct_unique_id` 的不同充值来源拆分，SUM 时需确认聚合粒度，避免重复累加 |
| `deduction_amt_usd` | double | 扣费金额换算为 USD，由 `deduction_amt / exchange_rate` 计算得出 ⚠️ 为派生字段，不可直接 SUM 后与汇率做反推，应通过 `deduction_amt` 原值重新计算 |
| `deduction_price` | double | 广告出价扣费金额（来自 `extinfo.deductionInfo.deductionPrice`，单位除以 100000），即差价拍卖后实际成交价 |
| `deduction_price_usd` | double | `deduction_price` 换算为 USD ⚠️ 派生字段，不可直接 SUM |
| `voucher_deduction_price` | double | 优惠券抵扣金额（来自 `extinfo.voucherDeductionPrice`，单位除以 100000） |
| `voucher_deduction_price_usd` | double | 优惠券扣费金额换算为 USD ⚠️ 派生字段，不可直接 SUM |
| `expected_price_deduction` | double | 期望扣费金额（来自 `extinfo.expectDeductPrice`）⚠️ 为预期值，非最终扣费金额，不应与 `deduction_amt` 混用 |

---

### 指标：竞价与质量分

| 字段 | 类型 | 说明 |
|------|------|------|
| `bid_price` | double | 广告主当前出价（来自 `extinfo.deductionInfo.bidprice`） |
| `pctr` | double | 预估点击率，来自 `extinfo.deductionInfo.quality` ⚠️ 为模型预估比率，不可直接 SUM，需加权平均计算 |
| `second_ads_ecpm` | double | 次位广告的 eCPM 总分（质量分×出价），用于差价拍卖计算 ⚠️ 非本广告指标，为竞争广告数据，不可与本广告指标混合聚合 |
| `second_ads_id` | bigint | 次位广告的 ads_id，用于差价拍卖定位 |

---

### 指标：余额快照

| 字段 | 类型 | 说明 |
|------|------|------|
| `acc_before_balance` | double | 扣费前钱包余额（包含无过期付费充值及其他充值方式金额，不含免费充值和有过期付费充值），单位：本地货币 ⚠️ 为账户快照值，不可跨行 SUM，仅反映该时刻余额 |
| `acc_after_balance` | double | 扣费后钱包余额，含义同 `acc_before_balance` ⚠️ 为账户快照值，不可跨行 SUM |
| `credit_amt_before_deduct` | double | 点击扣费前含过期/不过期免费充值及有过期付费充值的余额 ⚠️ 为账户快照值，不可跨行 SUM |
| `credit_amt_after_deduct` | double | 点击扣费后含过期/不过期免费充值及有过期付费充值的余额 ⚠️ 为账户快照值，不可跨行 SUM |
| `available_balance_amt` | double | 可用余额（未被冻结/预留的余额，等同于钱包展示余额），来自 `extinfo.availableBalance`，单位除以 100000 ⚠️ 为事件发生时快照值，不可跨行 SUM |
| `valid_balance_amt` | double | 有效可用余额（考虑1:1消耗规则，被 block 的免费 credit 及通用 credit 不计入），来自 `extinfo.validBalance`，单位除以 100000 ⚠️ 为事件发生时快照值，含特殊消耗规则，不可与 `available_balance_amt` 混用 |
| `original_topup_credit_amt` | double | 该充值订单的原始充值金额（本地货币），来自充值明细表 `max(topup_amt)` ⚠️ 取 max 聚合后的值，代表整笔充值金额，非本次扣费金额 |

---

### 指标：CPS 专属指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `cps_total_expenditure_amt` | double | CPS 广告从点击时间到下单时间的总消耗，单位除以 100000 ⚠️ 仅 CPS 广告（`operation=15`）有值，其他计价模式下为 null |
| `cps_available_budget` | double | CPS 广告从点击时间到下单时间的可用预算，单位除以 100000 ⚠️ 仅 CPS 广告有值，其他计价模式下为 null |

---

### 指标：时间戳

| 字段 | 类型 | 说明 |
|------|------|------|
| `event_timestamp` | bigint | Track 服务到达时间戳（Unix 秒），对应 translog 的 `timestamp` 字段 |
| `event_datetime` | string | Track 服务到达时间，格式 `YYYY-MM-DD HH:mm:ss`，由 `from_unixtime(timestamp)` 转换，基于调度时区 ⚠️ 时区依赖调度参数，跨地区对比时需注意时区差异 |
| `deduct_timestamp` | bigint | 实际扣费事件时间戳（Unix 秒），来自 `extinfo.deductTimestamp`；CPC 为点击时刻，CPM 为该转录日志中所有展示的最新时刻 |
| `click_timestamp` | bigint | 点击时间戳（Unix 秒），来自 `extinfo.clickTimestamp` |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，导致资源浪费和查询超时：

```sql
WHERE grass_date = DATE('2024-01-01')   -- 必须指定，避免全量历史扫描
  AND grass_region = 'MY'              -- 必须指定，隔离地区数据
  AND tz_type = 'local'               -- 必须指定，本表仅写入 local 分区
```

- `tz_type`：本表通过 `INSERT OVERWRITE PARTITION (tz_type = 'local', ...)` 写入，**只有 `local` 分区有数据**，若遗漏此条件可能返回空结果或产生不必要的分区扫描。
- `grass_region`：各地区数据独立分区，遗漏将导致跨地区数据混合，金额（本地货币）将无法直接对比。
- `grass_date`：本表为按日全量覆盖，遗漏将扫描全部历史日期分区。

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确用法 |
|------|------|----------|
| `deduction_amt` | 同一 `deduct_unique_id` 按充值来源拆分为多行，直接 SUM 无误，但统计扣费事件数时需用 `COUNT(DISTINCT deduct_unique_id)` | 统计总消耗可 SUM，统计扣费次数须 DISTINCT |
| `deduction_amt_usd` | 派生字段（`deduction_amt / exchange_rate`），汇率可能不同日期不同，不可跨日 SUM 后反推 | 以 `deduction_amt` 聚合后再除以当日汇率，或直接 SUM 此字段（同地区同日期内有效） |
| `deduction_price_usd` | 同上，为 `deduction_price / exchange_rate` 派生 | 同 `deduction_amt_usd` |
| `voucher_deduction_price_usd` | 同上，为 `voucher_deduction_price / exchange_rate` 派生 | 同 `deduction_amt_usd` |
| `pctr` | 预估点击率，为比率字段 | 需加权平均：`SUM(pctr * weight) / SUM(weight)` |
| `second_ads_ecpm` | 次位广告的得分，非本广告指标 | 不应纳入本广告绩效的 SUM/AVG 聚合 |
| `acc_before_balance` / `acc_after_balance` / `credit_amt_before_deduct` / `credit_amt_after_deduct` / `available_balance_amt` / `valid_balance_amt` | 均为账户余额快照值，跨行 SUM 无业务意义 | 取特定时刻（如最新一条）的值，或用于前后余额差值校验 |
| `original_topup_credit_amt` | 为整笔充值金额（对应充值订单），同一充值订单下多条扣费记录会重复出现此值 | 不可直接 SUM，需先按 `topup_order_id` + `ads_credit_id` 去重后再聚合 |
| `expected_price_deduction` | 为预期扣费金额，非实际扣费 | 仅用于与 `deduction_price` 对比分析，不应与实际消耗混合计算 |

### 时效性说明

- `topup_expired_today` 字段仅在**对应 `grass_date` 分区下**反映当日过期状态，历史分区中该值不会随时间更新，跨日查询时此字段仅代表历史写入时的状态。
- `event_datetime` 基于调度时区转换，各地区按本地时区参数化调度；跨地区时间对比时建议统一转换为 UTC 后比较。
- CPS 场景下 `cps_total_expenditure_amt` / `cps_available_budget` 记录的是**点击到下单时间段**内的快照值，与 `grass_date` 分区日期对应，不代表整个订单生命周期累计值。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live` | 核心源表，提供 CPC（operation=1,15）和 CPM（operation=11）扣费事件原始流水，包含扣费金额、extinfo JSON（含出价、质量、流量信息）、账户余额快照 |
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | CPM 场景专用，提供展示事件级别的用户 ID 和 adjusted_cost，用于将 CPM 整体扣费按展示比例分摊至各用户 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，提供 `seller_type`、`seller_type_1p` 等卖家属性 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，提供 `ads_type`、`ads_status`、`pricing_type` 等广告属性 |
| `mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live` | 广告主充值明细表，提供充值类型名称、活动归属、过期时间、原始充值金额、优惠券信息等 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供本地货币兑 USD 汇率，用于计算 `_usd` 后缀金额字段 |

---

## ETL 逻辑摘要

### 数据流

```
ods_shopee_ads_db__translog_tab_di__reg_s0_live
  │
  ├─── [operation IN (1,15), CPC/CPS 扣费]
  │         │
  │         ▼
  │    CTE: cpc_detail
  │    ├── 展开 adsCredits JSON 数组（lateral view explode）
  │    │   → 按充值来源拆分行
  │    └── 解析 decoded_extinfo 各 JSON 字段
  │
  ├─── [operation = 11, CPM 扣费]
  │         │
  │         ├─────────────────────────────────────────────────────────────────┐
  │         ▼                                                                  │
  │    CTE: cpm_detail                          ods_log_translog_event_hi    │
  │    ├── 展开 adsCredits / frozen.adsCredits JSON 数组                      │
  │    ├── LEFT JOIN translog_event ─────────────────────────────────────────┘
  │    │   (按 deduct_unique_id + adsid 关联，取 user_id 和 adjusted_cost)
  │    │   → 按展示成本比例（adjusted_cost / total_cost）分摊 deduction_amt
  │    └── 过滤 deduction_amt > 0
  │
  └─── [operation = 11, CPM 补偿修正]
            │
            ▼
       CTE: cpm_fix
       ├── 处理 mainType≠2无过期 的 credit（有过期付费、免费 credit）
       ├── 减去 cpm_detail 中已计算金额，补偿差额
       └── 同样基于 paidFreeExpirySummary.entries 处理无关联 credit 场景
                        │
                        ▼
               CTE: deduction_di
               （UNION ALL: cpc_detail ∪ cpm_detail ∪ cpm_fix）
                        │
          ┌─────────────┼──────────────────────────────────────┐
          │             │                                        │
          ▼             ▼                                        ▼
 dim_advertiser   dim_advertise              dwd_advertiser_credit_topup_df
 (LEFT JOIN       (LEFT JOIN                 (LEFT JOIN on topup_order_id +
  on shop_id)      on ads_id + placement)    credit_order_type + grass_region
                                             + credit_topup_type + ads_credit_id)
          │             │                                        │
          └─────────────┴────────────────────────────────────────┘
                        │
                        ▼
              dim_exchange_rate (LEFT JOIN on grass_region)
                        │
                        ▼
         INSERT OVERWRITE
         dwd_advertiser_deduction_di__reg_s0_live
         PARTITION (tz_type='local', grass_region=..., grass_date=...)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `cpc_detail` | `ods_shopee_ads_db__translog_tab_di__reg_s0_live`（operation IN 1,15） | 处理 CPC/CPS 扣费流水；通过 `lateral view explode(adsCredits)` 将一条扣费记录按充值来源展开为多行；同时解析 `decoded_extinfo` JSON 提取出价、质量分、流量等扩展字段 |
| `cpm_detail` | `ods_shopee_ads_db__translog_tab_di__reg_s0_live`（operation=11）+ `ods_log_translog_event_hi` | 处理 CPM 扣费流水；展开 adsCredits 后 LEFT JOIN 展示事件表，按 `adjusted_cost / total_cost` 比例分摊各用户的 `deduction_amt`；过滤 `deduction_amt > 0` |
| `cpm_fix` | `ods_shopee_ads_db__translog_tab_di__reg_s0_live`（operation=11）+ `cpm_detail` | CPM 扣费补偿修正 CTE；处理 `cpm_detail` 中未能关联到 translog_event 的 credit（mainType≠无过期付费），通过差值补偿（translog总额 - cpm_detail已分摊额）确保金额完整性；同时处理通过 `paidFreeExpirySummary.entries` 记录的 type=1 的 credit |
| `deduction_di` | `cpc_detail` ∪ `cpm_detail` ∪ `cpm_fix` | 三路 UNION ALL 汇总所有计价模式的扣费明细，统一字段命名（如 `order_id` → `topup_order_id`，`order_type` → `credit_order_type`），作为最终 INSERT 前的主体数据集 |

### 注意事项

1. **多行陷阱（行爆炸）**：同一 `deduct_unique_id` 若同时消耗多个 Ads Credit（付费+免费混合扣费），会通过 `lateral view explode(adsCredits)` 展开为多行，`id` 相同但 `ads_credit_id` 不同。统计扣费事件数时必须使用 `COUNT(DISTINCT deduct_unique_id)`，直接 `COUNT(*)` 会高估。

2. **CPM 分摊精度**：CPM 场景下 `deduction_amt` 通过 `round((adjusted_cost / total_cost) * deduction_amt, 5)` 按比例分摊，存在精度舍入。`cpm_fix` CTE 专门用于补偿因精度问题或无法关联 translog_event 导致的金额缺失，确保同一 `deduct_unique_id` 总扣费金额守恒。

3. **JSON 解析字段**：`pctr`、`bid_price`、`second_ads_ecpm`、`deduction_price`、`traffic_source` 等大量字段均从 `decoded_extinfo` JSON 字段解析而来，若上游 JSON 结构变更或字段缺失，对应字段值可能为 null。

4. **无过期付费充值的特殊处理**：当 `credit_topup_type = 1`（无过期付费充值）时，对应的 `topup_order_id`（即 `ads_credit_id`）在扣费时不关联充值订单，因此 `credit_order_type` 也为 null，无法 JOIN 到 `dwd_advertiser_credit_topup_df`，充值相关维度字段（如 `program_name`、`topup_expiry_start_timestamp`）均为 null。`credit_topup_type_name` 在此情况下由 ETL 硬编码为 `'paid credit without expiry'`。

5. **`ads_type` 字段废弃**：该字段 comment 标注为 `deprecated`，来源于 `dim_advertise` 维表，不应在新分析中使用。

6. **汇率关联**：USD 金额字段通过当日汇率计算，跨日汇总时各日的 `_usd` 字段可以直接 SUM（每日已换算），但不应将不同地区的本地货币金额混合 SUM。

7. **CPM `user_id` 为 null 的情形**：`cpm_fix` 补偿部分中 `user_id` 固定为 null（CPM 展示无法关联到具体用户的补偿记录），做用户级分析时需注意过滤。

---

*文档生成时间：2026-05-20*