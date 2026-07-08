<!-- ads-workspace-gdoc-sync: gdoc_id=1Eb7bTPLOOA00LHYiBtCJBZae0czEu1cHI29CwpDGIyo gdoc_url=https://docs.google.com/document/d/1Eb7bTPLOOA00LHYiBtCJBZae0czEu1cHI29CwpDGIyo/edit -->

# mp_paidads.dwd_advertiser_program_incentive_credit_df

**分层**：DWD（数据明细层）
**主键**：`shop_id × segment_id × program_id × granted_credit_order_id`（旧流）/ `shop_id × program_id × incentive_id`（新流）
**分区**：`tz_type / grass_region / grass_date`
**更新频率**：每日（T+1，覆盖昨日业务日期）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表存储广告主**激励计划（Incentive Program）信用额度（Credit）发放明细**，记录每个卖家在每个激励项目下的参与状态、信用奖励发放情况及相关消费/充值进度。表中数据来源于两套数据流：一是基于 `dim_advertiser_segment_program` 的旧流（old flow），二是基于新激励节点服务 `incentive_node_tab` 的新流（new flow），二者通过 `UNION ALL` 合并写入，覆盖全部激励项目类型。

表的核心使用场景包括：激励计划完成率分析、信用额度发放金额统计、卖家充值/消费达标进度追踪、ACP（广告信用礼包）购买与库存监控，以及各类激励项目（Cashback Onboarding、固定多层、复合型、自动充值等）的精细化运营分析。

表粒度为**卖家 × 细分项目 × 计划 × 信用发放订单**（旧流），或**卖家 × 计划 × 激励节点**（新流）。各地区按本地时区参数化调度写入，所有货币金额均同时提供本地货币和 USD 两个版本，USD 版本由当日汇率折算得出。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区键，当前仅写入 `'local'`（各地区本地时区） |
| `grass_region` | string | 地区分区键，大写区域代码（如 `'MX'`、`'TH'`） |
| `grass_date` | date | 业务日期分区键，格式 `yyyy-MM-dd`，对应 `BIZ_YESTERDAY` |

---

### 维度：主键与核心标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 卖家店铺 ID |
| `segment_id` | bigint | 细分市场 ID；新流数据此字段为 NULL |
| `program_id` | bigint | 激励计划 ID |
| `incentive_id` | bigint | 新激励服务中的激励节点 ID；旧流中由 `dim_advertiser_segment_program` 透传 |
| `package_id` | bigint | ACP（广告信用礼包）的 package ID；仅 `program_type=8` 有值，新流数据为 NULL |

---

### 维度：计划基本信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `program_name` | string | 激励计划名称 |
| `program_type` | int | 激励计划类型枚举值（见下方说明）⚠️ 不同 `program_type` 对应的有效字段集合不同，需结合类型判断可用字段 |
| `program_type_name` | string | 激励计划类型名称（字符串描述）；旧流数据此字段固定为 NULL，仅新流有值 |
| `program_status` | bigint | 计划状态枚举值，含义见上游枚举定义 |
| `owner_operator_type` | int | 计划运营方类型；新流数据为 NULL |
| `program_extinfo` | string | 计划扩展信息（JSON 字符串），旧流来自 `extinfo` 列，新流同名字段透传 |
| `learn_more_link` | string | 指向计划条款详情页的链接；新流数据为 NULL |
| `priority_score` | bigint | 卖家中心首页任务卡片展示优先级分数（最多展示 3 张）；新流数据为 NULL |
| `popup_score` | bigint | 弹窗展示评分；新流数据为 NULL |
| `is_dismissed` | boolean | 卖家是否已关闭奖励中心的计划卡片；新流数据为 NULL |
| `is_auto_claim` | boolean | 是否自动领取；从 `extinfo.incentive.is_auto_claim` 解析；新流数据为 NULL |

> **`program_type` 枚举说明**：1=QSS、2/3/4=通用激励(Incentive)、5=Cashback Onboarding、6/9=Cashback Multi、7/10=Fixed Multi、8=ACP（广告信用礼包）、11=Cashback Compound、12=Fixed Compound、13=Auto Topup、14=Topup Multi

---

### 维度：计划时间信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `program_start_timestamp` | bigint | 计划开始时间（Unix 时间戳，秒） |
| `program_start_datetime` | string | 计划开始时间（本地时区，格式 `yyyy-MM-dd HH:mm:ss`） |
| `program_end_timestamp` | bigint | 计划结束时间（Unix 时间戳，秒） |
| `program_end_datetime` | string | 计划结束时间（本地时区，格式 `yyyy-MM-dd HH:mm:ss`） |
| `display_timestamp` | bigint | 计划在卖家中心可展示的时间（Unix 时间戳），可早于计划开始时间用于预热；新流数据为 NULL |
| `display_datetime` | string | `display_timestamp` 的本地时区可读格式；新流数据为 NULL |
| `deadline_timestamp` | bigint | 计划完成截止时间（Unix 时间戳）；对于 Cashback Onboarding 计划，此为卖家进度结束时间；新流数据为 NULL |
| `deadline_datetime` | string | `deadline_timestamp` 的可读格式；新流数据为 NULL |

---

### 维度：卖家参与状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_program_status_id` | bigint | 卖家在该计划中的状态 ID（枚举值，含义见上游定义）；新流数据为 NULL |
| `seller_program_status` | string | 卖家在该计划中的状态（字符串描述）；新流数据为 NULL |
| `sign_up_timestamp` | bigint | 算法侧成功将卖家加入计划的时间（Unix 时间戳，秒）；新流数据为 NULL |
| `sign_up_datetime` | string | `sign_up_timestamp` 的本地时区可读格式；新流数据为 NULL |
| `completion_timestamp` | bigint | 卖家完成计划的时间戳（Unix 时间戳，秒）；新流中取所有节点 `completion_timestamp` 的最大值 |
| `completion_datetime` | string | 由 `completion_timestamp` 通过 `from_unixtime` 转换生成的可读格式 ⚠️ 为派生字段，勿单独修改或比较原始时间戳时注意时区 |
| `first_tier_completion_timestamp` | bigint | 卖家完成第一档（tier）的时间戳；旧流从 `base.first_tier_completion_time` 解析，新流取所有节点 `completion_timestamp` 最小值 |
| `is_dismissed` | boolean | （见上方维度：计划基本信息） |

---

### 维度：广告投放设置

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_placements` | array\<int\> | 广告位列表 ⚠️ 已废弃（DDL 注释 `DEPRECATED`），请使用 `incentive_ads_placement` 替代；新流数据为 NULL |
| `incentive_ads_placement` | int | 激励计划适用的广告位，映射到一个或多个 AdsPlacement，默认值 0 表示全部；新流数据为 NULL |
| `trigger_campaign_id` | bigint | 触发计划的广告活动 ID，从 `cashback_onboarding_info.ads_trigger.trigger_campaign_id` 解析；新流数据为 NULL |
| `trigger_time` | bigint | 触发时间戳，从 `cashback_onboarding_info.ads_trigger.trigger_time` 解析；新流数据为 NULL |
| `unread_ads` | boolean | 是否有未读广告，从 `qss_info.unread_ads` 解析；新流数据为 NULL |
| `ads_creation_try` | int | 广告创建尝试次数，从 `qss_info.ads_creation_try` 解析；新流数据为 NULL |
| `ads_creation_time` | bigint | 广告创建时间戳，从 `qss_info.ads_creation_time` 解析；新流数据为 NULL |

---

### 维度：各类型激励专属扩展信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `cashback_onboarding_info` | string | Cashback Onboarding 激励详情（JSON），仅 `program_type=5` 有效；新流数据为 NULL |
| `cashback_multi_info` | string | Cashback Multi 激励详情（JSON），仅 `program_type∈{6,9}` 有效；新流数据为 NULL |
| `fixed_multi_info` | string | Fixed Multi 激励详情（JSON），仅 `program_type∈{7,10}` 有效；新流数据为 NULL |
| `cashback_compound_info` | string | Fixed Cashback Compound 激励详情（JSON），仅 `program_type=11` 有效；新流数据为 NULL |
| `fixed_compound_info` | string | Fixed Compound 激励详情（JSON），仅 `program_type=12` 有效；新流数据为 NULL |
| `auto_topup_info` | string | Auto Topup 激励详情（JSON），仅 `program_type=13` 有效；新流数据为 NULL |
| `ads_credit_package_info` | string | ACP（广告信用礼包）详情（JSON），仅 `program_type=8` 有效；新流数据为 NULL |

---

### 维度：ACP（广告信用礼包）专属字段

> 以下字段仅 `program_type = 8` 时有意义，新流数据均为 NULL

| 字段 | 类型 | 说明 |
|------|------|------|
| `original_price` | double | 礼包原价（等于卖家获得的 paid+free 总信用额，本地货币）；从 `ads_credit_package_info.package.original_price` 解析，原始值 ÷ 100000 |
| `discount_price` | double | 折扣价（等于卖家实际支付的 paid credit，本地货币）；从 `ads_credit_package_info.package.discount_price` 解析，原始值 ÷ 100000 |
| `discount_percentage` | double | 折扣比例，计算公式：`(original_price - discount_price) / original_price`；从 `ads_credit_package_info.package.discount_percentage` 解析，原始值 ÷ 100000 ⚠️ 为预计算比率，不可直接 SUM，需用分子/分母重新计算 |
| `expiry_type` | int | 礼包过期类型：`1=END_TIME`（Unix 时间戳），`2=DAYS`（天数） |
| `expiry_days` | int | 固定过期天数，仅 `expiry_type=2` 时有效 |
| `expiry_time` | bigint | 具体过期时间（Unix 时间戳，秒），仅 `expiry_type=1` 时有效 |
| `is_deactivated` | boolean | ACP 是否已停用（`true` 表示 Disable，该 ACP 无效且不展示） |
| `is_oos` | boolean | 是否已达到库存上限（缺货） |
| `shop_total_stock` | bigint | 该卖家可购买的最大数量（从 `ads_package_tab` 的 `shop_level_total_stock` 解析） |
| `shop_used_stock` | bigint | 该卖家已完成的订单数（`total_order_done`） |

---

### 维度：Auto Topup 专属字段

> 以下字段仅 `program_type = 13` 时有意义

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_atu_on_before` | boolean | 卖家在参与期间是否曾开启过 Auto Topup；从 `auto_topup_info.is_atu_on_before` 解析；新流数据为 NULL |
| `target_topup_tiers` | string | Auto Topup 激励的目标充值档位详情；旧流从 `topup.target_topup_tiers` 解析，新流从 `incentive_node_tab` 的 `cond_accumulate_topup.config.objective` 解析（类型为 string） |

---

### 指标：信用额度发放

| 字段 | 类型 | 说明 |
|------|------|------|
| `granted_credit_amount` | double | 计划完成后发放给卖家的免费信用额（本地货币）；旧流原始值 ÷ 100000，新流从 `incentive_node_tab` 汇总 SUM |
| `granted_credit_amount_usd` | double | `granted_credit_amount` 除以当日汇率的 USD 换算值 ⚠️ 为派生字段（本地货币 / 汇率），不可独立 SUM，如需跨地区汇总应重新关联汇率 |
| `granted_credit_order_id` | bigint | 信用发放订单 ID（单笔）；旧流字段，新流数据为 NULL |
| `granted_credit_order_ids` | array\<bigint\> | 信用发放订单 ID 列表（多笔）；新流从 `incentive_node_tab` 通过 `collect_list` 聚合；旧流数据为 NULL |
| `uncapped_credit_amount` | double | 未经上限限制的信用额（本地货币），从 `credit_reward.uncapped_credit_amount` 解析，原始值 ÷ 100000；新流数据为 NULL |
| `uncapped_credit_amount_usd` | double | `uncapped_credit_amount` 的 USD 换算值 ⚠️ 派生字段，不可独立 SUM |
| `credit_amount_cap` | double | 信用额上限（本地货币），0 表示不设上限；从 `credit_reward.credit_amount_cap` 解析，原始值 ÷ 100000；新流数据为 NULL |
| `credit_amount_cap_usd` | double | `credit_amount_cap` 的 USD 换算值 ⚠️ 派生字段，不可独立 SUM |
| `credit_effective_type` | int | 信用额适用范围枚举：`0=UNIVERSAL`（除展示广告外全部广告）、`1=PRODUCT_ROI_TWO`（手动商品广告 ROI2 竞价）、`2=CREDIT_LIVE_STREAM`、`3=CREDIT_SEARCH_BRAND`；新流数据为 NULL |
| `credit_expiry_duration` | bigint | 信用额过期时长（秒），从 `credit_reward.credit_expiry_duration` 解析；新流数据为 NULL |
| `credit_claim_period` | bigint | 信用额领取有效期，从 `base.credit_claim_period` 解析；新流数据为 NULL |
| `credit_inject_time` | bigint | 信用额注入时间戳，从 `qss_info.credit_inject_time` 解析；新流数据为 NULL |
| `credit_consumption_type` | int | 信用消耗类型，从 `extinfo.incentive.credit_consumption_type` 解析；新流数据为 NULL |

---

### 指标：消费目标进度

> 以下字段仅消费类计划（`program_type∈{2,3,4,5,6,7,9,10,11,12}` 等）有效，新流数据均为 NULL

| 字段 | 类型 | 说明 |
|------|------|------|
| `spending_amount` | double | 累计广告消费金额（本地货币），从计划开始记录，按日更新；原始值 ÷ 100000 ⚠️ 为每日快照的累计值，不可跨分区 SUM |
| `spending_amount_usd` | double | `spending_amount` 的 USD 换算值 ⚠️ 累计派生字段，不可跨分区 SUM |
| `target_spending_tiers` | string | 消费激励各档位详情（JSON），原始值以 10^5 倍存储 ⚠️ 金额字段以 10^5 倍膨胀存储，使用时须 ÷ 100000 |
| `baseline_amount` | double | 基准消费金额（本地货币），原始值 ÷ 100000；新流数据为 NULL |
| `spending_period` | bigint | 消费考核周期（秒）；新流数据为 NULL |
| `spending_start_time` | bigint | 消费统计开始时间（Unix 时间戳），已归一化到当日 00:00；新流数据为 NULL |
| `spending_end_time` | bigint | 消费统计结束时间（Unix 时间戳）；新流数据为 NULL |
| `last_spending_timestamp` | bigint | 最近一次消费记录时间戳；新流数据为 NULL |

---

### 指标：充值目标进度

> 以下字段仅充值类计划（`program_type∈{1,2,3,4,13,14}` 等）有效

| 字段 | 类型 | 说明 |
|------|------|------|
| `topup_amount` | double | 自参与以来的累计充值金额（本地货币），原始值 ÷ 100000；新流从进度列表 `progress_list.amount` 聚合 SUM ⚠️ 为累计快照值，不可跨日期分区 SUM |
| `topup_amount_usd` | double | `topup_amount` 的 USD 换算值 ⚠️ 累计派生字段，不可跨分区 SUM |
| `topup_target_amount` | double | 充值目标金额（本地货币），达到该值则触发奖励；原始值 ÷ 100000；新流数据为 NULL |
| `topup_target_amount_usd` | double | `topup_target_amount` 的 USD 换算值 ⚠️ 派生字段，不可独立 SUM |
| `topup_reward_amount` | double | 充值奖励金额（本地货币），原始值 ÷ 100000；新流数据为 NULL |
| `topup_reward_amount_usd` | double | `topup_reward_amount` 的 USD 换算值 ⚠️ 派生字段，不可独立 SUM |
| `topup_order_ids` | array\<bigint\> | 触发充值任务履约的充值事件 ID 列表；新流从 `progress_list.topup_order_ids` flatten 后聚合 |
| `topup_orders` | bigint | 充值订单数量，从 `qss_info.topup_orders` 解析；新流数据为 NULL |
| `topup_target_amount` | double | （同上） |
| `last_topup_timestamp` | bigint | 最近一次充值时间戳，从 `topup.last_topup_timestamp` 解析；新流数据为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须显式指定以下分区字段**，否则会触发全表扫描，导致查询超时或资源浪费：

| 分区字段 | 推荐用法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `WHERE tz_type = 'local'` | 当前只有 `local` 分区，但不过滤会导致分区裁剪失效 |
| `grass_region` | `WHERE grass_region = 'XX'`（大写区域代码） | 扫描所有地区数据，性能严重下降 |
| `grass_date` | `WHERE grass_date = '${target_date}'` | 扫描全部历史分区，产生重复计数 |

**推荐过滤模板**：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'TH'   -- 替换为目标地区大写代码
  AND grass_date = '2026-04-21'
```

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确做法 |
|------|----------|----------|
| `discount_percentage` | 预计算比率，直接 SUM 无意义 | 使用 `SUM(original_price - discount_price) / SUM(original_price)` 重新计算 |
| `granted_credit_amount_usd` / `spending_amount_usd` / `topup_amount_usd` / `credit_amount_cap_usd` / `uncapped_credit_amount_usd` / `topup_target_amount_usd` / `topup_reward_amount_usd` | 由本地货币 / 汇率派生，不同地区汇率不同，跨地区混合 SUM 结果错误 | 保持在同一 `grass_region` 内聚合，或重新关联 `dim_exchange_rate` 统一折算 |
| `spending_amount` / `topup_amount` | 累计快照值，每日分区存储的是截止当日的历史累计数，跨分区 SUM 会重复计数 | 仅取**单一日期分区**的最新快照值，不跨分区 SUM |
| `target_spending_tiers` | JSON 字符串内金额以 10^5 倍存储 | 解析 JSON 后的金额字段需 ÷ 100000 |

### 时效性说明

- 本表每日 T+1 覆盖写入（`INSERT OVERWRITE`），**每个 `grass_date` 分区对应该日业务快照**。
- `spending_amount`、`topup_amount` 等累计字段，每日更新当前分区的累计值（从计划开始时记录），分析时应**取最新的 `grass_date` 分区**以获取最新进度，而非对多个分区求和。
- `completion_datetime` 由 ETL 实时从 `completion_timestamp` 转换生成，**不代表数据写入时间**。
- 新流（`program_type_name IS NOT NULL`）与旧流（`program_type_name IS NULL`）共存于同一分区，大量字段在新流中为 NULL，查询时建议先用 `program_type_name IS NULL/IS NOT NULL` 区分数据来源，避免混淆。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertiser_segment_program__reg_s0_live` | 旧流/新流共用的卖家-计划维表，提供计划基本信息、卖家参与状态及 `seller_program_extinfo` 扩展字段 |
| `mp_paidads.shopee_ads_${region}_db__ads_package_tab__reg_continuous_s0_live` | ACP 礼包库存信息，提供 `shop_level_total_stock` 和 `total_order_done`；仅旧流 join |
| `mp_paidads.shopee_ads_srm_${region}_db__incentive_node_tab__reg_continuous_s0_live` | 新激励服务的激励节点明细表，提供信用发放、充值进度等精细化状态；仅新流使用 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 当日汇率维表，用于将本地货币金额换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
dim_advertiser_segment_program__reg_s0_live
        │
        ├──[program_type IS NOT NULL]──► dim_seller_program (temp view)
        │                                       │
        │              ┌─────────────────────────┤
        │              │                         │
        │   [旧流 old_flow_data]        [新流 new_flow_data]
        │              │                         │
        │   shopee_ads_${region}_db              │
        │   __ads_package_tab                    │
        │   (LEFT JOIN on package_id)            │
        │              │                shopee_ads_srm_${region}_db
        │              │                __incentive_node_tab
        │              │                (LEFT JOIN on incentive_id,
        │              │                 按 incentive_id 聚合:
        │              │                 SUM/collect_list/min/max)
        │              │                         │
        │   dim_exchange_rate            dim_exchange_rate
        │   (LEFT JOIN for USD)          (LEFT JOIN for USD)
        │              │                         │
        └──────────────┴──── UNION ALL ──────────┘
                                │
                     INSERT OVERWRITE
                                │
        dwd_advertiser_program_incentive_credit_df__reg_s0_live
                  PARTITION(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE / Temp View | 来源表 | 作用 |
|-----------------|--------|------|
| `dim_seller_program` | `dim_advertiser_segment_program__reg_s0_live` | 过滤目标地区和业务日期，提取卖家-计划维度信息及 `package_id`（从 `seller_program_extinfo.acp.package.package_id` 解析） |
| `old_flow_data` | `dim_seller_program` + `ads_package_tab` + `dim_exchange_rate` | 处理旧数据流（`program_type IS NOT NULL`）：解析 `seller_program_extinfo` 各子节点 JSON，提取消费/充值/信用/ACP/ATU 等字段，并做 ÷100000 单位还原和 USD 换算 |
| `new_flow_data` | `dim_seller_program` + `incentive_node_tab` + `dim_exchange_rate` | 处理新激励服务数据流（`program_type_name IS NOT NULL`）：从 `incentive_node_tab` 按 `incentive_id` 聚合信用发放和充值进度，与计划维表 join 后输出，大量字段置 NULL |

### 注意事项

1. **双流并存**：旧流（`old_flow_data`）与新流（`new_flow_data`）以 `UNION ALL` 合并，同一 `grass_date` 分区内两类数据共存。旧流以 `program_type IS NOT NULL` 过滤，新流以 `program_type_name IS NOT NULL` 过滤，二者在 `dim_seller_program` 层面互斥（`program_type` 与 `program_type_name` 非空条件不同）。查询时可用 `program_type_name IS NULL` 识别旧流记录，`program_type_name IS NOT NULL` 识别新流记录。

2. **金额单位还原**：原始系统中金额以整数 × 10^5 存储，ETL 中通过 `÷ 100000` 还原为实际金额。`target_spending_tiers`（JSON 字符串内嵌金额）**未在 ETL 层还原**，使用时需在应用层自行 ÷ 100000。

3. **USD 换算依赖汇率表**：所有 `_usd` 后缀字段均为 `本地货币 / 当日汇率`，若汇率表当日数据缺失（LEFT JOIN 结果为 NULL），对应 USD 字段将为 NULL，不会报错但数据丢失。

4. **`ads_placements` 已废弃**：DDL 中明确注释 `DEPRECATED; use incentive_ads_placement`，新代码不应读取 `ads_placements`，应改用 `incentive_ads_placement`。

5. **新流字段大量为 NULL**：新流记录中，`segment_id`、`display_timestamp`、`sign_up_timestamp`、`priority_score`、`seller_program_status` 等大量字段固定为 NULL，分析时需注意聚合空值处理。

6. **`incentive_node_tab` 时间过滤**：新流在读取 `incentive_node_tab` 时使用 `ctime < unix_timestamp(date_add(date('${BIZ_YESTERDAY}'), 1))`，即只取截止昨日末的数据，确保数据时效一致性。

7. **各地区参数化调度**：SQL 中的 `${region}`、`${timezone}`、`${BIZ_YESTERDAY}` 均为调度模板参数，各地区独立调度写入对应的 `grass_region` 分区，`tz_type='local'` 表示各地区按本地时区处理。

---

*文档生成时间：2026-04-22*