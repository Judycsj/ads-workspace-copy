<!-- ads-workspace-gdoc-sync: gdoc_id=1UWcMmYmndmTTDzIxmd2cYOmW6vV1ZeqmSH3RARnaFwU gdoc_url=https://docs.google.com/document/d/1UWcMmYmndmTTDzIxmd2cYOmW6vV1ZeqmSH3RARnaFwU/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_to_page_duration

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `grass_date` + `user_id` + `request_id` + `item_id`
**分区：** `grass_region`（大区）/ `grass_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表记录搜索结果页（SRP）用户点击进入各类目标页面后的停留时长明细数据，以 **用户 × 搜索请求 × 商品** 为粒度，汇总三类目标页面的驻留时长：

| 目标页面 | 场景说明 |
|---|---|
| PDP（商品详情页） | 用户从搜索结果点击商品后在详情页的累计停留时长 |
| 短视频页 | 用户从搜索结果进入视频卡片后的累计观看时长 |
| 直播间 | 用户从搜索结果进入直播卡片后的累计观看时长 |

**核心业务场景：**
- 评估搜索结果对各类落地页（PDP / 视频 / 直播）的引流质量与用户深度参与度
- 支持搜索排序、召回策略对用户停留时长影响的归因分析
- 作为搜索推荐 AB 实验的时长类指标明细底表

**适合回答的问题：**
- 某次搜索请求（request_id）下，特定商品的 PDP / 视频 / 直播停留时长分别是多少？
- 搜索带来的直播间观看时长在不同大区的分布如何？
- 用户维度下，搜索引流各类落地页的时长偏好画像？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），用于数据物理分区 |
| `grass_date` | date | 业务日期（本地时区），对应事件发生当天 |

### 维度：用户 & 搜索上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；由三路数据源（PDP / 视频 / 直播）FULL JOIN 后 COALESCE 取非空值 |
| `request_id` | string | 搜索请求唯一标识，来源于搜索结果页的 request_id；COALESCE 取非空值 |
| `item_id` | bigint | 商品 ID；COALESCE 取非空值 |

### 指标：各落地页停留时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_to_pdp_duration` | bigint | 用户从搜索进入 PDP（商品详情页）的累计停留时长（毫秒）；按 user_id + request_id + item_id 聚合 `page_duration` 求和 |
| `search_to_video_duration` | bigint | 用户从搜索进入短视频页的累计观看时长（单位与上游 `watch_duration_ntl` 一致）；按 vv_id 维度去重后聚合 |
| `search_to_live_duration` | double | 用户从搜索进入直播间的累计观看时长（毫秒）；由上游 `duration_b`（秒）× 1000 转换，取当日及前一日进入直播的 view 事件关联当日明细 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则触发全分区扫描，严重影响性能。示例：`WHERE grass_region = 'SG'`
- **`grass_date`**：必须指定，建议同时过滤分区日期，避免跨天全扫。示例：`AND grass_date = '2024-01-01'`

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `search_to_pdp_duration` | 已在 ETL 阶段按 `(user_id, request_id, item_id)` 预聚合，跨 item 或跨 request 二次 SUM 需明确聚合粒度，避免重复计数 |
| `search_to_video_duration` | 同上，已预聚合；且上游按 `vv_id` 去重后关联，直接跨行 SUM 可能不反映独立播放次数 |
| `search_to_live_duration` | 同上，已预聚合；时间窗口涉及 T 与 T-1 两天进入事件，跨日汇总时需注意归属日期口径 |

### 时效性说明

- 本表为 **T+1 日更新**，每日 INSERT OVERWRITE 当日分区，查询时获取的是前一个自然日的已完成数据。
- `search_to_live_duration` 的直播进入事件使用了 `local_date BETWEEN DATE_SUB(${local_date}, 1) AND ${local_date}` 的跨天窗口（兼容跨零点进入直播的场景），但最终写入的分区为当日（`grass_date = ${local_date}`），无需对查询侧做额外日期偏移。
- 三路数据源经 FULL JOIN 合并，某行中三类时长指标可能存在 NULL（表示该 user+request+item 组合在对应落地页无行为），查询时需按需处理 NULL 值。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `traffic.dwd_view_di__reg_live` | 提取搜索跳转 PDP 的页面停留时长（`page_duration`），过滤 `page_type = 'product'` 且来源为搜索场景 |
| `video.video_mart_dwd_traffic_log_full_hi` | 提取搜索结果页视频卡片（`iaa_srp_video_card`）点击进入视频页的日志，获取 vv_id 与 item_id |
| `video.video_mart_dws_user_watch_time_ntl_1d` | 提供视频 vv_id 维度的实际观看时长（`watch_duration_ntl`） |
| `traffic.shopee_traffic_dwd_view_hi__reg_s1_live` | 提取搜索结果页直播卡片（`global_search_srp_live_card_entry`）进入直播间的 view 事件，获取 event_id 与 item_id |
| `livestream.ls_mart_dwd_view_streaming_detail_di` | 提供直播 view_event_id 维度的实际观看时长（`duration_b`，单位秒） |

---

## ETL 逻辑摘要

### 数据流

```
traffic.dwd_view_di__reg_live
        │ (PDP页停留)
        ▼
search_to_pdp_duration [tmp]
        │
        ├──────────────────────────────────────────────────┐
video.video_mart_dwd_traffic_log_full_hi                   │
        │ (视频进入日志)                                    │
        ▼                                                   │
video_mart_traffic_log [tmp]                               │
        │                                                   │
video.video_mart_dws_user_watch_time_ntl_1d               │
        │ JOIN by vv_id                                     │
        ▼                                                   │
search_to_video_duration [tmp]                             │
        │                                                   ▼
        │                            traffic.shopee_traffic_dwd_view_hi__reg_s1_live
        │                                    │ (直播进入日志)
        │                                    ▼
        │                            livestream_view_link [tmp]
        │                                    │
        │                            livestream.ls_mart_dwd_view_streaming_detail_di
        │                                    │ JOIN by event_id
        │                                    ▼
        │                            search_to_live_duration [tmp]
        │                                    │
        └──────────────┬─────────────────────┘
                       │ FULL JOIN × FULL JOIN
                       ▼
    srdi_mart.dwd_sr_data_warehouse_search_to_page_duration
```

### 关键步骤

1. **Statement 1 — `search_to_pdp_duration` 临时视图**
   从流量宽表过滤 `page_type = 'product'` 且前向来源为搜索场景（`pre_position_code LIKE 'search.%'`，scenario_key 限定为全局搜索 / PDP 搜索 / 预填充搜索），按 `(user_id, request_id, item_id)` 聚合 `page_duration` 得到 PDP 累计停留时长。

2. **Statement 2 — `video_mart_traffic_log` 临时视图**
   从视频流量日志过滤来自搜索结果页视频卡片的播放行为（`page=video`、`target_type=video_play_time`、来源页为 `iaa_srp_video_card`），解析 JSON 字段提取 `request_id`、`item_id`，按 `(user_id, request_id, item_id, vv_id)` 去重。

3. **Statement 3 — `search_to_video_duration` 临时视图**
   将 Statement 2 结果与视频观看时长表按 `vv_id` JOIN，按 `(user_id, request_id, item_id)` 聚合 `watch_duration_ntl` 得到视频累计观看时长。

4. **Statement 4 — `livestream_view_link` 临时视图**
   从直播流量日志过滤来自搜索结果页直播卡片的进入事件（`from_source = 'global_search_srp_live_card_entry'`、`operation = 'view'`），解析 JSON 提取 `request_id`、`item_id` 及 `event_id`；时间窗口取 T-1 至 T 两天以兼容跨零点场景。

5. **Statement 5 — `search_to_live_duration` 临时视图**
   将 Statement 4 结果与直播观看明细表按 `event_id = view_event_id` JOIN，将 `duration_b`（秒）× 1000 转换为毫秒，按 `(user_id, request_id, item_id)` 聚合得到直播累计观看时长。

6. **Statement 6 — INSERT OVERWRITE 写目标表**
   将三路临时视图以 FULL JOIN 方式合并（先 PDP FULL JOIN 视频，再 FULL JOIN 直播），主键字段使用 COALESCE 取非空值，写入目标表当日分区。

### 注意事项

- **单 writer**：本表仅由单一 ETL 文件写入，不存在多 writer 并发冲突风险。
- **FULL JOIN 导致的 NULL**：三路数据并非所有 `(user_id, request_id, item_id)` 组合都在三个渠道同时有行为，指标字段可能为 NULL，下游使用时需用 `COALESCE` 或 `IS NOT NULL` 过滤。
- **直播跨天时间窗口**：`livestream_view_link` 读取 T-1 到 T 两天的进入事件，但聚合后写入日期为 T，若同一 event_id 在 T-1 到 T 之间存在重复日志，可能导致时长偏高，需关注上游数据质量。
- **分区覆盖**：INSERT OVERWRITE 按 `(grass_region, grass_date)` 分区写入，重跑时会完整覆盖当日分区，需确保上游数据已就绪再触发任务，避免以不完整数据覆盖已有分区。
- **`grass_region_without_quote` 模板变量**：临时视图名称中含大区标识后缀，用于防止多区域任务并发时视图名冲突，不影响最终数据语义。

---

*文档生成时间：2026-05-18*