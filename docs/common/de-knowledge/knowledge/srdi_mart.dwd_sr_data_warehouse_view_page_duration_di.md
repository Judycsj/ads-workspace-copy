<!-- ads-workspace-gdoc-sync: gdoc_id=1uR2_u22j81GFOFzRcGGs2ut_L1Y7HzWtkPbPUPxqJwY gdoc_url=https://docs.google.com/document/d/1uR2_u22j81GFOFzRcGGs2ut_L1Y7HzWtkPbPUPxqJwY/edit -->

# srdi_mart.dwd_sr_data_warehouse_view_page_duration_di

**分层：** DWD（明细数据层）
**主键：** `event_id`（L0）；`grass_region + source1_page_tag/source2_page_tag + request_id + item_id + location + internal_location`（L1/L2 去重 key）
**分区：** `grass_region`（大区）/ `local_date`（本地日期）/ `source_level`（数据层级，0/1/2）
**更新频率：** 每日（Daily Incremental，`_di`）
**引用频次/访问频次：** 38,057

---

## 业务描述

本表记录搜索与推荐（Search & Recommendation, SR）场景下用户在各页面的**停留时长（Page Duration）**明细，是 SRDI 数仓中衡量用户深度互动的核心 DWD 表。

**核心业务场景：**

| `source_level` | 含义 | 典型场景 |
|---|---|---|
| `0` | 基础层（L0）：页面自身浏览时长 | 用户在 DD（Daily Discover）首页、搜索结果页（SRP）、搜索发现页（SDP）、图搜页（image_search）等页面停留的时长 |
| `1` | 一跳层（L1）：从 SR 入口点击后进入的落地页时长，溯源到 L1（source1）入口 | 用户从 DD/SRP 点击进入 PDP（商品详情页）、Video（短视频页）、Minifeed、Live（直播间）所产生的时长，并关联到点击行为 |
| `2` | 二跳层（L2）：经过中间页（video/minifeed/live）再进入 PDP 的时长，溯源到 L2（source2）入口 | 用户从 DD/SRP → Video/Minifeed/Live → PDP 的二级跳转所产生的 PDP 时长 |

**适合回答的问题：**
- 用户在各 SR 页面（DD 首页、SRP、SDP、图搜等）的平均/总停留时长是多少？
- 从 SR 入口导流到 PDP/视频/直播后，用户停留时长如何？
- 按 request_id、item_id 维度分析不同搜推请求带来的用户停留深度
- 分析 DD 与 SRP 场景在各落地页类型的用户时长分布差异

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、BR 等），分区键之一 |
| `local_date` | date | 本地日期（以用户所在时区为准），分区键之一 |
| `source_level` | int | 数据层级分区：0=基础页面浏览层(L0)，1=一跳落地页时长层(L1)，2=二跳落地页时长层(L2) |

### 维度：事件与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `event_id` | string | 页面浏览/点击事件唯一标识；L0 为 view event_id，L1/L2 为 click event_id |
| `user_id` | bigint | 用户 ID，过滤条件要求 `user_id > 0` |
| `click_timestamp` | bigint | 点击事件发生的日志时间戳（毫秒）；L0 无点击行为，该字段为 null |

### 维度：场景与页面标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 一级场景标签：`dd`（Daily Discover 首页推荐）、`search`（搜索场景）、`platform`（App 全量，仅 L0） |
| `page_tag` | string | 落地页类型：`dd`、`srp`、`sdp`、`sup`（搜索联想页）、`image_search`（图搜）、`pdp`（商品详情页）、`video`（短视频页）、`minifeed`（混合信息流页）、`live`（直播间）；L0 的 platform 场景下为 null |
| `source1_page_tag` | string | 一跳来源页标签，标识用户从哪个 SR 入口页面跳转：`dd`、`srp`、`image_search`；L0 为 null，L2 表示中间页类型（`video`、`minifeed`、`live`） |
| `source2_page_tag` | string | 二跳来源页标签（L2 专用），标识 L2 链路中最初的 SR 入口页：`dd`、`srp`；L0/L1 为 null |

### 维度：请求与内容标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 搜推请求 ID，关联曝光/点击行为；L0 为 null |
| `item_id` | bigint | 被点击的商品 ID；L0 为 null，`page_tag=pdp` 时来自点击时的 item_id |
| `card_id` | bigint | 卡片内容 ID：商品类卡片取 item_id，视频/直播类卡片取 content_id（streaming_id） |
| `card_type` | string | 卡片类型：`item`、`item_mix_feed_card`、`video`、`livestream`、`ai_minifeed_card` 等，来自点击事件的 `target_type` |
| `location` | int | 点击位置（在搜推请求结果列表中的坑位序号）；L0 为 null |
| `internal_location` | int | 落地页内部位置（如视频页/直播间内的曝光位）；pdp 默认为 0，L0 为 null |

### 维度：数据质量标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `req_click_rn` | bigint | 在同一 `(grass_region, request_id, item_id, location, internal_location)` 组合内，按 `click_timestamp` 升序排列的行号；用于标记首次点击，L0 为 null |
| `is_analysis_log` | int | 是否为分析用日志标记：1=是，0=否。L0 全量为 1；L1/L2 中，pdp 类型全为 1，其他类型仅 `req_click_rn=1` 时为 1 |
| `is_sample_log` | int | 是否为采样基准日志：在 `is_analysis_log=1` 基础上，进一步要求 `internal_location=0` 才为 1，用于标记来自第一屏/首位置的数据 |

### 指标：页面停留时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `duration` | double | 页面停留时长，单位为**毫秒（ms）**。L0 来自 `traffic.dwd_view_di__reg_live` 的 `page_duration`；L1 的 pdp 时长来自同表，video 来自 `video_mart_dws_user_watch_time_ntl_1d`，live 来自 `ls_mart_dwd_view_streaming_detail_di`；L2 为二跳 PDP 时长 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区裁剪（必须）**：查询时必须指定 `local_date` 和 `grass_region`，否则将触发全量分区扫描，导致严重性能问题：
   ```sql
   WHERE grass_region = 'SG'
     AND local_date = '2026-05-17'
   ```
2. **`source_level` 分区过滤**：需根据分析需求明确指定：
   - `source_level = 0`：分析用户在各 SR 自身页面（DD/SRP/SDP 等）停留时长
   - `source_level = 1`：分析从 SR 入口点击后落地页（PDP/视频/直播等）的一跳时长
   - `source_level = 2`：分析经中间页后二跳进入 PDP 的时长
   - 混合查询（如计算全链路时长）需注意三个 source_level 之间存在**逻辑上的路径重叠**，应避免简单合并求和

3. **`is_analysis_log = 1`**：分析有效数据时建议增加此过滤，排除因 request 维度下多次点击产生的重复关联记录（L1/L2）

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `duration` | **不同 source_level 之间不可跨层 SUM**：L0 为页面自身时长，L1 为一跳落地页时长，L2 为二跳落地页时长，三者在业务上对应不同链路层级，直接跨层相加无业务意义且存在重复计算风险 |
| `duration`（L1/L2 内部） | 在未过滤 `is_analysis_log = 1` 时，同一点击行为可能对应多条关联记录（`req_click_rn > 1`），直接 SUM 会导致时长重复计算 |
| `req_click_rn` | 行号字段，无 SUM 意义 |
| `is_analysis_log` / `is_sample_log` | 标记字段，SUM 仅作计数，不代表时长或行为量 |

### 时效性说明

- 本表为 **每日增量表（`_di`）**，每天产出前一日数据，通常 T+1 可用
- 表内含 **三个 ETL 写入任务**（L0/L1/L2），各自独立写入对应 `source_level` 分区，实际数据可用时间以所有分区写入完成为准
- `local_date` 为**用户本地时区日期**（`tz_type = 'local'`），与服务器时区日期存在差异，跨时区对比分析需注意统一口径

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 核心行为日志来源，提供用户的 view（浏览）、click（点击）、impression（曝光）等事件，支撑 L0/L1/L2 各层的事件过滤与关联 |
| `traffic.dwd_view_di__reg_live` | 页面浏览时长来源，提供 `page_duration` 字段，用于 L0 页面时长（DD/SRP/SDP/图搜）及 L1 PDP 时长、L2 PDP 时长的获取；通过 `pre_click_event_id` 实现点击与浏览的逆向关联 |
| `video.video_mart_dws_user_watch_time_ntl_1d` | 视频观看时长来源，提供 `watch_duration_ntl`，用于 L1 层 video 页面的停留时长，通过 `sv_source_entry_click_id` 解析来源信息 |
| `livestream.ls_mart_dwd_view_streaming_detail_di` | 直播观看时长来源，提供 `duration_b_ms`，用于 L1/L2 层 live 页面的停留时长，通过 `view_event_id` 关联点击事件 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform  ──┐
traffic.dwd_view_di__reg_live              ──┤── L0 ETL ──► source_level=0 分区
                                            │              (DD/SRP/SDP/图搜/平台全量时长)
srdi_mart.dwd_sr_data_warehouse_platform  ──┐
traffic.dwd_view_di__reg_live              ──┤── L1 ETL ──► source_level=1 分区
video.video_mart_dws_user_watch_time_ntl   ──┤              (一跳落地页时长：PDP/Video/Minifeed/Live)
livestream.ls_mart_dwd_view_streaming_di   ──┘

srdi_mart.dwd_sr_data_warehouse_platform  ──┐
traffic.dwd_view_di__reg_live              ──┤── L2 ETL ──► source_level=2 分区
livestream.ls_mart_dwd_view_streaming_di   ──┘              (二跳 PDP 时长：经 Video/Minifeed/Live 跳转)
```

### 关键步骤

#### L0 ETL（source_level = 0）

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| 1 | `home_page_view_detail` | 从 platform 表过滤 DD 首页的 view 事件（iOS/Android App），提取 session_id、civ_id |
| 2 | `dd_impr_user_session_civ_mapping` | 从 platform 表过滤 DD 首页 daily_discover 版块的曝光事件，按 user+session+civ 去重，用于验证用户确实看到了 DD 内容 |
| 3 | `traffic_dwd_page_view_di` | 从 traffic 表获取首页 page_duration（本地时区） |
| 4 | `l0_dd_page_duration_di` | 将 view 事件 inner join 曝光映射（确认 DD 用户），再 left join traffic 时长，得到 DD 页面时长，`page_tag='dd'` |
| 5 | `l0_search_page_duration_di` | 从 traffic 表直接过滤搜索相关页面（SRP/SDP/SUP/图搜）的时长，通过 page_type 和 scenario_key 派生 page_tag |
| 6 | `union_all_l0_page_duration` | UNION ALL 合并：DD 时长（scenario_tag='dd'）+ 搜索时长（scenario_tag='search'）+ App 全量时长（scenario_tag='platform'，page_tag=null） |
| 7 | INSERT OVERWRITE | 写入 `source_level=0` 分区，is_analysis_log=1，is_sample_log=0 全量标记 |

#### L1 ETL（source_level = 1）

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| 1 | `orig_dd_search_click_event` | 从 platform 表过滤 DD/SRP/图搜的点击事件（click），提取 request_id、item_id、location、card_id、source1_page_tag 等，计算 join_content_id 和 join_location 兜底关联键 |
| 2 | `l1_sr_pdp_page_duration_di` | 从 traffic 表获取 product 页（PDP）时长，通过 `pre_click_event_id` 逆向关联到点击事件，按 pre_click_event_id 聚合（sum duration），`page_tag='pdp'` |
| 3 | `l1_sr_video_page_duration_di` | 从 video 观看时长表解析 `sv_source_entry_click_id`，获取来自 DD/SRP 导流的视频观看时长，`page_tag='video'` |
| 4 | `l1_sr_minifeed_page_duration_di` | 从 platform 表过滤 action_video 操作的 card_stay_time 事件，获取混合信息流停留时长，`page_tag='minifeed'` |
| 5 | `l1_sr_live_page_duration_di` | 从 platform 表获取直播间 view 事件，inner join 直播观看时长表，获取来自 DD/SRP 导流的直播时长，`page_tag='live'` |
| 6 | `l1_union_all_has_location` / `l1_union_all_no_location` | 按 location 是否为 null 分两路汇总 Video+Minifeed+Live 时长（group by 去重并 sum），用于后续点击事件关联 |
| 7 | `join_l1_sr_source1_event` | 以点击事件为主表，依次 left join PDP 时长（by event_id=pre_click_event_id）、has_location 时长（by request_id+content_id+location）、no_location 时长（by request_id+content_id），优先取最先命中的时长 |
| 8 | INSERT OVERWRITE（主路径） | 计算 `req_click_rn`（按 click_timestamp 窗口排序），派生 `is_analysis_log` 和 `is_sample_log`，写入 `source_level=1` 分区 |
| 9 | INSERT OVERWRITE（兜底路径） | UNION ALL 追加 DD 导流直播但 location>0 或 null 的兜底数据（新埋点上线后将移除） |

#### L2 ETL（source_level = 2）

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| 1 | `orig_dd_search_click_event` | 同 L1 逻辑，但派生字段改为 `source2_page_tag`（标识 DD/SRP 最初入口），不含图搜场景 |
| 2 | `union_all_l2_sr_source1_event` | 从 platform 表过滤在 Video/Minifeed/Live 页面内的点击行为（`original_page_type in video/streaming_room`），获取中间页点击的 request_id、content_id、location、source1_page_tag、source2_page_tag |
| 3 | `l2_sr_page_duration` | inner join traffic PDP 时长表（`pre_position_code like 'video.%' or 'streaming_room.%'`），获取经中间页跳转到 PDP 的时长，`page_tag='pdp'` |
| 4 | `l2_sr_has_location` / `l2_sr_no_location` | 按 location 是否为 null 分两路聚合，逻辑与 L1 类似 |
| 5 | `join_l2_sr_source1_event` | 以 DD/SRP 点击事件为主表，left join 二跳 PDP 时长（by source2_page_tag+request_id+content_id+location） |
| 6 | INSERT OVERWRITE（主路径+兜底路径） | 计算 `req_click_rn`（按 source2_page_tag 分组），派生分析标记，写入 `source_level=2` 分区；UNION ALL 追加 DD→直播→PDP 二跳的兜底路径（新埋点上线后移除） |

### 注意事项

1. **Multi-writer 并发写入风险**：本表由 3 个独立 ETL 文件分别写入不同 `source_level` 分区（0/1/2），各文件使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date, source_level)` 写指定分区。需确保三个任务不在同一 `source_level` 上并发写入，否则存在分区数据覆盖风险。

2. **临时视图命名冲突**：L1 和 L2 ETL 文件均定义了同名临时视图 `orig_dd_search_click_event_${grass_region_without_quote}`，但业务逻辑不同（L1 含图搜，L2 不含；L1 派生 `source1_page_tag`，L2 派生 `source2_page_tag`）。两个 SQL 文件在不同 Spark Session 执行，不会冲突，但阅读时需注意区分。

3. **duration 单位统一**：所有来源的 duration 均转换为 **double 类型的毫秒值**，但原始字段类型不一致（traffic 表为 bigint，video 表为 ntl 单位，live 表为 `duration_b_ms`），使用前应确认业务口径是否已统一换算。

4. **兜底逻辑（临时性）**：L1 和 L2 的 INSERT 均包含一段注释为"兜底拼接的逻辑，后续埋点上线，会删除掉"的 UNION ALL 分支，处理新旧埋点交替期的数据缺失问题，后续版本将移除，使用时需关注字段完整性。

5. **req_click_rn 的分区键差异**：L1 的 `req_click_rn` 按 `(source1_page_tag, request_id, item_id, location, internal_location)` 分组计算；L2 按 `(source2_page_tag, request_id, item_id, location, internal_location)` 分组计算，跨层比较时需注意分母口径差异。

---

*文档生成时间：2026-05-17*