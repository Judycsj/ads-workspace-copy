<!-- ads-workspace-gdoc-sync: gdoc_id=1o3wZEXqLLctSNsz3vmyzrVar8TRY6qT2EmJhhrfd3l0 gdoc_url=https://docs.google.com/document/d/1o3wZEXqLLctSNsz3vmyzrVar8TRY6qT2EmJhhrfd3l0/edit -->

# mp_paidads.dwd_advertise_seller_report_hi

**分层**：DWD（数据明细层）
**主键**：`grass_region` + `grass_date` + `h` + `source` + `sub_source` + `handler` + `ads_id` + `user_id` + `shop_id` + `item_id` + `campaign_id` + `placement` + `keyword` + `query`（复合维度唯一定位一行）
**分区**：`grass_region` / `grass_date` / `h`
**更新频率**：每小时调度（Hi 级，按业务日期 + 小时分区写入）
**引用频次**：0（末端 ADS 层宽表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告（Paid Ads）卖家报表的 DWD 级明细宽表，汇聚了 Shopee 平台各类广告形态（关键词广告、定向广告、店铺广告、Boost、展示广告、Banner、直播广告、视频广告、ROI2 等）在每自然小时内的全量事件数据。表中每行对应一个特定广告投放维度组合（地区 × 日期 × 小时 × 数据来源 × 广告类型 × 广告主体 ID 等）的汇总指标快照，覆盖曝光、点击、扣费成本、归因转化（订单/GMV/加购）等全链路指标。

数据由 7 路不同来源通过 UNION ALL 汇聚写入：Tracking 日志（商品、店铺、视频、展示、直播五类）提供曝光/点击/去重/反欺诈等流量指标；Translog 扣费流水提供实际成本及分科目费用；归因报告（ReportNG）提供订单、GMV、结账等转化类指标。各路数据通过 `source`、`sub_source`、`handler` 字段标识来源，下游使用时需结合这三个字段理解指标口径差异。

本表是付费广告效果报表、卖家广告账单、平台广告大盘分析等场景的核心数据源，各地区按本地时区参数化调度，支持全球多市场统一查询。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区编码，如 `SG`、`MY`、`TH` 等，大写。分区键之一，查询时必须指定 |
| `grass_date` | date | 业务日期（各地区按本地时区参数化调度得到的本地日期）。分区键之一 |
| `h` | bigint | 业务小时（0–23，对应 `grass_date` 所在本地时区的整点小时）。分区键之一 |

---

### 维度：数据来源与广告类型

| 字段 | 类型 | 说明 |
|------|------|------|
| `source` | int | 数据来源标识：`0`=Tracking 日志（商品/店铺/视频），`1`=Translog 扣费流水，`3`=Display Tracking Banner，`4`=Livestream Tracking，`5`=归因报告（ReportNG）⚠️ 不同 source 的同名指标字段含义和可用性不同，跨 source 聚合前须确认字段口径一致性 |
| `sub_source` | int | 来源子类型：`0`=商品 Tracking，`1`=店铺 Tracking，`2`=视频 Tracking，`3`=Display Tracking，`4`=Livestream Tracking；`source=1/5` 时无意义 |
| `handler` | string | 广告类型标签，格式为 `<prefix>-<type>`。前缀：`tracking-`（商品/店铺/视频）、`display_tracking-`（展示/Banner）、`livestream_tracking-`（直播）、`translog-`（扣费）、`reportng`（归因）；类型值：`keyword`、`targeting`、`shop`、`boost`、`display`、`banner`、`livestream`、`roi2`、`shop_cpm`、`video` ⚠️ 同一 `ads_id` 在不同 handler 下均有记录，聚合时需明确过滤目标 handler |
| `operation` | int | 原始事件操作类型，含义因数据来源而异：Tracking 中 `1`=曝光，`2`=点击，`13`=浏览，`14`=商品点击/视频播放，`15`=直播观看时长，`21`=视频观看，`22`=视频完播；店铺 Tracking 中 `1001`=曝光，`1002`=点击；Translog 中 `1`=点击扣费，`11`=曝光扣费，`15`=预期收益 ⚠️ 此字段在最终写入时已被用于计算各指标字段，汇总后该字段含义不明确，不建议直接用于过滤 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID |
| `user_id` | bigint | 用户 ID（广告主的用户账号 ID） |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID；仅商品 Tracking（`sub_source=0`）有值，其余来源为 NULL |
| `campaign_id` | bigint | 广告计划 ID |
| `group_id` | bigint | 广告组 ID；仅 keyword、boost、roi2、targeting、shop、shop_cpm 等类型有值，其余为 NULL |
| `account_id` | bigint | 广告账户 ID；仅 livestream、video、banner handler 有值，其余为 NULL |
| `affiliate_id` | bigint | 联盟用户 ID；仅 `handler=livestream` 时有值（若无联盟用户则兜底取 `account_id`），其余为 NULL |
| `placement` | int | 广告位编码；不同广告形态取值范围不同，0/4/4400=搜索关键词，1~8 系列=定向，3/7/20 系列=店铺，1000~1205=Boost，9=展示，65=Banner，3327~3348=直播，40/50=ROI2，45=shop_cpm，54=视频 ⚠️ keyword handler 在 placement=4 时 keyword 字段会被替换为哨兵值 `'wkdaelpmissisiht'`，查询时需注意 |
| `entrance` | int | 广告入口标识（从 tracking 日志或 extinfo 解析） |
| `pricing_type` | int | 计价类型（CPC/CPM/oCPM 等枚举值） |
| `match_type` | int | 关键词匹配类型（广泛/精确等）；仅 keyword、roi2、shop、shop_cpm 类型有值 |
| `location_in_ads` | bigint | 广告位内位置；仅 keyword、boost、roi2、targeting、video handler 有值，其余为 NULL |
| `keyword` | string | 关键词；部分 placement 下会被置为空字符串或哨兵值 `'wkdaelpmissisiht'` ⚠️ 不可直接用于关键词分析，需过滤掉哨兵值（`keyword != 'wkdaelpmissisiht'`）后再使用 |
| `query` | string | 用户搜索词；仅 keyword、roi2 及部分 boost handler 有值 |
| `ls_session_id` | bigint | 直播场次 ID；仅 livestream、shop_cpm handler 有值，其余为 NULL |
| `new_boost` | bigint | 新 Boost 标记（1 表示命中 new boost 逻辑）；仅 keyword/targeting handler 且 `traffic_source=4`、placement 在白名单时置 1 |
| `region` | string | 地区编码（与 `grass_region` 含义相同，来自原始日志字段） |
| `event_timestamp` | bigint | 事件时间戳（毫秒级 Unix 时间戳） |

---

### 指标：流量与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `raw_imp` | bigint | 原始曝光数（未去重、未过滤反欺诈） |
| `raw_click` | bigint | 原始点击数（未去重、未过滤反欺诈） |
| `impression` | bigint | 有效曝光扣费次数（来自 Translog，`source=1` 时为 `deduct_imp_cnt`，其余 source 为 NULL）⚠️ 非 `source=1` 时为 NULL，不可与 `raw_imp`/`non_fraud_impression` 混用 |
| `click` | bigint | 有效点击数；`source=1`（Translog）时为点击扣费次数；`source=0`（Tracking）时为 oCPM 模式下的去重点击数 ⚠️ 不同 source 下口径不同，跨 source 聚合会导致重复计数，须单独使用 |
| `dedup_click` | bigint | 去重点击数（Tracking 层按重复标记去重后的点击，剔除重复请求）；仅 Tracking 类 source 有值 |
| `non_fraud_click` | bigint | 反欺诈点击数（去除被标记为欺诈的点击）；仅 Tracking 类 source 有值 |
| `non_fraud_impression` | bigint | 反欺诈曝光数（去除被标记为欺诈的曝光）；仅 Tracking 类 source 有值 |
| `cpm` | bigint | CPM/oCPM 计价下的单次曝光扣费价格（单位：厘，需除以 1000 得到实际金额）；仅 Tracking 类 source 且 is_ocpm 时有值 ⚠️ 为单条记录的计价参考值，不可直接 SUM 求总曝光费用，应使用 `cost` 或 `raw_expense` |
| `cost_by_cpm` | double | CPM 计价方式下的费用（double 精度）；仅部分 Tracking source 有值 ⚠️ 为预计算费用字段，与 `cost`（Translog 口径）含义不同，不可混合 SUM |
| `view` | bigint | 直播/展示广告的浏览次数（`operation=13`）；仅 display/livestream tracking 有值 |
| `video_view` | bigint | 视频观看次数（`operation=21`）；适用于视频、展示、直播 tracking |
| `view_duration` | bigint | 视频/直播观看时长（累计秒数，`operation=22` 视频完播或 `operation=15` 直播观看时长）；仅视频和直播 tracking 有值 ⚠️ 为累计时长，聚合时可直接 SUM，但需确保同一 source 内聚合 |
| `product_click` | bigint | 商品点击数（`operation=14`，直播中商品被点击或视频广告中商品点击）；仅 livestream/video tracking 有值 |
| `pageview` | bigint | 店铺页面浏览量；来自 ReportNG（`source=5`），其余 source 为 NULL |
| `shop_item_click` | bigint | 店铺商品点击数；来自 ReportNG（`source=5`） |
| `shop_item_impression` | bigint | 店铺商品曝光数；来自 ReportNG（`source=5`） |
| `broad_shop_item_imp` | bigint | 泛义店铺商品曝光数（含宽泛归因）；来自 ReportNG（`source=5`） |
| `broad_shop_item_click` | bigint | 泛义店铺商品点击数（含宽泛归因）；来自 ReportNG（`source=5`） |
| `add_to_cart` | bigint | 加购数；来自 ReportNG（`source=5`） |

---

### 指标：成本与费用

| 字段 | 类型 | 说明 |
|------|------|------|
| `cost` | bigint | 总扣费金额（四类费用科目之和：`expense_paid_credit_without_expiry + expense_paid_credit_with_expiry + expense_free_credit_without_expiry + expense_free_credit_with_expiry`）；来自 Translog（`source=1`），其余 source 为 NULL ⚠️ 仅 `source=1` 有意义，不可与 `raw_expense`（Tracking 口径）混合 SUM |
| `raw_expense` | bigint | Tracking 层记录的扣费金额（取自 `deduction_price`）；仅 Tracking 类 source（`source=0`）有值，其余为 NULL ⚠️ 与 `cost` 为不同口径的费用字段，两者不可相加 |
| `expected_revenue` | bigint | 预期收益（Translog 中 `operation=1/15` 时的 DAI 余额变化量）；仅 `source=1` 有值 |
| `expense_paid_credit_without_expiry` | bigint | 付费额度无期限消耗金额（Translog type=1）；仅 `source=1` 有值 |
| `expense_paid_credit_with_expiry` | bigint | 付费额度有期限消耗金额（Translog type=2）；仅 `source=1` 有值 |
| `expense_free_credit_without_expiry` | bigint | 免费额度无期限消耗金额（Translog type=3）；仅 `source=1` 有值 |
| `expense_free_credit_with_expiry` | bigint | 免费额度有期限消耗金额（Translog type=4）；仅 `source=1` 有值 |

---

### 指标：转化与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `order` | bigint | 归因订单量（直接归因）；来自 ReportNG（`source=5`） |
| `order_amount` | bigint | 归因订单金额；来自 ReportNG（`source=5`） |
| `order_gmv` | bigint | 归因订单 GMV；来自 ReportNG（`source=5`） |
| `paid_order` | bigint | 付费归因订单量（剔除免费额度贡献）；来自 ReportNG（`source=5`） |
| `paid_order_amount` | bigint | 付费归因订单金额；来自 ReportNG（`source=5`） |
| `paid_order_gmv` | bigint | 付费归因订单 GMV；来自 ReportNG（`source=5`） |
| `broad_order` | bigint | 宽泛归因订单量（含间接归因）；来自 ReportNG（`source=5`） |
| `broad_gmv` | bigint | 宽泛归因 GMV；来自 ReportNG（`source=5`） |
| `broad_item_count` | bigint | 宽泛归因商品件数；来自 ReportNG（`source=5`） |
| `paid_broad_order` | bigint | 付费宽泛归因订单量；来自 ReportNG（`source=5`） |
| `paid_broad_gmv` | bigint | 付费宽泛归因 GMV；来自 ReportNG（`source=5`） |
| `paid_broad_order_amount` | bigint | 付费宽泛归因订单金额；来自 ReportNG（`source=5`） |
| `checkout` | bigint | 结账次数（归因）；来自 ReportNG（`source=5`） |
| `paid_checkout` | bigint | 付费归因结账次数；来自 ReportNG（`source=5`） |
| `daily_order` | bigint | 每日归因订单量（天级汇总口径）；来自 ReportNG（`source=5`）⚠️ 与 `order` 存在统计口径差异（时间窗口不同），不可相加 |
| `daily_gmv` | bigint | 每日归因 GMV（天级汇总口径）；来自 ReportNG（`source=5`）⚠️ 与 `order_gmv` 存在统计口径差异，不可相加 |

---

## 查询使用须知

### 必须包含的过滤条件

查询本表时**必须同时指定以下三个分区字段**，否则将触发全表扫描，消耗大量计算资源并可能超时：

```sql
WHERE grass_region = 'SG'          -- 必须：指定地区，大写
  AND grass_date = '2024-01-15'    -- 必须：指定业务日期
  AND h BETWEEN 0 AND 23           -- 建议：限定小时范围，若分析整天则不限制
```

- **`grass_region`**：分区首键，必须指定，缺失将扫描所有地区数据
- **`grass_date`**：分区次键，必须指定，缺失将扫描历史全量分区
- **`h`**：分区末键，分析整小时数据时可用 `BETWEEN 0 AND 23`，拉取指定小时时精确指定

**强烈建议**同时加上 `source` 过滤，避免将不同口径指标误混合：

```sql
AND source = 1    -- 仅取成本口径
-- 或
AND source = 5    -- 仅取转化口径
```

### 不可直接 SUM 的字段

| 字段 | 问题 | 正确计算方式 |
|------|------|-------------|
| `cpm` | 单条记录的计价参考值，非费用累计值 | 使用 `cost`（`source=1`）或 `raw_expense`（`source=0`）统计实际消耗 |
| `cost_by_cpm` | double 精度的预计算费用，与 `cost` 口径不同 | 单独使用，不与 `cost` / `raw_expense` 混合 SUM |
| `cost` 与 `raw_expense` | 两者为不同来源的费用字段，分别属于 Translog（`source=1`）和 Tracking（`source=0`）口径 | 分别在各自 `source` 过滤条件下 SUM，不可跨 source 相加 |
| `click` | 在 `source=1` 时为点击扣费次数（Translog 口径），在 `source=0` 时为 oCPM 去重点击数（Tracking 口径） | 明确单一 `source` 后再 SUM，两者不可合并 |
| `daily_order` / `daily_gmv` | 天级汇总口径，与 `order` / `order_gmv` 的时间窗口不同 | 按需选择其中一种口径，不可与对应的 `order` / `order_gmv` 相加 |
| `keyword`（含哨兵值） | placement=4 时 keyword 被替换为 `'wkdaelpmissisiht'` | 关键词分析须加过滤：`AND keyword != 'wkdaelpmissisiht' AND keyword IS NOT NULL AND keyword != ''` |
| 各 `expense_*` 分科目字段 | 四个分科目之和等于 `cost`，单独 SUM 仅表示该科目消耗 | 合计成本时直接用 `SUM(cost)`，需分科目分析时分别 SUM 各子字段 |

### 时效性说明

本表为小时级分区表（Hi 表），每小时调度一次增量写入：

- **当天数据**：查询时指定具体 `h` 值获取该小时数据；需统计全天时用 `SUM` 聚合 `h=0` 到最新已完成小时
- **数据延迟**：Tracking 日志和 Translog 数据存在分钟级延迟，通常在调度执行完成后约 10~30 分钟数据可用；ReportNG（`source=5`）的归因数据可能存在更长的归因窗口延迟
- **不建议**直接查询当前小时最新分区，建议使用前一小时已完成分区：

```sql
AND h <= (HOUR(NOW()) - 1)    -- 避免查到写入中的分区
```

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live` | Banner/展示广告追踪日志，提供展示类广告曝光、点击、浏览事件（source=3） |
| `mp_paidads.ods_log_livestream_ads_tracking__reg_s0_live` | 直播广告追踪日志，提供直播广告曝光、点击、观看时长、商品点击事件（source=4） |
| `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` | 商品/店铺/视频广告追踪日志（EXPLODE items/shops/videos），分别提供三类广告 tracking 数据（source=0, sub_source=0/1/2） |
| `mp_paidads.ods_log_translog_event_hi__reg_s0_live` | 广告扣费流水日志，提供实际成本、分科目费用、预期收益（source=1） |
| `mp_paidads.ods_log_ads_report_hi__reg_s0_live` | 广告归因报告日志（ReportNG），提供订单、GMV、加购、结账等转化指标（source=5） |

---

## ETL 逻辑摘要

### 数据流

```
mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
    ├─ EXPLODE(items)  ──► [CTE] tracking_item_data  ──► INSERT source=0, sub_source=0 (商品Tracking)
    ├─ EXPLODE(shops)  ──► [CTE] tracking_shop_data  ──► INSERT source=0, sub_source=1 (店铺Tracking)
    └─ EXPLODE(videos) ──► [CTE] tracking_video_data ──► INSERT source=0, sub_source=2 (视频Tracking)

mp_paidads.ods_log_display_ads_tracking_hi__reg_s0_live
    └──► [CTE] display_tracking_banner ──► INSERT source=3, sub_source=3 (展示/Banner Tracking)

mp_paidads.ods_log_livestream_ads_tracking__reg_s0_live
    └──► [CTE] livestream_tracking_data ──► INSERT source=4, sub_source=4 (直播Tracking)

mp_paidads.ods_log_translog_event_hi__reg_s0_live
    └──► [CTE] translog_report_data ──► INSERT source=1 (扣费流水/成本)

mp_paidads.ods_log_ads_report_hi__reg_s0_live
    └──────────────────────────────────────────► INSERT source=5 (归因转化/GMV/订单)

                            ↓ 7路 UNION ALL
         dwd_advertise_seller_report_hi__reg_s0_live
              分区: (grass_region, grass_date, h)
```

> 计算引擎：Spark SQL；各地区通过 `${region}`、`${BIZ_DT}`、`${BIZ_H}` 参数化调度，每小时执行一次全量 INSERT OVERWRITE 对应分区。

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|---------------|--------|------|
| `display_tracking_banner` | `ods_log_display_ads_tracking_hi` | 解析 Banner JSON，映射 handler，输出展示广告事件（operation 1/2/13/21），item/account 相关字段置 NULL |
| `livestream_tracking_data` | `ods_log_livestream_ads_tracking` | EXPLODE 直播数组，处理 affiliate_id 兜底逻辑，新增 ls_session_id / view_duration |
| `tracking_item_data` | `ods_log_ads_tracking_hi`（items） | EXPLODE 商品数组，ROW_NUMBER 去重，处理 keyword 哨兵值、new_boost 标记、group_id/query 条件保留 |
| `tracking_shop_data` | `ods_log_ads_tracking_hi`（shops） | EXPLODE 店铺数组，ROW_NUMBER 去重，operation 1001/1002 对应曝光/点击，placement 默认值为 0 |
| `tracking_video_data` | `ods_log_ads_tracking_hi`（videos） | EXPLODE 视频数组，ROW_NUMBER 去重，view_duration 仅 operation=22 保留，使用 internal_label.frauds 判断反欺诈 |
| `translog_report_data` | `ods_log_translog_event_hi` | 三层嵌套：JSON_FROM_PROTOBUF 解析 extinfo → AGGREGATE 分科目费用 → ROW_NUMBER 按 deduct_unique_id 去重，输出成本及扣费明细 |

### 注意事项

1. **多口径费用字段**：`cost`（Translog 口径，`source=1`）与 `raw_expense`（Tracking 口径，`source=0`）、`cost_by_cpm`（CPM 计价预计算）均表示费用，但来源和统计方法不同，**绝对不可跨 source 相加**。分析广告主总消耗时，推荐以 `source=1` 的 `cost` 为准。

2. **Tracking 去重边界**：`tracking_item_data`、`tracking_shop_data`、`tracking_video_data` 使用 Spark ROW_NUMBER 在**当前小时分区内**去重，与 Flink Redis 跨小时去重存在边界差异——跨小时边界的重复事件在 Spark 端可能无法被完全去重，导致 `raw_imp`、`raw_click` 等字段在小时边界附近存在轻微高估。

3. **keyword 哨兵值**：`placement=4` 时 keyword 字段被替换为 `'wkdaelpmissisiht'`，该值为工程哨兵，无业务含义。关键词维度分析时须过滤该值。

4. **handler 前缀区分**：同一广告类型（如 `keyword`）会以 `tracking-keyword`、`translog-keyword` 两种 handler 出现在表中，分别代表 Tracking 和 Translog 两条数据链路，下游分析时不可混为一谈。

5. **US 地区直播数据**：`livestream_tracking_data` 中注明 US 地区无直播追踪数据，US 市场 `source=4` 分区下相关字段将为空。

6. **ReportNG 转化字段的 NULL 处理**：`source=5` 数据写入时，只有至少一个转化指标非零才会产生记录，Tracking 类字段在该 source 下全部为 NULL；反之，`source=0/1/3/4` 下所有转化类字段（order/GMV 等）均为 NULL。聚合时需用 `COALESCE(field, 0)` 避免 NULL 影响 SUM 结果。

---

*文档生成时间：2026-04-22*