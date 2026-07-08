<!-- ads-workspace-gdoc-sync: gdoc_id=18P2AIfE6elVP2eZiEWFwG-ZaqWSZKrfOYfwPxtkFNZo gdoc_url=https://docs.google.com/document/d/18P2AIfE6elVP2eZiEWFwG-ZaqWSZKrfOYfwPxtkFNZo/edit -->

# mp_paidads.dws_advertise_new_item_boost_order_th

**分层**：DWS（数据服务层）
**主键**：`ads_id`（广告 ID，在单分区内唯一）
**分区**：`grass_region` / `grass_date` / `h`（地区 / 日期 / 小时，三级分区）
**更新频率**：每小时调度，覆盖当前小时分区（INSERT OVERWRITE）
**引用频次**：1 次（候选表范围内下游引用统计）

---

## 业务描述

本表面向 **新品加速（New Item Boost）广告**，以广告 ID（`ads_id`）为粒度，逐小时快照当前广告的历史累计有效订单数、暂停累计时长及有效期起始时间戳。New Item Boost 是专为新上架商品设计的广告产品（placement = 44），帮助新品在上架初期快速积累曝光与销量。

表中的核心指标 `ads_order_cnt_th` 反映自广告"有效起点"（`start_timestamp`）以来截至当前统计周期内累计产生的广告订单数。`start_timestamp` 会随广告长时间暂停而被重置，`paused_hours` 记录广告连续暂停的小时数，两者共同描述广告的生命周期状态。该表采用**滚动小时快照**策略，每小时覆盖写入，是判断广告是否到达历史门槛（Threshold）的重要依据。

下游系统（如出价调优、广告质量评估等）可直接消费本表，获取每个 New Item Boost 广告在本地时区任意小时节点的历史订单积累情况，进而触发广告状态切换或预算调整等业务逻辑。各地区按本地时区参数化调度，覆盖所有已开通该广告产品的市场。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识，大写字母（如 `TH`、`ID`）。各地区独立调度，按本地时区参数化写入 |
| `grass_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`，对应 ETL 调度时间向前偏移 1 小时后的日期 |
| `h` | int | 业务小时（本地时区，0–23），对应 ETL 调度时间向前偏移 1 小时后的整点小时 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告唯一标识（New Item Boost 广告，placement = 44） |
| `item_id` | bigint | 广告关联的商品 ID |
| `start_timestamp` | bigint | 广告有效期的起始时间戳（Unix 秒）。⚠️ 该值并非广告创建时间，而是动态计算的有效起点：当广告累计暂停超过 7×24 小时（168 小时）后恢复正常，会被重置为 `mtime`（最近修改时间）；否则取历史快照中的 `start_timestamp`，初始值为广告创建时间 `ctime`。直接使用时需了解其业务含义 ⚠️ |

### 指标：广告订单与暂停状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_order_cnt_th` | bigint | 自 `start_timestamp` 起至当前统计小时内，广告累计产生的有效订单数（Threshold 口径，仅统计订单时间戳晚于 `start_timestamp` 的订单）。⚠️ 为**累计快照值**，不可跨分区直接 SUM；若广告处于非正常状态且 `paused_hours > 168`，该值被强制清零重置 ⚠️ |
| `paused_hours` | bigint | 广告当前连续暂停的累计小时数。广告恢复正常（`status = 1`）时归零；每小时暂停则在上一小时快照值基础上 +1。⚠️ 为**累计状态快照值**，不可跨分区直接 SUM 或比较绝对值，应取最新分区读取 ⚠️ |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，避免全表扫描导致资源浪费和查询超时：

```sql
WHERE grass_region = '<大写地区码>'   -- 如 'TH'、'ID'，必须大写
  AND grass_date   = DATE '<yyyy-MM-dd>'
  AND h            = <0~23>
```

- **`grass_region`**：必须使用大写字母，与写入时 `upper('${region}')` 一致，小写或混合大小写将导致分区未命中、全量扫描。
- **`grass_date` + `h`**：两者需配合使用，单独指定 `grass_date` 仍会扫描该日期下所有 24 个小时分区。

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确做法 |
|------|----------|----------|
| `ads_order_cnt_th` | 累计快照值，不同小时分区的值存在重叠计数；跨分区 SUM 会导致重复累加 | 取**单一分区**（最新小时）的值直接读取；若需计算某时间段增量，用 `当前分区值 - 历史分区值` |
| `paused_hours` | 连续暂停的累计快照值，跨分区 SUM 无实际业务含义 | 取**最新小时分区**的值作为当前暂停时长，不可多分区累加 |
| `start_timestamp` | 动态重置字段，不同时间点可能指向不同起点 | 结合业务时间点选取对应分区，不可聚合 |

### 时效性说明

- 本表每小时写入当前小时 - 1h 的分区（即 ETL 运行时写入 `h = BIZ_TIME - 1h`）。
- **推荐取最新完整小时分区**，即当前自然小时 - 1（已完成写入）的 `(grass_date, h)` 组合。
- 在查询时若选错分区（如取当前小时）可能命中尚未写入或正在写入的分区，导致数据为空或不完整。
- `paused_hours` 和 `ads_order_cnt_th` 均为历史累计快照，取最新分区即可得到最新状态，无需跨多分区聚合。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_shard_db__advertisement_tab__reg_continuous_s0_live` | 广告主表，筛选 placement = 44 的 New Item Boost 广告，获取广告状态、关联活动 ID、商品 ID 及创建/修改时间 |
| `mp_paidads.shopee_ads_${region}_shard_db__campaign_tab__reg_continuous_s0_live` | 活动（Campaign）主表，获取活动的开始/结束时间及状态，用于判断广告的综合生效状态 |
| `mp_paidads.dws_advertise_new_item_boost_order_th__reg_s0_live`（自身前一小时分区） | 历史快照自关联，读取 h-2 分区的 `paused_hours` 和 `start_timestamp`，实现跨小时状态滚动累计 |
| `mp_paidads.dwd_advertise_new_item_boost_event_th__reg_s0_live` | New Item Boost 广告事件明细表（DWD 层），提供广告订单事件（`broad_order`）及时间戳，用于统计有效订单数 |

---

## ETL 逻辑摘要

### 数据流

```
┌──────────────────────────────────────────────────────────────┐
│  advertisement_tab (placement=44)                            │
│  → new_item_boost_ads_all (CTE)                              │
└───────────────────────┬──────────────────────────────────────┘
                        │ LEFT JOIN on campaignid
┌──────────────────────────────────────────────────────────────┐
│  campaign_tab                                                │
│  → campaign_all (CTE)                                        │
└───────────────────────┘
                        │
                        ▼
          new_item_boost_ads_status (CTE)
          [计算广告综合生效状态 status=0/1]
                        │
                        │ LEFT JOIN on ads_id
┌──────────────────────────────────────────────────────────────┐
│  dws_advertise_new_item_boost_order_th (自身，h-2 分区)       │
│  [读取历史 paused_hours、start_timestamp]                     │
└───────────────────────┘
                        │
                        ▼
          new_item_boost_ads (CTE)
          [滚动计算 paused_hours、start_timestamp 重置逻辑]
                        │
                        │ LEFT JOIN on ads_id
┌──────────────────────────────────────────────────────────────┐
│  dwd_advertise_new_item_boost_event_th (h-1 分区)             │
│  → new_item_boost_ads_orders (CTE)                           │
│  [当前小时订单事件，broad_order]                              │
└───────────────────────┘
                        │
                        ▼
          聚合：SUM(broad_order WHERE timestamp > start_timestamp)
          清零逻辑：status≠1 且 paused_hours > 168 → ads_order_cnt_th = 0
                        │
                        ▼
┌──────────────────────────────────────────────────────────────┐
│  dws_advertise_new_item_boost_order_th (写入 h-1 分区)        │
│  INSERT OVERWRITE PARTITION(grass_region, grass_date, h)     │
└──────────────────────────────────────────────────────────────┘
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `new_item_boost_ads_all` | `advertisement_tab` | 筛选 placement = 44 的 New Item Boost 广告，获取基础属性（adsid、campaignid、status、itemid、ctime、mtime） |
| `campaign_all` | `campaign_tab` | 读取活动状态与时间范围，计算活动是否当前有效（`campaign_status`） |
| `new_item_boost_ads_status` | `new_item_boost_ads_all` + `campaign_all` | LEFT JOIN 活动信息，综合判断广告生效状态：仅当广告状态=1 且活动状态=1 时，`status=1` |
| `new_item_boost_ads` | `new_item_boost_ads_status` + 本表自身（h-2） | 核心状态滚动：计算当前 `paused_hours`（暂停则 +1，正常则归零）；若上次暂停超 168h 后恢复，`start_timestamp` 重置为 `mtime` |
| `new_item_boost_ads_orders` | `dwd_advertise_new_item_boost_event_th`（h-1） | 读取当前统计小时的广告订单事件明细 |

### 注意事项

1. **自关联滞后偏移**：ETL 读取本表 **h-2 分区**作为上一快照（而非 h-1），与订单事件表读取 h-1 分区不同，目的是保证在当前 h-1 分区写入前，历史快照数据已完整落地，避免读写冲突。实际写入的是 **h-1 分区**。

2. **`start_timestamp` 重置规则**：
   - 正常情况：沿用历史快照中的 `start_timestamp`，首次创建时取广告 `ctime`。
   - 若广告暂停时长（`last_paused_hours`）超过 7×24 = 168 小时后再次恢复正常（`status = 1`），则 `start_timestamp` 重置为 `mtime`（最近修改时间），代表广告重新计算有效期。

3. **`ads_order_cnt_th` 清零规则**：当广告处于非正常状态（`status ≠ 1`）且当前 `last_paused_hours > 168` 时，`ads_order_cnt_th` 被强制写为 0，表示超长暂停后订单计数重置。

4. **订单有效性口径**：仅统计订单事件时间戳（`timestamp`）严格晚于 `start_timestamp` 的订单，确保只累计广告有效期内产生的订单。

5. **状态判断依赖实时时间**：`campaign_all` 中使用 `unix_timestamp()` 判断活动是否在有效期内，该值为 ETL 任务运行时的服务器时间，存在轻微时效性误差（分钟级）。

6. **分区地区码大小写**：写入时统一使用 `upper('${region}')` 转大写，查询时 `grass_region` 过滤条件必须使用大写，否则分区裁剪失效。

---

*文档生成时间：2026-04-22*