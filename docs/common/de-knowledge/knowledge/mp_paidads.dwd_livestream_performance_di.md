<!-- ads-workspace-gdoc-sync: gdoc_id=1zwHiwqhqSeGnti2vslneVW5r0H-29mTfQzfcvOdSn7Q gdoc_url=https://docs.google.com/document/d/1zwHiwqhqSeGnti2vslneVW5r0H-29mTfQzfcvOdSn7Q/edit -->

# mp_paidads.dwd_livestream_performance_di

**分层**：DWD（数据明细层）
**主键**：无单一主键；行粒度为广告事件级明细（每行对应一次曝光/点击/订单/CPM扣费事件），可通过 `ads_id + event_timestamp + request_id + click_event_id` 组合唯一标识
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（Daily Incremental，`_di` 后缀）
**引用频次**：242 次（候选表范围内）

---

## 业务描述

本表是直播广告（Live Stream Ads）绩效的核心明细层事实表，记录各地区每日直播广告的全量事件明细，涵盖曝光、点击、订单、成交额（GMV）、广告花费、直播间维度信息等核心指标。数据来源融合了 Report-NG 事件日志（归因结果）与 Translog 扣费日志（CPM计费结果），并通过专项补丁逻辑修复了 `translog_event` 数据缺失的 CPM 记录。

本表的典型使用场景包括：直播广告 ROI 分析（ROAS / CIR）、广告花费审计（按信用类型拆分）、直播间级别效果归因、广告主与MCN代理的绩效对账，以及下游 DWS/ADS 层聚合表的核心数据源。下游被引用 242 次，是整个直播广告数仓中引用最频繁的底层明细表之一。

本表同时支持直接归因（Direct）、宽泛归因（Broad，7日店铺内）、Agent 归因（MCN 代播）、展现归因（Impression Attribution）以及 CPM 扣费记录，字段口径繁多，使用时须仔细区分归因逻辑。各地区通过 `${region}`、`${timezone}` 参数化调度，按本地时区写入对应分区。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前写入值固定为 `'local'`（本地时区）。⚠️ 查询时必须显式过滤 `tz_type = 'local'`，否则会触发全分区扫描或多分区重复计算 |
| `grass_region` | string | 地区标识（大写），如 `'ID'`、`'MY'`、`'TH'` 等，各地区按本地时区参数化调度独立写入 |
| `grass_date` | date | 数据日期分区，格式 `yyyy-MM-dd`，对应事件发生的本地日期 |

---

### 维度：主键与广告层级属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，广告最小粒度标识 |
| `campaign_id` | bigint | 营销活动 ID，广告所属 Campaign |
| `account_id` | bigint | 广告账号 ID（广告所有者）。当 `account_id = target_affiliate_id` 时，为卖家或 KOL 自投；否则为 MCN 代投场景 |
| `shop_id` | bigint | 广告关联店铺 ID |
| `item_id` | bigint | 广告商品 ID |
| `origin_item_id` | bigint | 订单实际商品 ID（与 `item_id` 可能不同，记录订单真实成交商品） |
| `user_id` | bigint | 触发事件的用户 ID |
| `target_affiliate_id` | bigint | MCN 场景下的 affiliate 用户 ID（即广告实际使用方）。若 `account_id = target_affiliate_id`，则为自用广告；若不同，则为 MCN 代投 |
| `pricing_type` | int | 广告计价模式：`9 = LIVE_STREAM_MAX_VIEW`，`10 = LIVE_STREAM_MAX_GMV`，另支持 14、19、22 等扩展类型 |
| `request_id` | string | 广告请求 ID，用于关联同一次广告请求的多条事件 |
| `click_event_id` | string | 点击事件唯一 ID |
| `model_id` | bigint | 原始订单 ID（raw order id） |
| `order_id` | bigint | 订单 ID |

---

### 维度：直播间属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ls_session_id` | bigint | 直播间 Session ID |
| `streamer_id` | bigint | 主播 ID |
| `streamer_shop_id` | bigint | 主播所属店铺 ID |
| `streamer_type` | int | 主播类型编码 |
| `ls_session_start_timestamp` | bigint | 直播开始时间（Unix 时间戳，秒） |
| `ls_session_start_datetime` | string | 直播开始时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `ls_session_end_timestamp` | bigint | 直播结束时间（Unix 时间戳，秒） |
| `ls_session_end_datetime` | string | 直播结束时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `ls_session_duration` | bigint | 直播时长（单位：秒） |

---

### 维度：广告活动时间属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_create_timestamp` | bigint | 广告创建时间（Unix 时间戳）|
| `ads_create_datetime` | string | 广告创建时间，格式 `YYYY-MM-DD HH:MM:SS`，由 `ads_create_timestamp` 格式化派生 |
| `campaign_start_datetime` | string | Campaign 开始时间，格式 `YYYY-MM-DD HH:MM:SS` |
| `campaign_end_datetime` | string | Campaign 结束时间，格式 `YYYY-MM-DD HH:MM:SS` |

---

### 维度：事件时间属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `event_timestamp` | bigint | 事件时间戳（Unix 格式），事件可为下单、付款或确认收货 |
| `event_datetime` | string | 事件时间，格式 `YYYY-MM-DD HH:MM:SS`，由 `event_timestamp` 派生 ⚠️ 为冗余派生字段，与 `event_timestamp` 信息重复，过滤时优先使用分区字段 `grass_date` |
| `click_timestamp` | bigint | 点击事件时间戳（Unix 格式） |
| `click_datetime` | string | 点击时间，格式 `YYYY-MM-DD HH:MM:SS`，由 `click_timestamp` 格式化派生 ⚠️ 为派生字段，不可作为分区过滤依据 |
| `paid_timestamp` | bigint | 订单付款时间戳（Unix 格式），COD 订单为下单时间，非 COD 为付款时间 |
| `paid_datetime` | string | 付款时间，格式 `YYYY-MM-DD HH:MM:SS`，由 `paid_timestamp` 派生 ⚠️ 为派生字段 |
| `confirmed_timestamp` | bigint | 卖家确认发货时间戳（Unix 格式），COD 为下单时间，非 COD 为付款时间 |
| `confirmed_datetime` | string | 确认时间，格式 `YYYY-MM-DD HH:MM:SS`，由 `confirmed_timestamp` 派生 ⚠️ 为派生字段 |

---

### 维度：流量与渠道属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `entrance` | int | 直播广告入口：`27 = ENTRANCE_LIVE_STREAM_DISCOVERY`，`28 = ENTRANCE_LIVE_STREAM_FOR_YOU` |
| `sub_entrance` | bigint | 子入口标识，细化 `entrance` 的流量来源 |
| `source` | string | 直播间入口追踪来源标识，详见内部 Confluence 文档 |
| `content_mix_frame_tab_name` | int | 内容混排帧 Tab 类型：`0 = UNKNOWN`，`1 = LiveTab`，`2 = ForYouTab`，`3 = VideoTab`，`4 = DiscoverTab` |
| `placement` | int | 广告位标识 |
| `platform` | string | 用户使用的平台类型（如 iOS、Android 等） |
| `page_type` | string | 页面类型（如 `image_search`、`search`、`shop`、`me` 等） |
| `page_section` | string | 页面区域标识，标识主流量事件所在的页面区域（如 `search`、`rcmd`、`you_may_also_like` 等） |
| `traffic_source` | int | 流量来源编码（如 `org`、`roi1`、`roi2` 等） |
| `recall_source` | int | 召回来源标识 |
| `location` | int | 当前商品在整个数据流中的位置（从 0 开始） |
| `location_in_ads` | int | 当前商品在广告商品列表中的位置索引（从 0 开始） |
| `slot_id` | bigint | 展示广告的广告位 ID |
| `target_type` | string | 广告目标类型（如 `item` 等） |
| `shop_exp_tag` | int | 店铺曝光标签：`1 = 命中店铺曝光`，`0 = 未命中`。用于宽泛归因（impression attribution）场景的过滤标识 |
| `is_cod` | tinyint | 是否为货到付款（COD）订单：`1 = 是`，`0 = 否` |
| `bid_rerank_trace` | string | 出价重排序追踪信息，经 `BiddingInfoDecodeUDF` UDF 解码后存储 ⚠️ 为 UDF 解码后的结构化字符串，不可直接聚合 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression` | bigint | 原始曝光次数 |
| `non_fraud_impression` | bigint | 非反作弊（去除无效流量后）的曝光次数 |
| `deduct_impression` | bigint | 实际扣费曝光次数（CPM 计费基础）⚠️ 来源混合了 Report-NG 事件行与 CPM 扣费补丁行，同一广告在同一分区可能存在多行，SUM 前须确认数据行来源 |
| `click` | bigint | 成功扣费的有效点击次数 |
| `raw_click` | bigint | 原始点击次数（未经过滤） |
| `product_click` | bigint | 从直播间点击商品的去重次数 |
| `view` | bigint | 直播间观看次数（仅直播流内存在，列表页无此值） |
| `view_duration` | bigint | 观看时长，每 30 秒上报一次，单位为毫秒 ⚠️ 单位为毫秒，换算为秒需除以 1000 |
| `add_to_cart` | bigint | 加购次数。归因逻辑：用户点击加购或立即购买，若仅广告商品成功加购，则回溯 1 天内最近的非欺诈广告点击进行归因 |
| `cpm` | bigint | 算法侧估算的千次展示费用（单位：本地货币最小单位）⚠️ 为算法预估值，不等于实际扣费，不可直接作为花费指标使用 |
| `expense_by_cpm` | bigint | 按 CPM 估算的原始广告花费（直播广告专用） |

---

### 指标：直接归因订单（Direct，7天内同商品）

| 字段 | 类型 | 说明 |
|------|------|------|
| `order` | bigint | 直接归因订单数。用户点击广告商品后 7 天内购买该商品计为直接订单 |
| `checkout` | bigint | 以 `order_id` 去重的直接归因结算单数（一个 checkout 可含多件商品） |
| `item_sold_cnt` | bigint | 直接归因订单的商品销量 |
| `order_gmv` | double | 直接归因订单 GMV（本地货币，已除以 100000 换算）⚠️ 原始存储值为整数乘以 10^5，ETL 中已换算为实际货币单位，可直接 SUM |
| `order_gmv_usd` | double | 直接归因订单 GMV（美元，已通过汇率换算）⚠️ 汇率取自 `dim_exchange_rate`，汇率时点为当日，跨期对比时注意汇率口径一致性 |
| `daily_order` | bigint | 当日点击当日下单的直接广告订单数（与点击发生在同一天） |
| `daily_item_sold_cnt` | bigint | 当日点击当日成交的商品销量 |
| `daily_gmv_amt_local` | double | 当日点击当日下单的直接订单 GMV（本地货币）⚠️ 口径为同天点击+同天下单，时间窗口小于 `order_gmv` 的 7 天窗口 |
| `daily_gmv_amt_usd` | double | 当日点击当日下单的直接订单 GMV（美元）⚠️ 同上，口径为同天点击+同天下单 |
| `paid_order` | bigint | 30 天内已付款的广告订单数 |
| `paid_order_amount` | bigint | 已付款订单的商品件数 |
| `paid_order_gmv` | double | 已付款订单 GMV（本地货币）|
| `paid_order_gmv_usd` | double | 已付款订单 GMV（美元）⚠️ 通过汇率换算，注意汇率时点 |
| `paid_checkout_cnt` | bigint | 已付款的结算单数（以 order_id 去重） |
| `confirmed_order` | bigint | 30 天内已确认发货（或已付款，COD 为已下单）的广告订单数 |

---

### 指标：宽泛归因订单（Broad，7天内同店铺）

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order` | bigint | 宽泛归因订单数。用户点击广告进入商品页后，7 天内在同一店铺内购买任何商品计入 |
| `broad_item_sold_cnt` | bigint | 宽泛归因订单的商品销量 |
| `broad_gmv` | double | 宽泛归因订单 GMV（本地货币）⚠️ 口径为 7 天内同店铺所有商品，包含非广告商品，与 `order_gmv`（仅广告商品）口径不同，不可混用 |
| `broad_gmv_usd` | double | 宽泛归因订单 GMV（美元）⚠️ 同上口径注意事项，且含汇率换算 |

---

### 指标：Agent 归因订单（MCN 代播场景）

| 字段 | 类型 | 说明 |
|------|------|------|
| `agent_order` | bigint | Agent（MCN 代播）场景下的直接归因订单数 |
| `agent_item_sold_cnt` | bigint | Agent 场景直接归因订单的商品销量 |
| `agent_gmv` | double | Agent 场景直接归因订单 GMV（本地货币）|
| `agent_gmv_usd` | double | Agent 场景直接归因订单 GMV（美元）⚠️ 含汇率换算 |
| `agent_checkout` | bigint | Agent 场景以 `order_id` 去重的直播广告订单数 |

---

### 指标：展现归因订单（Impression Attribution，无点击场景）

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_attr_order` | bigint | 无广告点击但命中 `shop_exp_tag` 的曝光归因订单数 |
| `imp_attr_order_amount` | bigint | 无广告点击但有广告曝光的曝光归因商品数 |
| `imp_attr_order_gmv` | decimal(25,10) | 曝光归因订单 GMV（本地货币，已除以 100000 换算）|
| `imp_attr_order_gmv_usd` | decimal(25,10) | 曝光归因订单 GMV（美元）⚠️ 含汇率换算 |
| `imp_attr_agent_order` | bigint | Agent OA 链路中无 agent 点击但有 agent 曝光的订单数 |
| `imp_attr_agent_order_amount` | bigint | Agent OA 链路中无 agent 点击但有 agent 曝光的商品数 |
| `imp_attr_agent_order_gmv` | decimal(25,10) | Agent 曝光归因订单 GMV（本地货币）|
| `imp_attr_agent_order_gmv_usd` | decimal(25,10) | Agent 曝光归因订单 GMV（美元）⚠️ 含汇率换算 |
| `imp_attr_paid_order_cnt` | bigint | 曝光归因已付款订单数（字段注释为空，从 ETL 上下文推断）|
| `imp_attr_paid_order_amount` | bigint | 曝光归因已付款订单商品件数（字段注释为空，从 ETL 上下文推断）|

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure` | double | 广告花费（本地货币，已除以 100000 换算为实际货币单位）|
| `ads_expenditure_usd` | double | 广告花费（美元，通过汇率换算）⚠️ 含汇率换算，汇率取当日值 |
| `ads_expenditure_vat` | double | 广告花费（本地货币，含增值税剔除后的税前金额）⚠️ 为 `ads_expenditure / (1 + vat_rate)` 派生计算，不可直接 SUM 后反推 VAT 比率 |
| `ads_expenditure_usd_vat` | double | 广告花费（美元，含 VAT 剔除）⚠️ 同上，为派生计算字段，区分跨境（CB）与本地税率 |
| `expense_free_credit_with_expiry` | bigint | 从有有效期的免费信用额度中扣除的广告费用（本地货币 × 10^5）⚠️ 单位为本地货币乘以 10^5，需除以 100000 换算为实际金额 |
| `expense_free_credit_without_expiry` | bigint | 从无有效期的免费信用额度中扣除的广告费用（本地货币 × 10^5）⚠️ 单位为本地货币乘以 10^5 |
| `expense_paid_credit_with_expiry` | bigint | 从有有效期的付费信用额度中扣除的广告费用（本地货币）⚠️ 注意：与其他 expense 字段相比，单位存在差异，需核实原始 ETL 口径后再使用 |
| `expense_paid_credit_without_expiry` | bigint | 从无有效期的付费信用额度中扣除的广告费用（本地货币 × 10^5）⚠️ 单位为本地货币乘以 10^5 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，避免全表扫描导致性能劣化或资源超限：

| 分区字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描全部 tz_type 分区，当前仅写入 `local`，遗漏时逻辑等价但扫描成本翻倍 |
| `grass_region` | `grass_region = 'XX'`（按实际地区指定）| 触发全地区扫描，数据量成倍增加且会混入其他地区数据 |
| `grass_date` | `grass_date = '2024-01-01'` 或范围条件 | 触发全量历史分区扫描，严重影响查询性能 |

**示例（正确写法）：**
```sql
SELECT ads_id, SUM(impression), SUM(ads_expenditure)
FROM mp_paidads.dwd_livestream_performance_di
WHERE tz_type = 'local'
  AND grass_region = 'ID'
  AND grass_date = '2024-01-01'
GROUP BY ads_id;
```

### 不可直接 SUM 的字段

以下字段在聚合时需特别注意，**不可直接跨行 SUM**：

| 字段 | 问题原因 | 正确使用方式 |
|------|----------|-------------|
| `ads_expenditure_vat` / `ads_expenditure_usd_vat` | 为 `ads_expenditure / (1 + vat_rate)` 的派生值，VAT 税率因店铺类型（CB/非CB）而异，简单 SUM 会混淆税率 | 按 `is_cb_shop` 分组后分别 SUM，或直接 SUM `ads_expenditure` 后在应用层处理 VAT |
| `expense_free_credit_with_expiry` / `expense_free_credit_without_expiry` / `expense_paid_credit_without_expiry` | 单位为本地货币 × 10^5，与 `ads_expenditure` 单位不同 | SUM 后除以 100000 换算为实际货币单位，且不可与 `ads_expenditure` 直接加总 |
| `expense_paid_credit_with_expiry` | 单位与其他 expense_* 字段存在差异（ETL 注释为 `local currency`，无 × 10^5），需核实 | 单独使用前确认单位后再与其他花费字段合并 |
| `cpm` | 为算法估算的千次展示费用（预计算值），不等于实际扣费 | 不可直接用于花费汇总，仅作参考；实际花费应使用 `ads_expenditure` |
| `target_cir` | 为目标成本收益比，由用户设定或算法填充，为比率类字段 | ⚠️ 不可直接 SUM，汇总时应使用广告主维度的加权平均或取最新值 |
| `view_duration` | 单位为毫秒，每 30 秒上报一次，存在分段累计特性 | SUM 后除以 1000 换算为秒，再除以 60 换算为分钟 |
| `deduct_impression` | 数据行来源混合（Report-NG 行 + CPM 补丁行 + CPM 修复行），同一广告可能在同一分区存在多类型行 | 必须结合业务场景确认是否只取特定行类型（如仅取有 `impression IS NOT NULL` 的行），避免重复计算 |
| `order_gmv_usd` / `broad_gmv_usd` / `agent_gmv_usd` / `imp_attr_order_gmv_usd` 等 USD 字段 | 汇率取自事件当日，跨多日聚合时汇率基准不同 | 跨日期聚合时，建议 SUM 本地货币后统一换算，或明确说明使用当日汇率 SUM |
| `bid_rerank_trace` | UDF 解码后的结构化字符串，不适合直接聚合 | 仅用于明细行级别的诊断分析 |

### 时效性说明

- 本表为 **每日全量覆盖写入**（`insert overwrite`），每日调度完成后当天分区数据最终稳定。
- `paid_order`、`confirmed_order` 字段统计的是 **30 天内**的付款/确认事件，这些字段的值随时间推移会在写入当天的分区中固化，历史分区不会追溯更新，因此**只代表写入当日时点的 30 天窗口统计值**，不适合用于跨日期比较累计趋势。
- `broad_order`/`broad_gmv` 采用 7 天归因窗口，同理，历史分区数据在写入后固化，不会回刷。
- 如需分析最新归因结果，应取**最新可用分区**（`MAX(grass_date)`）的数据；如需对比历史某天的当日表现，应取对应日期分区。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_ads_report_livestream_hi__reg_s0_live` | 直播广告 Report-NG 事件日志，提供曝光、点击、订单、GMV 等归因事件明细（主数据源） |
| `mp_paidads.ods_shopee_ads_db__translog_tab_di__reg_s0_live` | 广告扣费流水日志，提供 CPM 计费记录、信用额度扣减明细及广告花费 |
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | Translog 事件补充日志，提供 CPM 事件的页面、平台、流量等维度信息（与 translog_db 关联补全） |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度表，提供广告创建时间、Campaign 时间、店铺 ID 等广告属性维度 |
| `livestream.ls_mart_dim_ls_session` | 直播间 Session 维度表，提供主播 ID、直播时长、开始/结束时间等直播间属性 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维度表，提供当日本地货币对 USD 汇率，用于本地货币转 USD |
| `mp_user.dim_shop__reg_s0_live` | 店铺维度表，提供 `is_cb_shop`（跨境店）、`is_official_shop`、`is_managed_shop` 属性，用于区分 VAT 税率 |
| `regbida_keyreports.dim_vat_rate` | VAT 税率维度表，提供各地区跨境/本地广告收入的增值税税率，用于计算税前花费 |

---

## ETL 逻辑摘要

### 数据流

```
ods_log_ads_report_livestream_hi__reg_s0_live
        │  (Report-NG 事件日志：曝光/点击/订单/GMV 归因)
        ▼
[CTE: livestream_report_ng]
        │
        ├──────────────────────────────────────────────────────────────────┐
        │                                                                  │
ods_shopee_ads_db__translog_tab_di__reg_s0_live                           │
        │  (CPM 扣费流水: operation=11, pricing_type IN (9,10,14,19,22))   │
        ▼                                                                  │
[CTE: translog]                                                            │
        │                                                                  │
        │    ods_log_translog_event_hi__reg_s0_live                        │
        │    (CPM 事件维度补充: page_type/platform/cpm_detail)             │
        ▼           ▼                                                      │
[CTE: cpm_deduction] ←── LEFT JOIN on deduct_unique_id + ads_id           │
        │                                                                  │
        │  (CPM 数据补丁: 修复 translog_event 记录缺失问题)               │
        ▼                                                                  │
[CTE: cpm_deduction_issue_fix]                                             │
        │                                                                  │
        └──────────────────────────────────────────────────────────────────┘
                            │ UNION ALL（3路合并）
                            ▼
              [CTE: live_report_ng_all]
                            │
        ┌───────────────────┼────────────────────┬──────────────────┐
        │                   │                    │                  │
dim_advertise          ls_mart_dim_ls_session  dim_exchange_rate  (dim_shop + dim_vat_rate 后续关联)
(广告维度)             (直播间维度)            (汇率)
        └───────────────────┼────────────────────┘
                            ▼
                      [CTE: base]（LEFT JOIN 关联维度，计算 USD/GMV）
                            │
                    LEFT JOIN dim_shop（店铺类型判断 VAT）
                    LEFT JOIN dim_vat_rate（VAT 税率）
                            │
                            ▼
     dwd_livestream_performance_di__reg_s0_live
     （INSERT OVERWRITE，分区: tz_type='local' / grass_region / grass_date）
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `livestream_report_ng` | `ods_log_ads_report_livestream_hi__reg_s0_live` | 过滤指定地区和日期的 Report-NG 事件，仅取 `deduct_impression IS NULL` 的事件行（排除已在 translog 侧处理的 CPM 扣费行），作为归因事件主数据源 |
| `translog` | `ods_shopee_ads_db__translog_tab_di__reg_s0_live` | 过滤 CPM 扣费操作（`operation=11`），解析 `decoded_extinfo` 中的 JSON 字段，并解析信用额度类型明细（entries 数组），作为 CPM 花费数据源 |
| `cpm_deduction` | `translog` + `ods_log_translog_event_hi__reg_s0_live` | 将 translog 扣费记录与 translog_event 中的 CPM 事件明细（含用户维度、直播 JSON、content_mix_frame 等）进行 LEFT JOIN 关联，通过 `POSEXPLODE` 展开 CPM 事件数组，计算各信用类型花费占比 |
| `cpm_deduction_issue_fix` | `translog` + `cpm_deduction` 聚合 | 修复 `cpm_deduction` 中因 translog_event 日志丢失导致记录不完整的问题：计算 translog_db 总花费与 cpm_deduction 已匹配花费之差，补充未能从 translog_event 中解析的 impression 和费用记录 |
| `live_report_ng_all` | `livestream_report_ng` + `cpm_deduction` + `cpm_deduction_issue_fix` | 通过 UNION ALL 合并三路数据（Report-NG 归因事件 + CPM 明细行 + CPM 修复行），形成统一的宽表事件流 |
| `dim_advertise` | `mp_paidads.dim_advertise__reg_s0_live` | 提供广告维度（创建时间、Campaign 时间范围、shop_id 补全），过滤 live 广告计价类型 |
| `ls_dim` | `livestream.ls_mart_dim_ls_session` | 提供直播间维度（主播、时长、开播/结束时间） |
| `dim_exchange` | `mp_order.dim_exchange_rate__reg_s0_live` | 提供当日汇率，用于本地货币转 USD |
| `dim_shop` | `mp_user.dim_shop__reg_s0_live` | 提供店铺类型（CB/官方/托管），用于区分 VAT 税率适用场景 |
| `tax` | `regbida_keyreports.dim_vat_rate` | 提供各地区 CB 广告和本地广告的 VAT 税率，计算税前广告花费（`ads_expenditure_vat`） |
| `base` | `live_report_ng_all` + 以上维度表 | 关联所有维度，进行货币换算（本地 → USD）、时间字段格式化，形成最终写入前的完整宽表 |

### 注意事项

1. **三路数据合并（UNION ALL）导致的行类型差异**：`live_report_ng_all` 由三路 UNION ALL 合并，来自 Report-NG 的行包含完整的曝光/点击/订单/GMV 字段，来自 `cpm_deduction` 和 `cpm_deduction_issue_fix` 的行仅包含花费相关字段（曝光、点击、订单等均为 NULL）。因此，**对 `impression`、`click`、`order_gmv` 等指标字段直接 SUM 时，NULL 行不影响结果**；但若需要同时分析花费与归因效果，需理解两类行的字段填充情况。

2. **CPM 补丁行（`cpm_deduction_issue_fix`）**：专门处理 `translog_event` 日志丢失场景。当 `translog_db` 的总花费与 `cpm_deduction` 中已匹配的花费不一致时，用差值行补齐，确保花费总额完整。该逻辑使得同一 `deduct_unique_id` 的花费可能同时出现在 `cpm_deduction` 和 `cpm_deduction_issue_fix` 中（互补而非重复），**直接 SUM `ads_expenditure` 时无需额外去重**。

3. **信用额度字段单位不一致**：`expense_free_credit_with_expiry`、`expense_free_credit_without_expiry`、`expense_paid_credit_without_expiry` 的单位为本地货币 × 10^5；而 `expense_paid_credit_with_expiry` 在 ETL 注释中标注为 `local currency`（无 × 10^5）。使用时须分别处理，不可将四个字段直接相加。

4. **VAT 税率取最新可用日期**：`dim_vat_rate` 使用子查询取 `MAX(grass_date)` 的最新税率，而非当日税率。如果税率发生历史变更，历史分区的 `ads_expenditure_vat` 仍使用写入当时的最新税率，历史分区不会追溯修正。

5. **`shop_id` 来源优先级**：ETL 中 `shop_id` 优先使用 `dim_advertise` 关联到的 `shop_id`（`COALESCE(b.shop_id, a.shop_id)`），dim 表数据缺失时才使用原始事件中的 `shop_id`。

6. **参数化调度**：ETL SQL 中出现的 `upper('${region}')`、`'Asia/Jakarta'`、`DATE('${grass_date}')` 等均为调度模板占位符，实际运行时按各地区本地时区参数化替换，本表覆盖所有部署地区。

7. **GMV 单位换算**：上游 Report-NG 中 GMV 相关字段以整数存储（实际金额 × 10^5），ETL 中统一除以 100000 换算为实际货币单位后写入本表，`order_gmv`、`broad_gmv`、`agent_gmv`、`daily_gmv_amt_local`、`imp_attr_order_gmv`、`imp_attr_agent_order_gmv`、`paid_order_gmv` 均已完成换算，可直接 SUM。

---

*文档生成时间：2026-04-22*