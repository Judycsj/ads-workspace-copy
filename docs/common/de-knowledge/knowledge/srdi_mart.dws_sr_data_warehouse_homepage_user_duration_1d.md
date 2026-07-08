<!-- ads-workspace-gdoc-sync: gdoc_id=1rIjGfRf7-UrE5x_ELaRepgbHMFRPz9grFfw92u-i4Mg gdoc_url=https://docs.google.com/document/d/1rIjGfRf7-UrE5x_ELaRepgbHMFRPz9grFfw92u-i4Mg/edit -->

# srdi_mart.dws_sr_data_warehouse_homepage_user_duration_1d

**分层：** DWS（数据服务层）
**主键：** `user_id` + `grass_region` + `local_date`
**分区：** `grass_region`（地区）, `local_date`（本地日期）
**更新频率：** 每日（T+1）
**访问频次：** 590

---

## 业务描述

本表记录**首页 Daily Discover（每日发现）模块**中，每位用户在各类内容场景下的**每日时长消费明细**，粒度为用户 × 地区 × 日期。

核心业务场景：
- 衡量用户在首页 Daily Discover 入口停留、浏览商品详情页（PDP）、观看短视频、直播等行为的时长贡献；
- 区分有机流量与广告流量来源的 PDP 时长；
- 追踪来自混合 Feed（Mix Feed）、Mini Feed、视频落地页、直播落地页等子场景的用户深度；
- 支持新品到达（New Arrival）和最低价（Cheapest）运营卡片的 PDP 时长分析。

适合回答的典型问题：
- 某地区某日，用户在 Daily Discover 封面区的平均停留时长是多少？
- 广告商品 PDP 时长与自然流量 PDP 时长的比例如何？
- 用户通过视频落地页跳转直播的时长趋势如何变化？
- Mini Feed、Mix Feed 各子模块的时长分布如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地理区域标识，用于按区域切分数据分区 |
| `local_date` | date | 数据对应的本地日期，用于按天分区 |

### 维度：用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID，为当日在 Daily Discover 有行为的用户唯一标识 |

### 指标：Daily Discover 主入口时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_cover_duration_1d` | double | 用户在首页 Daily Discover 封面/Feed 区的停留时长（秒），源自 `home_dd_stay_impression_duration`，原始毫秒值 ÷ 1000 |
| `dd_pdp_duration_1d` | double | 用户从 Daily Discover 进入商品详情页（PDP）的停留时长（秒），原始毫秒值 ÷ 1000 |

### 指标：Mini Feed 相关时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_minifeed_duration_1d` | double | 用户在 Mini Detail Feed 区域的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_minifeed_pdp_duraion_1d` | double | 用户从 Mini Feed 商品卡进入 PDP 的停留时长（秒）；注意字段名中 `duraion` 为拼写错误，与建表保持一致；原始毫秒值 ÷ 1000 |

### 指标：视频相关时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_video_duration_1d` | double | 用户在 Daily Discover 视频页（包含视频卡片 `iaa_dd_video_card` 来源）的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_video_pdp_duration_1d` | double | 用户从 Daily Discover 视频入口进入商品 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_video_landing_page_duration` | double | 用户在视频落地页的停留时长（秒），当前逻辑与 `dd_video_duration_1d` 取值相同（均来自 `dd_video_page_duration_1d` 汇总），原始毫秒值 ÷ 1000 |
| `dd_video_landing_livestream_duration_1d` | double | 用户通过视频落地页（`dd_common_video_feed_page`）进入直播间的观看时长（秒），单位已为秒，不再除以 1000 |

### 指标：直播相关时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_live_duration_1d` | double | 用户在 Daily Discover 直播卡片（`dd_card`）的观看时长（秒），单位已为秒，不再除以 1000 |
| `dd_live_pdp_duration_1d` | double | 用户从 Daily Discover 直播入口进入商品 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_item_mix_landing_livestream_duration_1d` | double | 用户通过 Mix Feed 落地页（`dd_mix_item_mix_feed_page`）进入直播间的观看时长（秒），单位已为秒，不再除以 1000 |

### 指标：Mix Feed 相关时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_mixfeed_duration_1d` | double | 用户在 Daily Discover Mix Feed 页面（`iaa_dd_mix_item` 来源）的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_mixfeed_pdp_duration_1d` | double | 用户从 Daily Discover Item Mix Feed 卡片进入 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |

### 指标：有机/广告商品 PDP 时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_organic_item_pdp_duration_1d` | double | 用户点击自然流量商品卡（`item card`，非广告）后在 PDP 的停留时长（秒），过滤 `is_ads=false` 且时长在 [0, 3600000] ms 范围内，原始毫秒值 ÷ 1000 |
| `dd_organic_item_mix_feed_pdp_duration_1d` | double | 用户点击自然流量 Mix Feed 卡（`mix feed card`，非广告）后在 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_ads_item_pdp_duration_1d` | double | 用户点击广告商品卡（`item card`，`is_ads=true`）后在 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |
| `dd_ads_item_mix_feed_pdp_duration_1d` | double | 用户点击广告 Mix Feed 卡（`mix feed card`，`is_ads=true`）后在 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |

### 指标：运营专题卡片 PDP 时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `new_arrival_pdp_duration_1d` | double | 用户从新品到达卡片（`home-daily_discover-new_arrival_card`）进入 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |
| `cheapest_pdp_duration_1d` | double | 用户从最低价落地卡片（`home-daily_discover-cheapest_landing_card`）进入 PDP 的停留时长（秒），原始毫秒值 ÷ 1000 |

### 指标：平台整体时长

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_duration_1d` | double | 用户在平台整体页面的停留时长（秒），来自流量层 `page_duration` 汇总，原始毫秒值 ÷ 1000 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 分区过滤**，否则将触发全表扫描，产生大量不必要的资源消耗：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

- 本表所有时长字段均为**用户粒度预聚合值**，可跨用户 `SUM` 以计算总时长，但不应再对同一用户的同一字段重复累加。
- `dd_video_duration_1d` 与 `dd_video_landing_page_duration` 在当前 ETL 中取值逻辑相同（均来自 `dd_video_page_duration_1d`），若同时 SUM 两列会导致重复计数，请按业务含义择一使用。
- `dd_live_duration_1d`、`dd_video_landing_livestream_duration_1d`、`dd_item_mix_landing_livestream_duration_1d` 三个直播时长字段单位为**秒**，其余时长字段也均为秒（ETL 已完成 ÷1000 换算），但上游数据源精度不同，混合使用时需注意。

### 时效性说明

- 本表为 **`_1d` 日粒度快照表**，每日调度一次，数据通常在 T+1 日产出。
- `local_date` 表示**本地时区日期**，与 UTC 日期存在时差，跨区域对比时需注意时区对齐。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | Daily Discover 主入口的用户停留时长、PDP 时长、Mini Feed、视频/直播 PDP 时长 |
| `video.video_mart_dws_external_dd_mixfeed_ssecid_user_1d` | 视频卡片及 Mix Feed 卡片的用户页面停留时长（外部视频域） |
| `livestream.ls_mart_dwd_view_streaming_detail_di` | 用户通过 DD 卡片、视频落地页、Mix Feed 落地页进入直播间的观看时长 |
| `traffic.dwd_view_di__reg_live` | 平台整体页面停留时长 |
| `${schema}.dwm_sr_data_warehouse_homepage_user_item` | 有机/广告商品 PDP 时长、New Arrival 卡片及 Cheapest 卡片 PDP 时长 |
| `video.video_mart_dws_ls_content_minils_userid_cp_ssp_vft_aggr_1d` | Mini 直播（miniLS）在视频/Mix Feed 落地页的观看时长 |

---

## ETL 逻辑摘要

### 数据流

多个上游异构数据源（商品行为域、视频域、直播域、流量域）→ 临时视图 `detail_data_${grass_region_without_quote}`（宽行 UNION ALL 拼接）→ 按 `user_id` 聚合 + 单位换算（ms → s）→ `INSERT OVERWRITE` 写入目标分区。

### 关键步骤

**Step 1：创建临时视图 `detail_data_${grass_region_without_quote}`**

通过 6 段 `UNION ALL` 将不同来源数据拉平为统一宽表结构（21 个中间指标列），每段仅填充本源相关字段，其余字段补 0：

| UNION 段 | 数据源 | 主要产出字段 |
|---|---|---|
| ① | `dwm_sr_data_warehouse_platform_user_item` | `home_dd_stay_duration`、`home_dd_pdp_duration`、Mini Feed、视频/直播/Mix PDP 时长 |
| ② | `video_mart_dws_external_dd_mixfeed_ssecid_user_1d` | `dd_video_page_duration`（video_card）、`dd_video_mix_feed_page_duration`（mix_item） |
| ③ | `ls_mart_dwd_view_streaming_detail_di` | `dd_livestream_page_duration`、`dd_video_landing_livestream`、`dd_item_mix_landing_livestream` |
| ④ | `dwd_view_di__reg_live` | `platform_page_duration` |
| ⑤ | `dwm_sr_data_warehouse_homepage_user_item` | 有机/广告 PDP 时长、`new_arrival_pdp`、`cheapest_pdp` |
| ⑥ | `video_mart_dws_ls_content_minils_userid_cp_ssp_vft_aggr_1d` | Mini 直播场景的 `dd_video_page_duration`、`dd_video_mix_feed_page_duration` |

**Step 2：INSERT OVERWRITE 写入目标表**

对临时视图按 `user_id` 做 `SUM` 聚合，并对大部分毫秒单位指标做 `÷ 1000` 换算为秒，直播相关字段（来源已为秒）不做除法，最终写入目标分区 `(grass_region, local_date)`。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件，无多写风险，同一分区不存在并发覆盖问题。
- **动态参数分区**：ETL 使用 `${grass_region}` / `${local_date}` 参数化，每次执行仅覆盖单一 `(grass_region, local_date)` 分区，使用 `INSERT OVERWRITE ... PARTITION(...)` 模式，重跑安全。
- **`dd_video_duration_1d` 与 `dd_video_landing_page_duration` 重复**：两个目标字段均由中间列 `dd_video_page_duration_1d` 聚合而来，数值完全相同，查询时避免同时累加。
- **直播时长单位**：`dd_live_duration_1d`、`dd_video_landing_livestream_duration_1d`、`dd_item_mix_landing_livestream_duration_1d` 未做 ÷ 1000，其原始数据来源（直播域）已以秒为单位；与其他字段做跨模块对比时需确认单位一致。
- **Mini 直播重叠**：UNION 段 ② 和 ⑥ 均向 `dd_video_page_duration_1d` 和 `dd_video_mix_feed_page_duration_1d` 贡献数据，两者分别来自外部视频 Feed 和 Mini 直播内容，最终由 SUM 合并，属于有意设计。
- **PDP 时长过滤**：有机/广告 PDP 时长字段在 ETL 层已过滤 `page_stay_duration` 在 `[0, 3600000]` ms 区间，异常超长会话已被排除。

---

*文档生成时间：2026-05-17*