<!-- ads-workspace-gdoc-sync: gdoc_id=1CKvgVqrAFvDpElCuVMAlPRkJB9sGUFMDBiOmcpIAtxc gdoc_url=https://docs.google.com/document/d/1CKvgVqrAFvDpElCuVMAlPRkJB9sGUFMDBiOmcpIAtxc/edit -->

# mp_paidads.dwd_advertise_seller_report_di

**分层**：DWD（明细数据层）
**主键**：无单一主键；逻辑主键为 `(grass_date, grass_region, handler, user_id, ads_id, item_id, shop_id, operation, event_timestamp)`
**分区**：`grass_region` / `handler` / `grass_date`
**更新频率**：每日全量覆写（INSERT OVERWRITE），T+1 调度（处理前一自然日数据）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是付费广告（Paid Ads）卖家投放报表的 DWD 明细层，汇聚来自广告追踪日志的三类原始事件——**商品广告追踪（tracking_item）**、**店铺广告追踪（tracking_shop）** 和 **视频广告追踪（tracking_video）**——并将曝光、点击、视频播放等多操作类型的日志行展平为统一的宽表结构，每行代表一条去重前的广告追踪事件聚合记录。

本表的核心价值在于为上层 ADS/报表层提供标准化、可横向对比的广告绩效原始明细，支持多维分析场景：按广告位类型（`handler`）、广告单元（`ads_id`）、商品（`item_id`）、店铺（`shop_id`）、买家（`user_id`）等维度下钻，统计曝光量、点击量、花费、订单及 GMV 等核心指标。各地区按本地时区参数化调度，覆盖平台所有活跃市场。

本表带 `__reg_s0_live` 后缀，通过 `${region}`、`${timezone}` 等参数化调度覆盖多地区，实际写入分区字段 `grass_region` 以区分地区数据。`sub_source` 字段区分三路数据来源（0=商品广告、1=店铺广告、2=视频广告），`handler` 分区字段则进一步标识广告位类型（如 `tracking-keyword`、`tracking-boost`、`tracking-livestream` 等），使用时需结合两者过滤以精准定位业务场景。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 数据日期分区，由 `event_timestamp` 转换而来（`DATE(from_unixtime(event_timestamp))`），代表广告事件发生的本地日历日期。⚠️ 每次查询必须指定此字段，否则触发全表扫描 |
| `grass_region` | string | 地区分区，取自追踪日志中的 `country` 字段，写入时与 `region` 相同。⚠️ 每次查询必须指定此字段，有效值包括：`MY`、`SG`、`TH`、`ID`、`VN`、`PH`、`TW`、`BR`、`MX`、`CO`、`CL`、`AR`（大写） |
| `handler` | string | 广告位类型分区，格式为 `tracking-{handler_type}`，可选值：`tracking-keyword`、`tracking-targeting`、`tracking-shop`、`tracking-boost`、`tracking-display`、`tracking-banner`、`tracking-livestream`、`tracking-roi2`、`tracking-shop_cpm`、`tracking-video`。⚠️ 过滤时注意带 `tracking-` 前缀 |

### 维度：主键与广告层级

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 触发广告事件的买家用户 ID，来自追踪日志 `userid` 字段，有效值 > 0 |
| `ads_id` | bigint | 广告单元 ID（Ad ID） |
| `campaign_id` | bigint | 广告活动 ID（Campaign ID） |
| `group_id` | bigint | 广告组 ID（Group ID）；仅 `handler` 为 keyword / boost / roi2 / targeting / shop 时有值，其余为 NULL |
| `shop_id` | bigint | 卖家店铺 ID |
| `item_id` | bigint | 推广商品 ID；店铺广告（sub_source=1）和视频广告（sub_source=2）中为 NULL |
| `account_id` | bigint | 广告账户 ID；视频广告中从 json_data 解析，商品广告和店铺广告中为 NULL |
| `affiliate_id` | bigint | 联盟 ID；当前所有来源均为 NULL，预留字段 |

### 维度：广告投放属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `region` | string | 地区代码，来自追踪日志 `country` 字段，与 `grass_region` 内容相同，但大小写可能混合（ETL 中已过滤为已知有效地区）。⚠️ 聚合时建议以 `grass_region`（分区字段）为准，避免大小写不一致 |
| `placement` | int | 广告位编码，对应业务中的广告展示位置（如搜索结果页、推荐流等）；编码含义参见 ETL SQL 头部注释中的 `TrackingOperationType` 对照及 `handlerByPlacement` 映射 |
| `entrance` | int | 广告入口编码，从 json_data 中解析 |
| `pricing_type` | int | 计价类型编码，从 json_data 中解析（如 CPC、CPM 等） |
| `match_type` | int | 关键词匹配类型；仅 keyword / roi2 / boost（部分 placement）/ shop / shop_cpm 类型有值 |
| `source` | int | 数据来源大类，当前固定为 `0`（tracking 日志） |
| `sub_source` | int | 数据来源子类：`0`=商品广告追踪、`1`=店铺广告追踪、`2`=视频广告追踪。⚠️ 跨 sub_source 合并统计时需注意指标口径差异，部分指标仅在特定 sub_source 下有值 |
| `operation` | int | 广告事件操作类型编码。主要值：1=曝光、2=点击、14=商品点击、21=视频播放、22=视频播放时长、1001=店铺曝光、1002=店铺点击。⚠️ 本表为事件行级别明细，同一 `(ads_id, grass_date)` 可存在多行不同 `operation`，聚合前需理解各指标对应的 operation 过滤逻辑 |
| `keyword` | string | 广告关键词；仅 keyword / roi2 / boost（部分 placement）/ shop / shop_cpm 类型有值 |
| `query` | string | 买家搜索词；仅 keyword / roi2 / boost（部分 placement）/ shop / shop_cpm 类型有值 |
| `location_in_ads` | bigint | 广告在列表中的位置序号；仅 keyword / boost / roi2 / targeting 和 video 类型有值，其余为 NULL |
| `ls_session_id` | bigint | 直播会话 ID；仅 shop_cpm 类型有值，其余为 NULL |
| `event_timestamp` | bigint | 广告事件发生的 Unix 时间戳（秒），来自追踪日志 `timestamp` 字段 |
| `new_boost` | bigint | 标记是否为新 Boost 广告（traffic_source=4 且 placement 为特定值时置 1）；仅商品广告来源部分记录有值，其余为 NULL |

### 指标：点击与曝光

| 字段 | 类型 | 说明 |
|------|------|------|
| `raw_imp` | bigint | 原始曝光计数（未去重）；商品广告：operation=1 且 duplicate_label≤0 且 handler 为 boost/keyword/roi2/targeting 时为 1；店铺广告：operation=1001 时为 1；视频广告：operation=1 且 duplicate_label≤0 时为 1 |
| `raw_click` | bigint | 原始点击计数（未去重）；商品广告：operation=2 时为 1；店铺广告：operation=1002 时为 1；视频广告：operation=2 时为 1。⚠️ 包含欺诈点击和重复点击，建议优先使用 `non_fraud_click` 或 `dedup_click` |
| `impression` | bigint | 有效曝光数；当前三路数据源均写入 NULL，为预留字段。⚠️ 当前为空，勿直接使用 |
| `click` | bigint | 有效点击数（已去重且过滤 ocpm 条件）；商品广告：operation=2 且 is_ocpm 且 duplicate_label≤0 时为 1；店铺广告：operation=1002 且 is_ocpm 且 duplicate_label≤0 时为 1；视频广告中为 NULL |
| `dedup_click` | bigint | 去重后点击数（不含 ocpm 条件过滤）；三路均按 duplicate_label≤0 去重 |
| `non_fraud_click` | bigint | 非欺诈点击数；过滤 `internal.frauds` 非空记录后统计 |
| `non_fraud_impression` | bigint | 非欺诈曝光数；过滤 `internal.frauds` 非空记录后统计 |
| `product_click` | bigint | 商品点击数（operation=14）；仅视频广告（sub_source=2，handler=video）有值，其余为 NULL |
| `video_view` | bigint | 视频播放次数（operation=21）；商品广告和视频广告类型有值，店铺广告为 NULL |
| `view` | bigint | 页面浏览数；当前三路数据源均写入 NULL，为预留字段。⚠️ 当前为空，勿直接使用 |
| `pageview` | bigint | 页面访问数；当前三路数据源均写入 NULL，为预留字段。⚠️ 当前为空，勿直接使用 |
| `view_duration` | bigint | 视频播放时长（operation=22）；仅视频广告（sub_source=2，handler=video）有值，其余为 NULL |
| `shop_item_impression` | bigint | 店铺商品曝光数；当前三路数据源均写入 NULL，为预留字段。⚠️ 当前为空，勿直接使用 |
| `shop_item_click` | bigint | 店铺商品点击数；当前三路数据源均写入 NULL，为预留字段。⚠️ 当前为空，勿直接使用 |

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `cost` | bigint | 广告花费总额；当前三路数据源均写入 NULL，为预留字段（可能由下游汇总层填充）。⚠️ 当前为空，勿直接使用 |
| `raw_expense` | bigint | 原始扣费金额（最小货币单位）；商品广告：CPC 时取 deduction_price，CPM 时取 deduction_price；店铺广告：点击取 deduction_price，曝光取 cpm/1000；视频广告：曝光时取 cpm/1000。⚠️ 单位为平台最小货币单位，换算为标准货币需除以 100000（或参照各地区汇率配置） |
| `cpm` | bigint | CPM 扣费金额（每千次曝光费用，原始值）；仅 CPM 计价且 operation=1（或 shop 的 operation=1001）时有值 |
| `cost_by_cpm` | double | CPM 单次曝光分摊费用（`cpm / 1000`）；仅 CPM 计价曝光时有值。⚠️ 为派生计算值（cpm÷1000），不可与 `cpm` 字段直接 SUM 后混用；按曝光次数汇总花费时应 SUM `cost_by_cpm` |
| `expense_paid_credit_without_expiry` | bigint | 使用无过期期限付费积分支出；当前三路均为 NULL，预留字段 |
| `expense_paid_credit_with_expiry` | bigint | 使用有过期期限付费积分支出；当前三路均为 NULL，预留字段 |
| `expense_free_credit_without_expiry` | bigint | 使用无过期期限免费积分支出；当前三路均为 NULL，预留字段 |
| `expense_free_credit_with_expiry` | bigint | 使用有过期期限免费积分支出；当前三路均为 NULL，预留字段 |

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `order` | bigint | 广告带来的订单数；当前三路数据源均写入 NULL，预留字段（通常由归因层回流）。⚠️ 当前为空，勿直接使用 |
| `order_amount` | bigint | 订单金额；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `order_gmv` | bigint | 订单 GMV；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `broad_order` | bigint | 宽口径归因订单数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `broad_item_count` | bigint | 宽口径归因商品件数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `broad_gmv` | bigint | 宽口径归因 GMV；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `broad_shop_item_imp` | bigint | 宽口径店铺商品曝光数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `broad_shop_item_click` | bigint | 宽口径店铺商品点击数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `daily_order` | bigint | 当日订单数（日粒度）；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `daily_gmv` | bigint | 当日 GMV（日粒度）；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `checkout` | bigint | 结算/下单行为数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `add_to_cart` | bigint | 加购物车次数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `expected_revenue` | bigint | 预期收入；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_order` | bigint | 付费归因订单数（窄口径）；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_order_amount` | bigint | 付费归因订单金额；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_order_gmv` | bigint | 付费归因订单 GMV；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_broad_order` | bigint | 付费宽口径归因订单数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_broad_order_amount` | bigint | 付费宽口径归因订单金额；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_broad_gmv` | bigint | 付费宽口径归因 GMV；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |
| `paid_checkout` | bigint | 付费归因结算数；当前三路数据源均写入 NULL，预留字段。⚠️ 当前为空，勿直接使用 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致查询超时或产生巨额计算费用：

```sql
WHERE grass_date = '2025-01-01'          -- 或日期范围：BETWEEN '2025-01-01' AND '2025-01-07'
  AND grass_region = 'MY'               -- 指定地区，使用大写地区码
  AND handler = 'tracking-keyword'      -- 如只关注某类广告位，强烈建议指定
```

- `grass_date`：**必须指定**，该表按天分区，遗漏将扫描全量历史数据
- `grass_region`：**必须指定**，有效值为大写地区码（`MY`/`SG`/`TH`/`ID`/`VN`/`PH`/`TW`/`BR`/`MX`/`CO`/`CL`/`AR`）；注意 `region` 字段内容与 `grass_region` 相同但大小写可能不一致，过滤时优先用分区字段
- `handler`：分区字段，若业务场景明确广告位类型，**强烈建议指定**以减少数据扫描量；值格式为 `tracking-{type}`

**补充过滤建议**：
- 多数分析场景需要按 `operation` 过滤，例如：统计曝光只取 `operation IN (1, 1001)`，统计点击只取 `operation IN (2, 1002)`，统计视频播放只取 `operation = 21`
- 跨广告类型分析时应意识到 `sub_source` 的差异：`sub_source = 0` 为商品广告，`sub_source = 1` 为店铺广告，`sub_source = 2` 为视频广告

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确做法 |
|------|----------|----------|
| `cost_by_cpm` | 派生值（`cpm / 1000`），已经是单次分摊值，直接 SUM 求总花费是正确的；但不可与 `cpm` 字段混合计算 | 汇总 CPM 花费：`SUM(cost_by_cpm)`；不要同时 SUM `cpm` 和 `cost_by_cpm` |
| `raw_expense` | 单位为平台最小货币单位，不同地区货币面值不同 | 换算为标准货币单位需除以对应汇率基数（通常为 100000），并关联汇率维表 |
| `click` | 受 `is_ocpm` 条件限制，仅 CPM 计价广告有值，与 `dedup_click` 含义不同 | 统计通用点击建议用 `SUM(dedup_click)`；CPM 计价点击用 `SUM(click)` |
| `impression` / `view` / `pageview` / `cost` 等预留字段 | 当前写入 NULL，SUM 结果为 0 或 NULL | 不可使用，改用 `raw_imp` / `non_fraud_impression` 作为曝光口径 |
| `order` / `order_gmv` / `broad_gmv` 等归因指标字段 | 当前写入 NULL，归因数据由其他任务回流填充 | 此表仅做追踪日志 DWD，订单/GMV 指标需从归因结果表获取 |
| `cpm` | 每千次曝光费用原始值，SUM 后不代表总花费 | CPM 总花费 = `SUM(cost_by_cpm)` 或 `SUM(cpm) / 1000` |

### 时效性说明

- 本表采用 **T+1 全量 INSERT OVERWRITE** 写入，每日调度处理前一自然日（`${BIZ_YESTERDAY}`）的数据，通常在次日上午完成更新。
- `grass_date` 的值由 `event_timestamp` 按各地区本地时区转换而来；各地区按本地时区参数化调度，因此同一 UTC 时刻在不同地区可能落入不同的 `grass_date` 分区。
- 查询"最新"数据时应取 `grass_date = CURRENT_DATE - 1`；避免查询当天分区（数据可能未写完或分区不存在）。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live` | 广告追踪原始日志（小时分区），包含 items / shops / videos 三类嵌套结构，是本表的唯一数据来源；通过 LATERAL VIEW EXPLODE 展开三路数据 |

---

## ETL 逻辑摘要

### 数据流

```
mkplpaidads_data.ods_log_ads_tracking_hi__reg_s0_live
          │
          │  grass_date = '${BIZ_YESTERDAY}'
          │
    ┌─────┴──────────────────────────────────────────┐
    │                                                 │
    │  LATERAL VIEW EXPLODE(items)                    │
    │  operation IN (1,2,21)                          │
    │  item.adsid > 0                                 │
    ▼                                                 │
tracking_item_general                                 │
    │                                                 │
    │  handlerByPlacement 映射                        │
    │  ROW_NUMBER 去重（duplicate_label）              │
    ▼                                                 │
tracking_item_general_with_handler                    │
    │                                                 │
    │  rn = 1 取首条                                  │
    │  new_boost 标记                                 │
    ▼                                                 │
tracking_item ──────────────────────────────┐         │
(sub_source = 0, 商品广告追踪)               │         │
                                            │         │
    LATERAL VIEW EXPLODE(shops)             │         │
    operation IN (1001,1002)                │         │
    ads_id > 0, user_id > 0                │         │
    ▼                                       │         │
tracking_shop_general                       │         │
    │  handlerByPlacement + ROW_NUMBER 去重 │         │
    ▼                                       │         │
tracking_shop_general_with_handler          │         │
    │  rn = 1                               │         │
    ▼                                       │         │
tracking_shop ──────────────────────────────┤         │
(sub_source = 1, 店铺广告追踪)               │         │
                                            │         │
    LATERAL VIEW EXPLODE(videos)            │         │
    operation IN (1,2,14,21,22)             │         │
    video.ads_id > 0, user_id > 0           │         │
    ▼                                       │         │
tracking_video_general                      │         │
    │  handlerByPlacement + ROW_NUMBER 去重 │         │
    ▼                                       │         │
tracking_video_general_with_handler         │         │
    │  rn = 1                               │         │
    ▼                                       │         │
tracking_video ─────────────────────────────┤         │
(sub_source = 2, 视频广告追踪)               │         │
                                            ▼         │
                              UNION ALL (3路合并)      │
                                            │         │
                                            ▼         │
              dwd_advertise_seller_report_di__reg_s0_live
              (INSERT OVERWRITE, 分区: grass_region/handler/grass_date)
              (REPARTITION 2000 by grass_region, handler, grass_date, user_id)
```

### 关键 CTE 说明

| 临时视图（CTE） | 来源表 | 作用 |
|----------------|--------|------|
| `tracking_item_general` | `ods_log_ads_tracking_hi__reg_s0_live` (EXPLODE items) | 展开商品广告日志行，提取 placement/entrance/pricing_type 等维度，过滤 operation IN (1,2,21) 且 adsid > 0 |
| `tracking_item_general_with_handler` | `tracking_item_general` | 按 placement 映射 handler 类型，通过 ROW_NUMBER 在相同 (region, operation, duplicate_label, event_timestamp, user_id, ads_id, item_id ...) 分组内去重 |
| `tracking_item_with_placement` | `tracking_item_general_with_handler` | 取 rn=1 首条，规范化 placement/keyword/match_type/query/group_id 的输出逻辑（按 handler 类型条件赋值） |
| `tracking_item` | `tracking_item_with_placement` | 叠加 new_boost 标记（traffic_source=4 且特定 placement 时置 1） |
| `tracking_shop_general` | `ods_log_ads_tracking_hi__reg_s0_live` (EXPLODE shops) | 展开店铺广告日志行，过滤 operation IN (1001,1002) 且 ads_id > 0 |
| `tracking_shop_general_with_handler` | `tracking_shop_general` | 同商品广告路径，按 placement 映射 handler，ROW_NUMBER 去重 |
| `tracking_shop` | `tracking_shop_general_with_handler` | 取 rn=1，规范化 ls_session_id / keyword / match_type / query / group_id 输出 |
| `tracking_video_general` | `ods_log_ads_tracking_hi__reg_s0_live` (EXPLODE videos) | 展开视频广告日志行，过滤 operation IN (1,2,14,21,22) 且 video.ads_id > 0 |
| `tracking_video_general_with_handler` | `tracking_video_general` | 按 placement 映射 handler（优先取 `internal.cpm_deduction_info.placement`），ROW_NUMBER 去重 |
| `tracking_video` | `tracking_video_general_with_handler` | 取 rn=1，补充 view_duration（operation=22）、product_click（operation=14）字段 |

### 注意事项

1. **去重机制**：三路数据均采用 `ROW_NUMBER() OVER (PARTITION BY region, operation, duplicate_label, event_timestamp, user_id, ads_id, item_id, location_in_ads, placement, json_data, request_id, event_id ORDER BY event_timestamp)` 取 `rn = 1` 进行离线去重，用于过滤重复上报的事件；`raw_click` / `raw_imp` 为去重前计数，`dedup_click` / `non_fraud_click` 为去重后计数。

2. **handler 分区值格式**：写入分区时 handler = `concat('tracking-', handler_type)`，即带有 `tracking-` 前缀，不同于临时视图内部的 handler 值（如 `keyword`、`boost`）。过滤时务必使用带前缀的形式，例如 `handler = 'tracking-keyword'`。

3. **大量预留 NULL 字段**：订单、GMV、归因类指标（`order`、`order_gmv`、`broad_gmv`、`impression` 等约 20+ 字段）在本表三路数据源中均写入 NULL。这些字段的数据预计由其他归因/汇总任务通过 UNION 或 JOIN 方式补充写入，本表仅承载追踪日志明细。

4. **operation 编码跨 sub_source 不通用**：商品广告和视频广告使用 operation=1（曝光）、2（点击），店铺广告使用 1001（店铺曝光）、1002（店铺点击）。跨 sub_source 汇总曝光时，曝光条件应为 `operation IN (1, 1001)`，不可仅用 `operation = 1`。

5. **placement 特殊值**：ETL 中 `keyword` 类型的 placement=4 被重映射（原始 placement 保留在 `coalesce_placement`，输出中对 placement=4 的 keyword_wkdaelpmissisiht 特殊处理），分析时需注意。

6. **cost_by_cpm 的精度问题**：`cost_by_cpm` 字段类型为 `double`，由整数 `cpm / 1000` 计算，存在浮点精度误差；在对账场景需注意与 `cpm` 字段的换算一致性。

7. **地区大小写**：`region` 字段在日志中大小写混合（ETL 过滤条件包含 `'my'` 和 `'MY'` 两种），而 `grass_region`（分区字段）中的实际值取决于上游日志的 `country` 字段原始值；查询时建议用 `UPPER(grass_region)` 或直接使用大写值过滤。

---

*文档生成时间：2026-04-22*