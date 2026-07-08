<!-- ads-workspace-gdoc-sync: gdoc_id=1rqZd6K9noQXytj81a7NvL_Lj3NxjdgUoLcKn0WXR0tE gdoc_url=https://docs.google.com/document/d/1rqZd6K9noQXytj81a7NvL_Lj3NxjdgUoLcKn0WXR0tE/edit -->

# mp_paidads.dim_active_item

**分层：** ADS 层（维度表）
**主键：** `ads_id`
**分区：** 无静态分区字段（实时 Kafka 流写入，按 `update_time` 标记更新时间）
**更新频率：** 实时流式更新（每 5 秒一批，滚动拉取 ads 变更）
**引用频次：** 0（末端 ADS 层表，直接供下游查询使用）

---

## 业务描述

本表存储当前**活跃付费广告投放条目（Active Item）**的维度快照，涵盖各地区 placement 40 和 placement 50 下的广告单元信息，包括广告 ID、商品 ID、店铺 ID、计划 ID、投放位置及操作类型等核心属性。数据来源于 Shopee 广告平台（Valar Gateway）的实时 API，通过 Python 流式 ETL 程序拉取后写入 Kafka Topic `shopee_ads_roi2_active_item`，再落地至本表。

本表主要用于**识别当前处于活跃投放状态的广告条目**，支撑付费广告的归因分析、ROI 计算、广告主大盘监控等场景。下游可通过关联商品、店铺、广告计划等维度表，快速定位某一广告的投放状态与归属信息。

由于 ETL 采用增量变更推送机制（`+I` 新增 / `-D` 删除），本表反映的是各地区广告条目在 placement 40、50 下的**最新活跃状态**，是构建实时付费广告数据流的关键基础维表。各地区按本地时区参数化调度，覆盖所有 Shopee 运营市场。

---

## 字段列表

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告单元唯一标识，为本表主键。每条广告投放记录对应一个 ads_id |
| `campaign_id` | bigint | 广告计划 ID，标识该广告所属的投放计划（Campaign） |
| `item_id` | bigint | 被投放的商品 ID，关联商品维度表可获取商品详情 |
| `shop_id` | bigint | 广告主店铺 ID，关联店铺维度表可获取店铺信息 |
| `placement` | bigint | 投放位置编码，当前仅拉取 placement 40（搜索广告）和 placement 50（发现广告）两种类型 ⚠️ 该字段为枚举编码，直接数值无业务含义，需对照 placement 映射表解读，勿直接 SUM |
| `grass_region` | string | 地区编码（大写），如 `SG`、`MY`、`TH` 等，标识该广告所属的 Shopee 运营市场；各地区按本地时区参数化调度写入 |
| `operation` | string | 数据变更操作类型：`+I` 表示新增/激活，`-D` 表示删除/下线 ⚠️ 查询活跃广告时必须过滤 `operation = '+I'`，否则会将已下线广告误计为活跃 |
| `update_time` | timestamp | 本条记录的拉取时间戳（Unix 秒），由 ETL 程序在调用 API 时记录，反映数据写入时间而非广告状态变更时间 ⚠️ 该字段为 ETL 写入时间，非广告平台侧的业务变更时间，不可用于精确还原广告状态变更历史 |

---

## 查询使用须知

### 必须包含的过滤条件

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `operation` | `WHERE operation = '+I'` | 若不过滤，已下线（`-D`）广告条目将混入结果，导致活跃广告数虚高、关联数据错误 |
| `grass_region` | `WHERE grass_region = '${region}'` | 若不过滤，将跨地区混合统计，可能导致商品/店铺 ID 重叠引发计算错误，且影响查询性能 |
| `placement` | `WHERE placement IN (40, 50)` | 当前数据已按 placement 40/50 拉取，但建议显式过滤以防后续新增 placement 类型时查询结果变化 |

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确使用方式 |
|------|----------|--------------|
| `placement` | 枚举编码，数值无加和意义 | 使用 `GROUP BY placement` 或 `COUNT(DISTINCT ads_id)` 按位置分组统计 |
| `update_time` | 时间戳，不具备累加语义 | 取 `MAX(update_time)` 获取最新拉取时间，或用于时间范围过滤 |

### 时效性说明

本表为实时流式写入，数据每 5 秒增量更新一次。查询活跃广告时，应结合 `update_time` 取最近一段时间的最新记录，建议：

1. **获取当前活跃快照**：先按 `ads_id` 取 `MAX(update_time)` 最新记录，再过滤 `operation = '+I'`，确保未被 `-D` 覆盖。
2. **时间窗口分析**：若分析某一时间段内的活跃广告，需注意 `update_time` 为 ETL 拉取时间，与广告实际状态变更时间存在秒级误差。
3. **避免全量扫描**：如无分区裁剪，应尽量在查询中加入 `update_time` 范围限制，减少扫描数据量。

---

## 数据来源

| 上游表 / 数据源 | 用途 |
|----------------|------|
| Shopee 广告平台 API：`paidads.valar.gateway.get_ads_info` | 初始化全量拉取各地区 placement 40/50 下的活跃广告信息 |
| Shopee 广告平台 API：`paidads.valar.gateway.get_ads_info_changes` | 增量拉取广告变更记录（新增 `+I` / 删除 `-D`），每 5 秒一批 |
| Kafka Topic：`shopee_ads_roi2_active_item` | Python ETL 将 API 结果序列化为 JSON 后发布至此 Topic，再由消费端写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
┌─────────────────────────────────────────────────────┐
│         Shopee 广告平台 Valar Gateway API            │
│  ┌──────────────────────┐  ┌───────────────────────┐│
│  │  get_ads_info        │  │  get_ads_info_changes  ││
│  │  (初始化全量拉取)    │  │  (增量变更拉取)        ││
│  │  placement: [40,50]  │  │  placement: [40,50]    ││
│  │  每次最多 500 条     │  │  时间窗口: 5秒/批      ││
│  └──────────┬───────────┘  └───────────┬────────────┘│
│             │  游标翻页 (node_cursors)  │ 并发12进程  │
└─────────────┼───────────────────────────┼─────────────┘
              │                           │
              ▼                           ▼
     ┌──────────────────────────────────────────┐
     │         Python ETL（多进程 + 线程池）     │
     │  字段提取：ads_id / item_id / campaign_id │
     │           shop_id / placement             │
     │           update_time（API调用时间戳）    │
     │           grass_region（region.upper()）  │
     │           operation（+I / -D）            │
     └──────────────────┬───────────────────────┘
                        │ JSON 序列化
                        ▼
     ┌──────────────────────────────────────────┐
     │   Kafka Topic: shopee_ads_roi2_active_item│
     │   集群: di-kafka-at01-bg1 (Airtrunk SG)  │
     │   批大小: 32KB / linger: 10ms / acks=all │
     └──────────────────┬───────────────────────┘
                        │ Kafka Consumer 消费写入
                        ▼
     ┌──────────────────────────────────────────┐
     │  mp_paidads.dim_active_item__reg_s0_live  │
     │  （按 ${region} 参数化调度，覆盖全地区） │
     └──────────────────────────────────────────┘
```

**计算引擎：** Python（multiprocessing + concurrent.futures.ThreadPoolExecutor）
**写入方式：** KafkaProducer → Kafka Topic → 下游 Consumer 写入数据表

### 关键 CTE 说明

本 ETL 为纯 Python 脚本，无 SQL CTE，核心逻辑分为两个函数：

| 函数 | 来源 | 作用 |
|------|------|------|
| `get_ads_info(region)` | Valar Gateway `get_ads_info` API | 初始化模式：全量拉取指定地区 placement 40/50 下所有活跃广告，通过 `node_cursors` 游标翻页直至数据拉取完毕，所有记录 operation 均标记为 `+I` |
| `get_ads_info_changes(start_ts, end_ts, region)` | Valar Gateway `get_ads_info_changes` API | 增量更新模式：拉取指定时间窗口内的广告变更，operation=1 映射为 `+I`，operation=3/4 映射为 `-D` |
| `produce(current_time, region)` | 调度入口 | 将 1 分钟时间窗口切分为 12 个 5 秒子窗口，通过 `multiprocessing.Pool(processes=12)` 并发调用 `get_ads_info_changes` |
| `ads_info_producer(messages)` | KafkaProducer | 将提取结果序列化为 JSON 批量发送至 Kafka Topic，配置 `acks=all` 保障消息不丢失 |

### 注意事项

1. **operation 字段的关键过滤**：ETL 将广告平台 operation=1 映射为 `+I`（激活），operation=3 或 4 映射为 `-D`（下线）。本表存储所有变更记录而非最终状态快照，查询活跃广告**必须过滤** `operation = '+I'` 并取每个 `ads_id` 的最新记录。

2. **update_time 含义**：该字段记录的是 Python ETL 调用 API 的本地时间（`start_time = time.time()`），而非广告平台侧的业务变更时间戳，存在秒级至分钟级偏差，不可用于精确事件溯源。

3. **placement 覆盖范围**：当前 ETL 仅拉取 `placement = [40, 50]` 的广告数据，其他 placement 类型不在本表覆盖范围内，与全量广告表对比时需注意口径差异。

4. **地区参数化调度**：`grass_region` 由调度参数 `${region}` 传入并转为大写写入，各地区独立调度，按本地时区运行，文档中出现的具体地区代码仅为调度模板示例。

5. **Kafka 可靠性配置**：生产者配置 `acks=all`、`retries=5`，具备基本的消息可靠性保障，但极端情况下仍可能存在少量重复消息，下游需做幂等处理。

6. **并发写入一致性**：增量模式使用 12 进程并发拉取同一分钟内的 12 个 5 秒子窗口，子窗口之间时间连续无重叠，但多进程写入 Kafka 时消息顺序无严格保证，查询时需以 `update_time` 排序取最新值。

---

*文档生成时间：2026-04-22*