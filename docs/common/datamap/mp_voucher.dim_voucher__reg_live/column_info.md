<!-- ads-workspace-gdoc-sync: gdoc_id=1QLnEUDhZOyxdlxfXsEM6N8zJWQPHcyCPrfHVYQ-dDXY gdoc_url=https://docs.google.com/document/d/1QLnEUDhZOyxdlxfXsEM6N8zJWQPHcyCPrfHVYQ-dDXY/edit -->

# Columns: mp_voucher.dim_voucher__reg_live

> **Contributors**: roger.li ｜ **最后更新**：2026-06-10 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/datamap/mp_voucher.dim_voucher__reg_live/column_info.md)

共 69 字段；下表只列**分析高频 / 口径关键**字段。完整字段用 `SELECT * ... LIMIT 1` 获取。

## Key / Identity 列

| Column | Type | Description | Query Note |
|---|---|---|---|
| `promotion_id` | bigint | voucher promotion 唯一 ID | **Join key**：↔ unified order `pv_promotion_id` / `sv_promotion_id` |
| `voucher_name` | varchar | 券名称 | 形如 `SIP-PH-SG-88-SSV-1` |
| `grass_date` | date | 每日快照分区 | 必过滤 |
| `grass_region` | varchar | 地区 | 表已按地域分物理表，此列冗余 |
| `tz_type` | varchar | 时区类型 | `local` |

## Classification / 分类标志位（核心）

| Column | Type | Description |
|---|---|---|
| `is_smart_reg_voucher` | tinyint | **=1 即 MP 中心化非local smart 券**（PV + shopee 出资）。识别「他们的券」就用这个 |
| `is_smart_ads_voucher` | tinyint | **=1 即广告 smart 券（我们的 ads 券）**，SV 类型 |
| `is_smart_seller_voucher` | tinyint | =1 seller smart 券 |
| `is_smart_voucher` | tinyint | smart 券总标志 |
| `is_seller_voucher` | tinyint | 是否 seller 券 |
| `voucher_groups` | array&lt;string&gt; | 文本分组标签；`'Reg Smart Voucher*'` ≡ `is_smart_reg_voucher=1`（实测完全相等）。**优先用 flag** |
| `voucher_business_line` | varchar | `BUSINESS_LINE_MP` 等 |
| `voucher_business_domain` | varchar | `BUSINESS_DOMAIN_MARKETPLACE` 等 |
| `voucher_status` | varchar | `PROMOTION_STATUS_ENABLED` 等 |

## Funding & Type / 出资方与类型（`mp_voucher_settings` 嵌套 row）

| Field | Type | Description |
|---|---|---|
| `mp_voucher_settings.mp_voucher_type` | varchar | `PV`（平台券）/ `SV`（seller券）/ `FSV`（免邮券）。**MP reg smart 券=PV，ads 券=SV** |
| `mp_voucher_settings.is_mp_plaform_voucher` | tinyint | 是否 MP 平台券（注意拼写 `plaform`） |
| `mp_voucher_settings.is_shopee_absorbed` | tinyint | Shopee 出资。MP reg smart 券 100%=1 |
| `mp_voucher_settings.is_seller_absorbed` | tinyint | seller 出资 |
| `mp_voucher_settings.is_external_absorbed` | tinyint | 外部出资 |
| `mp_voucher_settings.is_voucher_cofunded` | tinyint | 是否 cofund；`voucher_cofund_rules` 含分摊方/比例/上限 |

## Reward / 折扣规则（面额，`voucher_reward_settings` 嵌套 row）

| Field | Type | Description |
|---|---|---|
| `voucher_reward_settings.fixed_discount_amt` | decimal | 固定立减额 |
| `voucher_reward_settings.discount_pct` | decimal | 折扣百分比 |
| `voucher_reward_settings.discount_cap_amt` | decimal | 折扣封顶额 |
| `voucher_reward_settings.min_spend_amt` | decimal | 最低消费门槛 |
| `voucher_reward_settings.max_reward_cash_value_amt` | decimal | 最大现金价值 |

> 注意：reward 是**券面额规则**，不是实际花费。实际花费看订单端 `pv_rebate_*` / `sv_rebate_*`。

## Quota & Budget / 配额与预算（`voucher_quota_settings` 嵌套 row）

| Field | Type | Description |
|---|---|---|
| `voucher_quota_settings.max_cost_of_voucher_promotion` | decimal | **券预算上限（planned）**；很可能是外部 PRM 计划表口径，**≠ 实际 redeem** |
| `voucher_quota_settings.user_voucher_usage_cnt` | bigint | 用户核销数 |
| `voucher_quota_settings.approved_user_voucher_usage_quota_cnt` | bigint | 批准核销配额 |

## 其他可用嵌套规则

`product_usage_rules`（适用商品）、`user_usage_rules`（适用人群 / 新客 / 会员 / segment）、`payment_usage_rules`（支付方式）、`logistics_usage_rules`（物流）、`fe_display_settings`（前端展示）、`voucher_usage_start/end_timestamp`（生效时间窗）。需要时按名取。

## Column Usage Notes (from-code, 2026-06-15)

### 常见 WHERE 值 (Common Filter Values)

从 172 个代码引用中提取的高频过滤值：

- `grass_date`: `date('${grass_date}')` / `date '${BIZ_YESTERDAY}'` — 几乎全是当日或昨日
- `grass_region`: `upper('${region}')` 或 `'${upper_region}'` — 标准化 8 区，偶尔单个区域如 `'SG'`、`'BR'`
- `tz_type`: `'local'` — 约 90% 查询使用
- `is_seller_voucher`: `1` — 仅关注商家券（包含广告券）
- `array_contains(voucher_groups, 'ADS-ROI')` — 最核心条件，出现在 ~60% 的引用中
- `status`: `1` — 仅有效券
- `voucher_groups is not null` — 排除无标签组

### 代码中使用的列 (Columns Used in Code)

以下为在 studio_tasks SQL 中被实际引用的列（按频率排序）：

| Column | 使用模式 |
|--------|----------|
| `promotion_id` | 核心 JOIN key，常 cast 为 bigint；用于关联订单/click 中的 voucher_id |
| `voucher_groups` | array_contains / element_at / contains 检查；最常用于判断 `ADS-ROI` |
| `grass_date` | 必带分区过滤 |
| `grass_region` | 必带分区过滤 |
| `tz_type` | 绝大多数用 'local' |
| `is_seller_voucher` | 区分平台券(0) vs 商家券(1，含广告券) |
| `status` | = 1 过滤有效券 |
| `voucher_reward_settings` | 取 discount_cap_amt / fixed_discount_amt / min_spend_amt |
| `mp_voucher_settings` | 取 mp_voucher_type (PV/SV/FSV) |
| `rewards` | 取 reward_sub_type_id / value_cap_usd / discount_amt_usd |
| `reward_type` | = 'normal_voucher' 过滤普通券 |
| `discount_amt` | * 100000 得到 voucher_price (原生单位) |
| `voucher_usage_end_timestamp` | 券有效期检查 |
| `shop_id` | 在部分 JOIN 中用于多键匹配 |
| `is_smart_ads_voucher` | 直接 flag 判断广告券（优于 array_contains 字符串匹配） |
| `is_smart_reg_voucher` | 直接 flag 判断 MP 中心化非local smart 券 |
