<!-- ads-workspace-gdoc-sync: gdoc_id=1Yoo556Vt-WGwzxMQCYAaqroyJml4lC8d-mO39ezUcSY gdoc_url=https://docs.google.com/document/d/1Yoo556Vt-WGwzxMQCYAaqroyJml4lC8d-mO39ezUcSY/edit -->

# mp_paidads.dwd_advertiser_transaction_di

**分层：** DWD（数据明细层）
**主键：** `deduct_unique_id`（扣费事件）/ `id`（每日自增流水号）
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日调度（DI，日增量覆盖写入）
**引用频次：** 10 次（候选表范围内）

---

## 业务描述

本表记录广告主账户的每一笔资金流水事件，涵盖广告点击扣费（CPC）、曝光扣费（CPM）、账户充值（手动/自动/钱包）、免费额度注入、冻结/解冻等全部操作类型。每行代表一条独立的交易流水记录，是广告计费系统的核心明细表。

核心使用场景包括：广告主消耗金额统计与对账、充值行为分析、账户余额变动追踪、各广告位/计价模式的消耗拆解，以及异常扣费排查。下游 DWS/ADS 层的广告消耗汇总、ROI 分析、财务对账等报表均以本表为基础数据源。

本表通过参数化调度（`${region}`、`${timezone}`）覆盖所有地区市场，各地区按本地时区独立产出当日分区数据，确保本地日期口径一致。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区，固定值为 `'local'`（本地时区），各地区按本地时区参数化调度产出 ⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 地区分区，如 `'MY'`、`'TH'`、`'VN'` 等，覆盖所有已上线地区 ⚠️ 查询时必须指定具体地区，否则将跨地区全扫描 |
| `grass_date` | date | 日期分区，以本地时区对应的业务日期为准，格式 `YYYY-MM-DD` ⚠️ 查询时必须指定日期范围，避免全量扫描 |

---

### 维度：主键与流水标识

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `id` | bigint | 来源于 `translog_tab` 的每日自增 ID，在同一地区同一日期内唯一 ⚠️ 跨日期、跨地区不保证唯一，不可作全局主键 |
| `deduct_unique_id` | bigint | 扣费事件在数据库中的唯一标识符，**仅扣费事件有值**，充值/调整类事件该字段为 NULL ⚠️ 不可用此字段做全量记录去重 |
| `event_code` | tinyint | 操作类型枚举值（对应源表 `operation` 字段），详见枚举说明：1=点击扣费、2=订单充值、3=手动充值、4=钱包充值、5=订单扣费、6=SVS充值、8=卖家任务充值、9=SRM充值、10=负余额抵扣、11=曝光扣费（CPM），更多枚举见字段描述 |
| `event_type` | string | 操作类型名称，为 `event_code` 的可读化映射，如 `'deduction'`、`'topup_from_order'`、`'deduct_imp'` 等；枚举范围外的 `operation` 值映射为 NULL |
| `event_timestamp` | bigint | 事件 Unix 时间戳（秒级）；扣费事件指 Track 服务到达时间，充值/调整事件指实际操作时间 ⚠️ 语义随 `event_code` 不同而变化，跨类型比较需注意 |
| `event_datetime` | string | 事件时间的格式化字符串（`YYYY-MM-DD HH:MM:SS`），由 `event_timestamp` 按本地时区转换得出，语义同 `event_timestamp` ⚠️ 为派生字段，排序/过滤建议直接使用 `event_timestamp` |

---

### 维度：广告与活动属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_id` | bigint | 广告 ID |
| `campaign_id` | bigint | 营销活动 ID；优先取 `dim_advertise` 表值，缺失时从 `decoded_extinfo.campaignid` 解析 ⚠️ 部分旧数据可能为 NULL |
| `ads_type` | string | 广告类型，已废弃（deprecated），不建议用于业务分析 ⚠️ 字段值不可信 |
| `ads_status` | bigint | 广告状态，来自 `dim_advertise` 维表，反映调度时刻的广告状态快照 ⚠️ 为维表当日快照值，非事件发生时的实时状态 |
| `status` | bigint | 广告状态枚举，来自源流水表（`translog_tab.status`），枚举：0=已删除、1=正常、2=暂停、3=关闭、4=临时保留、5=已取消、6=已封禁、7=隐藏删除 |
| `placement` | bigint | 广告位，优先取 `dim_advertise` 表值，缺失时取流水表原始值；枚举详见 proto 定义 |
| `pricing_type` | int | 广告计价模式枚举；优先取 `decoded_extinfo.pricingType`，缺失时取 `dim_advertise.pricing_type`；枚举：0=默认、1=手动CPC、2=增强CPC、5=CPT、6=CPM、9=直播最大观看、10=直播最大GMV 等 |
| `item_id` | bigint | 广告关联商品 ID，来自 `dim_advertise` 维表 |
| `shop_id` | bigint | 广告主店铺 ID |
| `account_id` | bigint | 广告账户 ID |
| `entrance` | int | 广告入口枚举；CPM（`event_code=11`）事件取自 `ods_log_translog_event_hi`，其他事件从 `decoded_extinfo.entrance` 解析 |
| `keywords` | string | 广告竞价关键词；来自源表 `keyword` 字段，已过滤 `system_dummy_negative_deduction` 系统占位词 |
| `match_type` | bigint | 关键词匹配类型，从 `decoded_extinfo.matchType` 解析 |
| `recall_type` | bigint | 广告召回类型，从 `decoded_extinfo.recallType` 解析 |
| `sort_type` | bigint | 用户搜索排序方式（如相关性、最新、销量、价格等），从 `decoded_extinfo.query.sorttype` 解析 |
| `ab_sign` | string | A/B 实验标识，从 `decoded_extinfo.deductionInfo.algoName` 解析，用于算法实验追踪 |

---

### 维度：用户与页面上下文

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `user_id` | bigint | 用户 ID；CPM 扣费（`event_code=11`）取自 `ods_log_translog_event_hi` 的 `cpm_event_details`，CPC 扣费取点击用户 ID（直播广告为 NULL），充值事件取广告主 user_id ⚠️ 字段语义因 `event_code` 不同而不同，混合类型查询需分组处理 |
| `user_query` | string | 用户搜索查询词（触发广告扣费的检索词），从 `decoded_extinfo.query.keyword` 解析，仅搜索场景扣费有值 |
| `pdp_item_id` | bigint | 商品详情页（PDP）的商品 ID，从 `decoded_extinfo.query.itemid` 解析 |
| `pdp_shop_id` | bigint | 商品详情页（PDP）的店铺 ID，从 `decoded_extinfo.query.shopid` 解析 |

---

### 维度：二价竞拍与算法信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `second_ads_id` | bigint | 排名次位广告的 ads_id，用于二价扣费追踪，从 `decoded_extinfo.deductionInfo.nextAdsid` 解析；仅扣费事件有值 |
| `decoded_extinfo` | string | 原始 extinfo 的解密/解析 JSON 字符串，包含扣费详情、竞拍信息等 ⚠️ 为 JSON 字符串，下游使用须通过 `get_json_object` 解析，不可直接聚合 |

---

### 维度：已废弃字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `topup_order_id` | bigint | 已废弃（deprecated），ETL 中硬编码为 NULL，不建议使用 ⚠️ 字段恒为 NULL |
| `topup_sign` | string | 已废弃（deprecated），ETL 中硬编码为 NULL，不建议使用 ⚠️ 字段恒为 NULL |

---

### 指标：金额（本地货币，已换算）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `price` | double | 本次交易金额（本地货币）；扣费事件仅含账户余额变动部分，充值/调整事件含账户余额与广告 credit 的总变动 ⚠️ 扣费与充值语义不对称，不可将不同 `event_code` 的 `price` 直接加总对账；原始值已除以 10^5 换算为本地货币单位 |
| `acc_before_balance` | double | 本次操作前的账户余额（本地货币），原始值已除以 10^5 换算 |
| `acc_after_balance` | double | 本次操作后的账户余额（本地货币），原始值已除以 10^5 换算 |
| `dai_before_balance` | double | 本次操作前的每日预算余额（本地货币），原始值已除以 10^5 换算 |
| `dai_after_balance` | double | 本次操作后的每日预算余额（本地货币），原始值已除以 10^5 换算 |
| `expected_price_deduction` | double | 期望扣费金额，从 `decoded_extinfo.expectDeductPrice` 解析（原始整型，单位与 `price` 不同）⚠️ 单位为原始整型（未除以 10^5），与 `price` 字段单位不一致，不可直接比较 |

---

### 指标：竞拍与质量分

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `bid_price` | double | 广告主当前出价，从 `decoded_extinfo.deductionInfo.bidprice` 解析（BIGINT 类型存储）⚠️ 仅扣费事件有值；单位为原始整型，与 `price` 单位体系一致性需确认 |
| `pctr` | double | 预测点击率（predicted CTR），从 `decoded_extinfo.deductionInfo.quality` 解析 ⚠️ 为模型预测的比率值（0~1），不可直接 SUM，需加权平均计算 |
| `second_ads_ecpm` | double | 次位广告的 eCPM 总分（质量分 × 出价），用于差价扣费计算，从 `decoded_extinfo.deductionInfo.nextScore` 解析 ⚠️ 仅扣费事件有值，充值类事件为 NULL |

---

### 指标：信用额度扣费明细

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `deduction_details` | string | 广告 credit 账户扣费明细列表（Protobuf 序列化后的 JSON），字段含 `order_id`、`balance_before`、`balance_after`、`main_type` 等子字段；优先取 `decoded_extinfo.adsCredits`，缺失时取 `decoded_extinfo.frozen.adsCredits` ⚠️ 为 JSON 字符串，需解析后使用；仅扣费事件有值 |
| `paid_free_expiry_summary` | string | 本次扣款中各 credit 类型（付费/免费/到期）的金额分布汇总，从 `decoded_extinfo.paidFreeExpirySummary` 解析 ⚠️ 为 JSON 字符串，需解析后使用 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，产生极高的计算资源消耗：

```sql
WHERE tz_type = 'local'
  AND grass_region = '<目标地区>'   -- 如 'MY'、'TH'、'ID' 等
  AND grass_date BETWEEN '<start_date>' AND '<end_date>'
```

- `tz_type`：目前有效分区值为 `'local'`，**必须显式指定**，否则扫描所有时区分区
- `grass_region`：按地区业务范围指定，不可省略
- `grass_date`：必须指定日期范围，避免全量历史扫描

若需统计纯消耗数据（排除充值、调整），建议追加：
```sql
  AND event_code IN (1, 5, 11)  -- 扣费类事件
```

---

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确做法 |
|------|------|----------|
| `pctr` | 预测点击率（比率值），直接 SUM 无业务意义 | 需加权平均：`SUM(pctr * impression) / SUM(impression)` |
| `price` | 扣费事件（`event_code IN (1,5,11)`）与充值事件（`event_code IN (2,3,4,6,8,9)`）语义不同，混合 SUM 会导致错误对账 | 按 `event_code` 分组后分别汇总，消耗金额仅对扣费类事件求和 |
| `expected_price_deduction` | 单位为原始整型（未除以 10^5），与其他金额字段单位不一致 | 使用时需除以 10^5 换算为本地货币，或仅在同单位场景下与原始字段对比 |
| `deduction_details` | JSON 字符串，直接聚合无意义 | 使用 `get_json_object` 或 `FROM_JSON` 解析后再计算 |
| `paid_free_expiry_summary` | JSON 字符串，直接聚合无意义 | 解析 JSON 后按 credit 类型汇总 |
| `acc_before_balance` / `acc_after_balance` | 余额快照值，SUM 无意义 | 取最新一条记录的 `acc_after_balance` 作为当前余额；余额变动用 `acc_after_balance - acc_before_balance` |
| `dai_before_balance` / `dai_after_balance` | 每日预算余额快照值，SUM 无意义 | 同上，取最新快照或计算差值 |

---

### 时效性说明

本表为 **DI（日增量）** 表，每日覆盖写入当日分区。查询最新数据时，建议取 **最近已完成调度的分区日期**，通常为 `grass_date = CURRENT_DATE - 1`（T+1 产出前一日数据）。

`event_datetime` 字段由源表 Unix 时间戳按本地时区转换得出，与分区日期 `grass_date` 口径一致，可用于分区内的时间细粒度过滤，但**不应跨分区依赖此字段做日期判断**（应以分区字段 `grass_date` 为准）。

CPM 事件（`event_code = 11`）的 `user_id` 和 `entrance` 字段来源于 `ods_log_translog_event_hi`，该上游表使用了跨日期窗口（`grass_date` 至 `grass_date + 1`）关联，对于日期边界附近的 CPM 事件，相关字段可能存在少量延迟或空值。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live` | 主表，提供广告交易流水原始记录，包含金额、时间戳、操作类型、extinfo 等核心字段 |
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | 补充 CPM（曝光扣费）事件的 `user_id` 和 `entrance` 字段，通过 `deduct_unique_id` 与 `ads_id` 关联；跨日期窗口查询以覆盖时区边界 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，补充 `campaign_id`、`ads_status`、`placement`、`ads_type`、`item_id`、`user_id`（广告主）、`pricing_type` 等广告属性 |

---

## ETL 逻辑摘要

### 数据流

```
ods_shopee_ads_db__translog_tab_di__reg_s0_live
  (grass_region = '${upper_region}', grass_date = '${grass_date}', tz_type = 'local')
  │  过滤: keyword != 'system_dummy_negative_deduction'
  │
  ├── LEFT JOIN ──────────────────────────────────────────────────────────────────────┐
  │     ON operation = 11                                                             │
  │     AND translog.deduct_unique_id = cpm.deduct_unique_id                         │
  │     AND translog.adsid = cpm.ads_id                                              │
  │                                                                          ods_log_translog_event_hi__reg_s0_live
  │                                                                          (operation=11, 跨日期窗口)
  │                                                                          LATERAL VIEW EXPLODE(cpm_event_details_str)
  │                                                                          → 提取 user_id, entrance
  │
  └── LEFT JOIN ──────────────────────────────────────────────────────────────────────┐
        ON translog.adsid = advertise.ads_id                                          │
        AND translog.placement = advertise.placement                                  │
                                                                          dim_advertise__reg_s0_live
                                                                          (grass_date = '${grass_date}')
                                                                          → 提供 campaign_id, ads_status,
                                                                            ads_type, item_id, user_id,
                                                                            pricing_type, placement
  │
  ▼
字段加工：
  ├── price / 10^5 → price（本地货币换算）
  ├── acc_before/after_balance / 10^5 → 账户余额（本地货币换算）
  ├── dai_before/after_balance / 10^5 → 每日余额（本地货币换算）
  ├── get_json_object(decoded_extinfo, ...) → 解析竞拍/查询/credit 字段
  ├── coalesce(dim_advertise 字段, translog/extinfo 字段) → 字段优先级合并
  └── topup_order_id = NULL, topup_sign = NULL（废弃字段置空）
  │
  ▼
INSERT OVERWRITE
dwd_advertiser_transaction_di__reg_s0_live
PARTITION (tz_type='local', grass_region='${upper_region}', grass_date='${grass_date}')
```

### 关键 CTE 说明

本 ETL 未使用显式 CTE，采用内联子查询方式：

| 子查询别名 | 来源表 | 作用 |
|------------|--------|------|
| `translog`（主查询驱动表） | `ods_shopee_ads_db__translog_tab_di__reg_s0_live` | 提供所有交易流水原始字段，作为左表驱动整个 JOIN |
| `cpm`（内联子查询） | `ods_log_translog_event_hi__reg_s0_live` | 专为 `operation=11`（CPM 扣费）提取点击用户（`user_id`）和广告入口（`entrance`），通过 `LATERAL VIEW EXPLODE` 展开 JSON 数组 |
| `advertise`（内联子查询） | `dim_advertise__reg_s0_live` | 广告维度属性补全，当流水表字段缺失时通过 `COALESCE` 提供兜底值 |

### 注意事项

1. **金额单位换算**：源表 `translog_tab` 中金额字段（`price`、各 `balance` 字段）以整型存储，单位为本地货币最小精度单位（除以 10^5 得到实际金额）。`expected_price_deduction` 字段从 `decoded_extinfo` 解析为 `BIGINT`，**未做单位换算**，使用时需自行处理。

2. **CPM 事件跨日期关联**：`ods_log_translog_event_hi` 使用 `grass_date >= ${grass_date} AND grass_date <= ${grass_date} + 1` 的跨日期窗口，并通过时区转换过滤时间戳范围，以确保覆盖本地日期边界附近的 CPM 日志。因此 CPM 事件的 `user_id` 和 `entrance` 在极少数边界情况下可能为 NULL。

3. **`price` 字段语义二义性**：扣费事件（`event_code IN (1,5,11)`）的 `price` 仅反映账户余额（wallet）扣减，不含广告 credit 部分；充值/注入类事件的 `price` 含账户余额与广告 credit 的总增量。如需完整消耗口径，需结合 `deduction_details` 计算 credit 消耗。

4. **`user_id` 多义性**：同一字段在不同 `event_code` 下含义不同——扣费时为点击用户（直播广告为 NULL），充值时为广告主 user_id。下游使用时应先按 `event_code` 分类再引用该字段。

5. **系统占位词过滤**：源表过滤了 `keyword = 'system_dummy_negative_deduction'` 的记录，该类记录为系统内部负余额冲正操作，不代表真实广告扣费行为。

6. **废弃字段**：`topup_order_id`、`topup_sign`、`ads_type` 均已废弃，ETL 中前两者硬编码为 NULL，不应用于任何业务分析。

7. **`dim_advertise` 关联条件**：同时匹配 `ads_id` 和 `placement`，对于同一广告在不同广告位的情况，维表字段优先级高于流水表原始值，若维表无对应记录则保留流水表原始 `placement`。

---

*文档生成时间：2026-04-22*