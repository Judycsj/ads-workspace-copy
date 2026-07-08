<!-- ads-workspace-gdoc-sync: gdoc_id=1e4te3pVvcieOQCojCdg3CrqqfHXmbjSoQ5LyDxIPPYw gdoc_url=https://docs.google.com/document/d/1e4te3pVvcieOQCojCdg3CrqqfHXmbjSoQ5LyDxIPPYw/edit -->

# mp_paidads.dwd_advertiser_credit_topup_df

**分层：** DWD（明细数据层）
**主键：** `ads_credit_id`（广告充值记录唯一标识）
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日全量覆盖（INSERT OVERWRITE，按分区）
**引用频次：** 114 次（候选表范围内下游引用）

---

## 业务描述

本表是广告主广告余额充值的 DWD 明细宽表，完整记录每一笔广告信用额度（Ads Credit）的充值、调整、发放、套餐兑换等操作的全链路信息。每行对应一条充值记录（`ads_credit_id` 唯一标识），涵盖充值金额、充值类型（付费/免费/SVS 套餐）、有效期、余额、优惠券、套餐包等核心属性，以及本地货币与 USD 双币种金额（含当日汇率和历史汇率两个口径）。

本表是广告充值分析的核心底表，广泛用于：广告充值收入统计、免费 credit 投放效果监控、广告余额健康度分析、人工充值审批流跟踪、ACP/SVS 套餐核销分析等场景。下游 ADS 层报表、BI 看板及运营决策工具均以本表为主要数据源，高引用频次（114 次）印证了其基础地位。

各地区按本地时区参数化调度，统一输出 `tz_type='local'` 分区，确保不同市场的日期归属遵循本地时区语义。对于套餐充值（ACP / SVS 套餐）和优惠券充值，ETL 会将一笔原始充值拆分为"付费部分"和"免费部分"两行，以便下游按付费/免费维度精确统计充值金额。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区。当前写入值固定为 `'local'`，代表各地区按本地时区归属日期。⚠️ 查询时必须指定 `tz_type = 'local'`，否则将触发全分区扫描 |
| `grass_region` | string | 国家/地区分区，大写字母，如 `'SG'`、`'MY'`、`'PH'` 等。⚠️ 查询时必须指定，避免跨地区全扫描 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`，表示当前数据快照所对应的本地日期。⚠️ 查询时必须指定，避免全量历史扫描 |

---

### 维度：主键与广告账户

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_credit_id` | bigint | 广告充值记录（Ads Credit）的唯一主键，用于唯一标识一笔充值/调整/发放操作产生的广告余额记录 |
| `shop_id` | bigint | 店铺 ID |
| `user_id` | bigint | 用户 ID |
| `order_id` | bigint | 充值订单 ID，与 `topup_translog_tab` 中的 `orderid` 对应 |

---

### 维度：充值类型与订单属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_type` | bigint | 充值操作类型枚举值（详见 enum TransOperation）。常用值：2=从订单充值、3=人工充值、6=SVS 套餐充值、7=免费 credit、10=credit 调整、16=ACP 套餐充值 等 |
| `order_type_name` | string | 订单类型名称，与 `order_type` 对应的可读描述 |
| `credit_topup_type` | bigint | 充值类型细分枚举：1=付费无期限、2=付费有期限、3=免费无期限、4=免费有期限。⚠️ 对于套餐/优惠券充值，该字段由 ETL 拆行后重新计算，与原始充值记录值可能不同，不可直接与原始流水关联比较 |
| `credit_topup_type_name` | string | 充值类型名称，如 `'paid credit with expiry'`、`'free credit without expiry'` 等，与 `credit_topup_type` 对应 |
| `credit_topup_main_type` | bigint | 充值主类型：2=付费 credit、3=免费 credit、5=SVS 套餐及 Package。⚠️ 套餐/优惠券拆行后该字段被重新赋值，拆分行中 SVS 套餐（=5）会被改写为 2 或 3 |
| `credit_topup_main_type_name` | string | 充值主类型名称，如 `'paid credit'`、`'free credit'`，与 `credit_topup_main_type` 对应 |
| `credit_topup_sub_type` | bigint | 充值子类别枚举 ID，描述充值的细分场景（如特定激励项目、特殊计划等） |
| `credit_topup_sub_type_name` | string | 充值子类别名称，与 `credit_topup_sub_type` 对应 |
| `credit_topup_status` | bigint | 充值状态，来源于人工充值表（manual credit tab），仅 `order_type in (3, 10, 14)` 时有实质意义 |
| `svs_topup_status` | bigint | SVS 充值状态，仅适用于 SVS 类充值（`order_type = 6`）。枚举：0=处理中、1=失败、2=成功。该表仅包含已确认的 SVS 充值记录 |
| `is_topup_today` | tinyint | 是否在 `grass_date` 当天发生充值：1=是，0=否 |
| `is_package_topup` | tinyint | 是否为套餐充值（`pckg_id > 0`）：1=是，0=否 |
| `is_voucher_topup` | tinyint | 是否为优惠券充值（`voucher_id > 0`）：1=是，0=否 |
| `effective_type` | int | 特定广告类型的 ads credit 用途属性（来源于 `ads_credit_tab.effective_type`） |
| `consumption_type` | int | 扣费类型，仅适用于免费 credit。枚举：0=General，1=1:1 credit，定义免费 credit 的消耗方式 |
| `ads_revenue_push_type` | int | 已废弃字段，值固定为 null ⚠️ 请勿使用 |
| `seller_investment_type` | int | 已废弃字段，值固定为 null ⚠️ 请勿使用 |

---

### 维度：有效期与过期状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `credit_topup_expiry_start_timestamp` | bigint | Credit 有效期开始时间（Unix 时间戳），0 或 null 表示无有效期限制 |
| `credit_topup_expiry_start_datetime` | string | Credit 有效期开始时间，格式 `YYYY-MM-DD HH:MM:SS`，0 时为 null |
| `credit_topup_expiry_end_timestamp` | bigint | Credit 有效期结束时间（Unix 时间戳），0 或 null 表示无过期时间（永久有效） |
| `credit_topup_expiry_end_datetime` | string | Credit 有效期结束时间，格式 `YYYY-MM-DD HH:MM:SS`，0 时为 null |
| `is_credit_topup_expired` | tinyint | 截至 `grass_date` 前该 credit 是否已过期（`end_datetime < grass_date`）：1=已过期，0=未过期 ⚠️ 该字段具有时效性，含义随分区日期变化，历史分区与最新分区值不同，应取最新分区判断当前状态 |
| `is_credit_topup_expired_today` | tinyint | 是否在 `grass_date` 当天过期（`date(end_datetime) = grass_date`）：1=是，0=否 |

---

### 维度：套餐（Package）信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `pckg_id` | bigint | SVS 套餐 ID，由 SVS 系统生成，仅 `order_type = 6` 时适用 |
| `ads_package_id` | bigint | ACP（Ads Credit Package）套餐 ID，由广告系统内部生成，仅 `order_type = 16` 时适用 |
| `pckg_expiry_timestamp` | bigint | 套餐到期时间（Unix 时间戳） |
| `pckg_expiry_datetime` | string | 套餐到期时间，格式 `YYYY-MM-DD HH:MM:SS` |

---

### 维度：优惠券（Voucher）信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `voucher_id` | bigint | 优惠券 ID |
| `voucher_expiry_timestamp` | bigint | 优惠券过期时间（Unix 时间戳） |
| `voucher_expiry_datetime` | string | 优惠券过期时间，格式 `YYYY-MM-DD HH:MM:SS` |

---

### 维度：免费 Credit 项目信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `credit_program_id` | bigint | 本次充值归属的活动/项目 ID |
| `credit_program_name` | string | 本次充值归属的活动/项目名称 |
| `credit_program_start_timestamp` | bigint | 项目/活动起始时间（Unix 时间戳） |
| `credit_program_start_datetime` | string | 项目/活动起始时间，格式 `YYYY-MM-DD HH:MM:SS` |

---

### 维度：人工充值（Manual Credit）审批信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `credit_reason` | string | 人工充值的审批原因，仅 `order_type in (3, 10, 14)` 时有值 |
| `credit_operator` | string | 上传充值/调整记录的操作人。对于 `order_type = 3` 或 `10`，为实际上传人；其他订单类型固定为 `'Auto'` |
| `operator` | string | 实际执行审批操作的人（如审批通过、拒绝、取消），来自 `ads_manual_topup_action_history_tab`，仅 `order_type in (3, 10, 14)` 时有值 |
| `action_type` | int | 人工充值操作类型枚举，仅 `order_type in (3, 10, 14)` 时有值。1=APPROVE、2=REJECT、3=CANCEL、4=UPLOAD |
| `manual_credit_create_timestamp` | bigint | 人工充值创建时间戳 |
| `manual_credit_create_datetime` | string | 人工充值创建时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `manual_credit_approved_timestamp` | bigint | 人工充值审批通过时间戳 |
| `manual_credit_approved_datetime` | string | 人工充值审批通过时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `manual_credit_effective_type` | int | 手动充值的 credit 用途属性，标记该人工充值对应的广告类型用途 |

---

### 维度：SVS 实体信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `svs_entity_type` | int | SVS 体系中充值主体类型。1=店铺（shop），3=MCN |
| `svs_entity_id` | bigint | SVS 体系中充值归属对象 ID。当 `svs_entity_type=1` 时为 `shop_id`，当 `svs_entity_type=3` 时为 `mcn_id`；字段为空时默认使用 `shop_id` |

---

### 维度：时间戳与修改记录

| 字段 | 类型 | 说明 |
|------|------|------|
| `topup_create_timestamp` | bigint | 充值订单创建时间戳（Unix 格式） |
| `topup_create_datetime` | string | 充值订单创建时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `credit_modify_timestamp` | bigint | Credit 记录最后修改时间戳 |
| `credit_modify_datetime` | string | Credit 记录最后修改时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `notified` | bigint | 通知状态标记 |

---

### 维度：扩展信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_credit_extinfo` | string | Ads Credit 额外信息，JSON 格式（由 UDF `decode_extinfo` 解码）。结构：`source`（来源）、`paid_amount`（初始付费 credit 金额）。⚠️ 为 JSON 字符串，使用时需通过 `get_json_object` 解析，不可直接聚合 |
| `seller_investment_amount` | double | 已废弃字段，来源于 `_decoded_extinfo`，请勿在新开发中使用 ⚠️ |

---

### 指标：充值金额（本地货币）

| 字段 | 类型 | 说明 |
|------|------|------|
| `topup_amt` | double | 充值金额，本地货币。⚠️ 对于套餐/优惠券充值，经 ETL 拆行处理，同一 `order_id` 可能对应两行（付费部分 + 免费部分），直接 SUM 会重复计算，需结合 `credit_topup_main_type` 过滤后再聚合 |
| `pckg_original_amt` | double | 套餐原始价格（卖家充值到账的金额），本地货币 |
| `pckg_paid_amt` | double | 套餐折后实付价格（卖家实际支付金额），本地货币 |
| `voucher_discount_amt` | double | 优惠券抵扣金额，本地货币 |
| `credit_balance_amt` | double | 该充值订单当前剩余余额（不含无有效期付费 credit），本地货币。⚠️ 该字段为当前快照值，具有时效性，反映 `grass_date` 当天的余额状态，历史分区值不代表当前余额 |

---

### 指标：充值金额（USD，当日汇率）

| 字段 | 类型 | 说明 |
|------|------|------|
| `topup_amt_usd` | double | 充值金额（USD），按 `grass_date` 当日汇率换算。⚠️ 同 `topup_amt`，套餐/优惠券充值经拆行处理，SUM 前需按 `credit_topup_main_type` 过滤 |
| `pckg_original_amt_usd` | double | 套餐原始价格（USD），按当日汇率换算 |
| `pckg_paid_amt_usd` | double | 套餐折后实付价格（USD），按当日汇率换算 |
| `voucher_discount_amt_usd` | double | 优惠券抵扣金额（USD），按当日汇率换算 |
| `credit_balance_amt_usd` | double | 充值订单剩余余额（USD），按当日汇率换算。⚠️ 同 `credit_balance_amt`，具有时效性，应取最新分区值 |

---

### 指标：充值金额（USD，历史汇率）

| 字段 | 类型 | 说明 |
|------|------|------|
| `topup_amt_usd_his` | double | 充值金额（USD），按充值创建日期的历史汇率换算。⚠️ 同 `topup_amt`，套餐/优惠券充值经拆行处理，SUM 前需按 `credit_topup_main_type` 过滤；此字段适合做历史趋势对比，避免汇率波动影响 |
| `pckg_original_amt_usd_his` | double | 套餐原始价格（USD），按充值创建日期历史汇率换算 |
| `pckg_paid_amt_usd_his` | double | 套餐折后实付价格（USD），按充值创建日期历史汇率换算 |
| `voucher_discount_amt_usd_his` | double | 优惠券抵扣金额（USD），按充值创建日期历史汇率换算 |
| `credit_balance_amt_usd_his` | double | 充值订单剩余余额（USD），按充值创建日期历史汇率换算。⚠️ 具有时效性，应取最新分区 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下三个分区字段，否则将引发全表扫描，导致严重的计算资源浪费和查询超时：

```sql
WHERE tz_type = 'local'           -- 必须，当前仅写入 local 分区
  AND grass_region = 'SG'         -- 必须，替换为目标地区
  AND grass_date = '2026-04-22'   -- 必须，替换为目标日期
```

- **`tz_type`**：当前 ETL 仅写入 `'local'` 分区，遗漏此条件将产生无效扫描。
- **`grass_region`**：本表覆盖所有地区，不过滤时将扫描全部地区数据。
- **`grass_date`**：本表为全量快照分区，不过滤时将扫描全部历史日期。

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确处理方式 |
|------|----------|--------------|
| `topup_amt` / `topup_amt_usd` / `topup_amt_usd_his` | 对于含套餐或优惠券的充值，ETL 将一笔充值拆为两行（付费部分 + 免费部分），同一 `order_id` 对应两条记录，直接 SUM 会重复计算 | 按 `credit_topup_main_type` 过滤（如 `= 2` 取付费、`= 3` 取免费）后再 SUM；或按 `order_id + credit_topup_main_type` 去重聚合 |
| `credit_balance_amt` / `credit_balance_amt_usd` / `credit_balance_amt_usd_his` | 余额为当前快照值，不同日期分区值不同，且 voucher 充值对应的余额行写入 null；多行余额不具加和意义 | 取最新 `grass_date` 分区查余额；若需要账户总余额，应按 `shop_id` 汇总非 null 值 |
| `ads_credit_extinfo` | JSON 字符串，不可直接聚合 | 使用 `get_json_object(ads_credit_extinfo, '$.source')` 等解析后再使用 |
| `is_credit_topup_expired` / `is_credit_topup_expired_today` | 标志字段，随 `grass_date` 变化，历史分区的值不反映当前状态 | 仅在当前最新分区使用该字段判断过期状态 |

### 时效性说明

- **余额字段**（`credit_balance_amt*`）：为各 `grass_date` 的快照余额，具有时效性。分析"当前未使用余额"时，应查询最新 `grass_date` 分区；历史分区的余额字段反映的是当时的余额状态。
- **过期标志字段**（`is_credit_topup_expired`）：基于 `grass_date` 与 `credit_topup_expiry_end_datetime` 的比较计算，历史分区中该字段为 0 的记录在更新分区中可能变为 1，务必取最新分区使用。
- **充值金额字段**（`topup_amt*`）：为充值发生时的金额，不随日期变化，历史分区与最新分区一致，可在任意分区查询。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_shopee_ads_db__topup_translog_tab_df__reg_s0_live` | 充值流水原始数据，提供 `order_id`、`order_type`、充值金额、套餐、优惠券等核心充值记录 |
| `mp_paidads.shopee_ads_${region}_ultimate_shard_db__ads_credit_tab__reg_continuous_s0_live` | Ads Credit 明细表，提供 credit 金额、余额、有效期、子类型、extinfo 等字段 |
| `mp_paidads.shopee_ads_${region}_ultimate_shard_db__promotion_paid_ads_manual_credit_tab__reg_continuous_s0_live` | 人工充值/调整明细，提供审批人、原因、项目信息、manual credit 类型等 |
| `mp_paidads.shopee_ads_${region}_central_db__promotion_paid_ads_manual_credit_subtype_tab__reg_continuous_s0_live` | 充值子类型映射表，提供 `sub_type_id` 到 `sub_type_name` 的映射 |
| `mp_paidads.dim_translog_order_type_mapping__reg_s0_live` | 订单类型枚举映射维表，提供 `order_type` 到 `order_type_name` 的映射 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供 `grass_date` 当日汇率及历史各日汇率，用于本地货币换算 USD |
| `mp_paidads.shopee_ads_${region}_ultimate_shard_db__ads_manual_topup_action_history_tab__reg_continuous_s0_live` | 人工充值操作历史，提供最近一次操作的 `operator` 和 `action_type` |

---

## ETL 逻辑摘要

### 数据流

```
ods_shopee_ads_db__topup_translog_tab_df          (充值流水原始数据)
    │
    ├─── LEFT JOIN dim_translog_order_type_mapping  (订单类型名称补全)
    │
    └──► CTE: topup (充值主体信息)
              │
              ├─── LEFT JOIN CTE: manual ◄──── promotion_paid_ads_manual_credit_tab (人工充值详情)
              │                         ◄──── CTE: subtype ◄── promotion_paid_ads_manual_credit_subtype_tab
              │
              ├─── LEFT JOIN CTE: credit ◄──── ads_credit_tab (Credit 明细/余额/有效期)
              │                         ◄──── CTE: subtype (子类型名称)
              │
              ├─── LEFT JOIN CTE: exrate ◄──── dim_exchange_rate (当日汇率)
              │
              ├─── LEFT JOIN CTE: exrate_his ◄─ dim_exchange_rate (历史汇率，按充值日期匹配)
              │
              └──► CTE: topup_credit (充值宽表，含金额换算)
                        │
                        ├── 第一部分：所有充值记录（付费部分 / 非拆行记录）
                        │   CASE 计算 topup_amt_split / credit_topup_type_split 等
                        │
                        └── UNION ALL
                            │
                            └── 第二部分：套餐/优惠券免费部分拆行
                                （仅 credit_topup_main_type=5 且 is_package_topup=1 且折扣>0，
                                 或 is_voucher_topup=1 且 voucher_discount_amt>0）
                                    │
                                    └──► LEFT JOIN manual_topup_action ◄── ads_manual_topup_action_history_tab
                                              (取最新一次审批操作，ROW_NUMBER rank=1)
                                                   │
                                                   ▼
                              INSERT OVERWRITE dwd_advertiser_credit_topup_df__reg_s0_live
                              partition(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `topup` | `ods_shopee_ads_db__topup_translog_tab_df` + `dim_translog_order_type_mapping` | 读取充值流水原始记录，完成金额单位换算（÷100000）、时间戳转日期字符串、订单类型名称关联；过滤 `order_id > 0` 及 `order_time < 次日零点` |
| `subtype` | `promotion_paid_ads_manual_credit_subtype_tab` | 聚合充值子类型映射（`FIRST` 取名称，按 `id` GROUP BY），供 `manual` 和 `credit` 两个 CTE 复用 |
| `manual` | `promotion_paid_ads_manual_credit_tab` + `subtype` | 读取人工充值/调整记录，关联子类型名称，输出审批信息、项目信息、credit 类型等；过滤 `ctime <= 次日零点` |
| `credit` | `ads_credit_tab` + `subtype` | 读取 Ads Credit 余额明细，完成金额换算、有效期处理（end_time=0 转 null）、extinfo 解码（UDF）、过期标志计算；过滤 `ctime <= 次日零点` |
| `exrate` | `dim_exchange_rate` | 取 `grass_date` 当日汇率，用于当日金额换算（`topup_amt_usd` 等） |
| `exrate_his` | `dim_exchange_rate` | 取全量历史汇率，按充值创建日期匹配（`topup_create_datetime` 前 11 位 = `grass_date`），用于历史口径金额换算（`*_usd_his` 字段） |
| `topup_credit` | topup + manual + credit + exrate + exrate_his | 核心宽表 JOIN，整合充值、人工 credit、余额、汇率信息；执行套餐/优惠券金额拆分逻辑；`UNION ALL` 拼接免费部分拆行记录 |
| `manual_topup_action` | `ads_manual_topup_action_history_tab` | 取每笔人工充值最近一次操作记录（`ROW_NUMBER() OVER(PARTITION BY credit_id ORDER BY ctime DESC) = 1`），输出 `operator` 和 `action_type` |

### 注意事项

1. **套餐/优惠券充值拆行机制**：当一笔充值同时包含付费部分和免费部分时（ACP 套餐折扣 `pckg_original_amt - pckg_paid_amt > 0`，或优惠券 `voucher_discount_amt > 0`），ETL 通过 `UNION ALL` 将其拆为两行写入：第一行记录付费部分（`credit_topup_main_type = 2`），第二行记录免费部分（`credit_topup_main_type = 3`）。因此，**同一 `order_id` 在本表中可能存在两行**，对充值金额求 SUM 前务必按 `credit_topup_main_type` 明确过滤，否则会产生重复计算。

2. **汇率两套口径**：`*_usd` 字段使用 `grass_date` 当日汇率（`exrate`），适合看当日货币换算值；`*_usd_his` 字段使用充值发生当天的历史汇率（`exrate_his`），适合跨时期横向对比，排除汇率波动干扰。两套口径不可混用。

3. **`order_type = 10`（调整）金额符号**：ETL 中对 `order_type = 10` 的充值金额乘以 `-1.0`，即调整类型的 `topup_amt` 可能为负值，代表扣减操作，聚合时需注意。

4. **已废弃字段**：`ads_revenue_push_type`、`seller_investment_type` 在 ETL 中显式赋值为 `null`；`seller_investment_amount` 虽有计算逻辑但字段注释标注为 deprecated，三个字段均不建议在新开发中使用。

5. **`credit_balance_amt` 的 null 值**：对于优惠券充值（`is_voucher_topup = 1 AND voucher_discount_amt > 0`）的免费拆行部分，`credit_balance_amt`、`credit_balance_amt_usd`、`credit_balance_amt_usd_his` 被显式赋值为 null，不代表余额为零。

6. **`credit_operator` 字段语义**：该字段对 `order_type in (3, 10)` 记录上传人，其他所有类型固定为字符串 `'Auto'`，不代表真实操作人，请勿用于人工操作的统计过滤。

7. **数据截止时间**：各上游表均过滤 `ctime/order_time < UNIX_TIMESTAMP(DATE_ADD(grass_date, 1))`，即仅包含截至 `grass_date` 次日零点（本地时区）前的记录，当天最后时段数据若有延迟可能在次日分区中才完整体现。

---

*文档生成时间：2026-04-22*