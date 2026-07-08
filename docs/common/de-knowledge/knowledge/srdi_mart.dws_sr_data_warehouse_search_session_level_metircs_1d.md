<!-- ads-workspace-gdoc-sync: gdoc_id=1mTKMdu01oGWIGIaHIBBEfpy2yS1qScoEYX3TOPDtOXk gdoc_url=https://docs.google.com/document/d/1mTKMdu01oGWIGIaHIBBEfpy2yS1qScoEYX3TOPDtOXk/edit -->

# srdi_mart.dws_sr_data_warehouse_search_session_level_metircs_1d

**分层：** dws_search
**主键：** `user_id` + `search_session_id` + `global_session_id` + `search_entrance` + `search_mid` + `keyword`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次 / 访问频次：** 733

---

## 业务描述

本表是搜索域 **会话（Session）粒度** 的日级聚合宽表，每行对应一个用户在某次搜索会话中针对特定关键词的完整行为快照。

**核心业务场景：**

- 分析单次搜索会话内用户的曝光、点击、下单转化漏斗；
- 评估商品（item）、直播（livestream）、视频（video）三类内容在搜索结果页的表现；
- 对比广告（ads）与自然结果（organic）的曝光、点击、GMV 贡献；
- 分析用户首次点击行为（位置、内容类型）及位置分布（top1 / top4 / top20）；
- 识别无召回（no recall）会话及店铺曝光会话；
- 结合用户画像（年龄、性别）进行搜索行为的人群分层分析。

**适合回答的问题举例：**

- 某关键词在某站点某日的搜索会话点击率 / 转化率是多少？
- 广告位与自然结果的 GMV 贡献各占多少？
- 用户首次点击集中在哪些位置？
- 无召回会话占比如何随时间变化？
- 不同性别 / 年龄段用户的搜索转化表现是否存在差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点 / 区域标识，如 `SG`、`MY` 等，所有查询必须指定 |
| `local_date` | date | 业务日期（本地时区），所有查询必须指定 |

---

### 维度：会话与搜索标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `search_session_id` | string | 搜索会话 ID，标识一次连续的搜索行为 |
| `global_session_id` | string | 全局会话 ID，跨搜索会话的用户访问会话标识 |
| `session_id` | string | 页面会话 ID，取该 search_session 首次 view 事件对应的 session_id |
| `search_mid` | string | 搜索中间态标识（search mid），空值时以空字符串填充 |
| `keyword` | string | 搜索关键词（已做 trim + lower 标准化处理） |
| `search_entrance` | string | 搜索入口标识 |
| `page_type` | string | 页面类型，取该 search_session 首次 view 事件的 page_type，枚举值：`global_search`、`search_in_pdp`、`search_prefill` |
| `search_time` | bigint | 该搜索会话首次 view 事件的时间戳（Unix 毫秒） |

---

### 维度：用户画像

| 字段 | 类型 | 说明 |
|---|---|---|
| `gender` | string | 用户性别，枚举值：`Male`、`Female`、`Unknown`，来自用户维度表 |
| `age` | int | 用户年龄，来自用户维度表 |

---

### 维度：会话特征标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_no_recall` | boolean | 该会话是否存在无召回曝光（target_type = `no_recall_general` 且 operation = `impression`） |
| `is_shop_imp` | boolean | 该会话是否存在店铺曝光（target_type = `shop` 且 operation = `impression`） |
| `first_click_type` | string | 首次点击的内容类型（target_type），仅对 item / video / livestream 类型生效 |

---

### 指标：曝光指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | int | 全类型（item + video + livestream）总曝光次数（含广告与自然） |
| `distinct_imp_cnt` | int | 全类型去重曝光内容数（按 content_id / item_id 去重） |
| `imp_request_cnt` | int | 曝光请求去重数（按 request_id 去重），可近似代表搜索翻页次数 |
| `max_imp_location` | int | 本会话最大曝光位置（位置序号最大值） |
| `item_imp_cnt_org` | int | 商品自然结果曝光次数 |
| `item_imp_cnt_ads` | int | 商品广告结果曝光次数 |
| `distinct_item_imp_cnt` | int | 商品去重曝光数 |
| `video_imp_cnt` | int | 视频曝光次数 |
| `distinct_video_imp_cnt` | int | 视频去重曝光数 |
| `live_imp_cnt` | int | 直播曝光次数 |
| `distinct_live_imp_cnt` | int | 直播去重曝光数 |

---

### 指标：点击指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | int | 全类型总点击次数 |
| `distinct_click_cnt` | int | 全类型去重点击内容数 |
| `click_top1` | int | 位置为 0（第 1 位）的全类型点击次数 |
| `click_top4` | int | 位置 < 4（前 4 位）的全类型点击次数 |
| `click_top20` | int | 位置 < 20（前 20 位）的全类型点击次数 |
| `first_click_location` | int | 首次点击（时间最早）的位置序号，仅统计 item / video / livestream |
| `item_click_cnt_org` | int | 商品自然结果点击次数 |
| `item_click_cnt_ads` | int | 商品广告结果点击次数 |
| `distinct_item_click_cnt` | int | 商品去重点击数 |
| `video_click_cnt` | int | 视频点击次数 |
| `distinct_video_click_cnt` | int | 视频去重点击数 |
| `live_click_cnt` | int | 直播点击次数 |
| `distinct_live_click_cnt` | int | 直播去重点击数 |

---

### 指标：订单与 GMV 指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 全类型总下单次数（含广告与自然，支持 source1 / source2 归因） |
| `distinct_order_cnt` | int | 全类型去重下单商品数 |
| `gmv` | double | 全类型总 GMV（下单金额） |
| `avg_order_location` | double | 下单商品的平均位置（基于去重位置取均值），**不可直接 SUM** |
| `item_order_cnt_org` | double | 商品自然结果下单次数 |
| `item_order_cnt_ads` | double | 商品广告结果下单次数 |
| `item_gmv_org` | double | 商品自然结果 GMV |
| `item_gmv_ads` | double | 商品广告结果 GMV |
| `distinct_item_order_cnt` | int | 商品去重下单数 |
| `video_order_cnt` | double | 视频下单次数 |
| `video_gmv` | double | 视频 GMV |
| `distinct_video_order_cnt` | int | 视频去重下单数 |
| `live_order_cnt` | double | 直播下单次数 |
| `live_gmv` | double | 直播 GMV |
| `distinct_live_order_cnt` | int | 直播去重下单数 |

---

## 查询使用须知

### 必须指定的过滤条件

```sql
WHERE grass_region = 'SG'   -- 必须指定，否则全分区扫描
  AND local_date = '2024-01-01'  -- 必须指定，日期范围建议精确到天
```

多天查询时使用 `local_date BETWEEN '2024-01-01' AND '2024-01-07'`。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `avg_order_location` | 预聚合均值（`AVG(DISTINCT ...)`），跨行 SUM 无业务意义 | 需回溯明细或加权重新计算 |
| `distinct_imp_cnt` | 会话内去重计数，跨会话求和存在重复，不代表全局去重数 | 仅用于单会话分析，跨会话需重新 COUNT DISTINCT |
| `distinct_click_cnt` | 同上 | 同上 |
| `distinct_order_cnt` | 同上 | 同上 |
| `distinct_item_imp_cnt` / `distinct_item_click_cnt` / `distinct_item_order_cnt` | 同上 | 同上 |
| `distinct_video_*` / `distinct_live_*` | 同上 | 同上 |
| `first_click_location` | 会话级别的首次点击位置，SUM 无意义 | 使用 AVG / PERCENTILE 等聚合 |

### 时效性说明

- 本表为 **日级全量覆写表**（`INSERT OVERWRITE PARTITION`），每日 T+1 产出，数据代表自然日内的完整行为。
- `local_date` 为本地时区日期，不同 `grass_region` 可能存在时区差异，跨站点对比时需注意。
- 表名后缀 `_1d` 表示单日快照，不包含滚动窗口累计数据。

### 其他注意事项

- 本表仅保留 **存在 view 事件** 的搜索会话（ETL 最终写入时过滤 `is_view = true`），纯曝光或纯点击但无 view 的会话不计入。
- `order_cnt`、`item_order_cnt_org` 等订单类字段类型为 `double`，因 ETL 中使用 `SUM` 聚合 `operation_cnt`（可能为小数权重），求和时需注意精度。
- 订单数据包含 **最多三路归因**（主归因 + source1 + source2），同一订单可能被计入多条搜索会话，分析全站订单总量时应避免使用本表直接汇总。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索事件明细表，提供 impression / click / order / view 四类行为事件，包含主归因、source1、source2 三路订单归因字段 |
| `srdi_mart.dim_sr_data_warehouse_user` | 用户维度表，提供用户性别（gender）和年龄（age）画像信息 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search
  ├── 主归因（impression / click / order / view）
  ├── source1 订单归因（order，source1_feature_detail != feature_detail）
  └── source2 订单归因（order，source2_feature_detail != source1_feature_detail 且 != feature_detail）
          │
          ▼
    [Temp View] dwd_search_${region}      ← UNION ALL 三路数据，计算 time_rank / view_time_rank
          │
          ├──▶ [Temp View] dws_search_main_${region}   ← 按会话聚合主要行为指标
          ├──▶ [Temp View] dws_search_other_${region}  ← 计算 is_shop_imp / is_no_recall
          └──▶ [Temp View] dim_user_${region}           ← 提取用户画像
                    │
                    ▼
    INSERT OVERWRITE dws_sr_data_warehouse_search_session_level_metircs_1d
    （三表 LEFT JOIN，过滤 is_view = true）
```

### 关键步骤

**Step 1 — Temp View `dwd_search`（数据清洗与合并）**

- 从 `dwd_sr_data_warehouse_search` 抽取当日当站点数据，过滤 page_type 为 `global_search` / `search_in_pdp` / `search_prefill`，且 `search_session_id` 不为空的记录；
- 通过 UNION ALL 合并三路数据：主归因（impression + click + order + view）、source1 订单归因、source2 订单归因；
- 使用窗口函数计算 `time_rank`（点击事件按会话+用户+操作类型的时间排名）和 `view_time_rank`（view 事件排名），用于后续提取首次行为；
- 关键词做 `trim(lower(...))` 标准化；`search_mid` 空值填充为空字符串。

**Step 2 — Temp View `dws_search_main`（会话级主要指标聚合）**

- 以 `(user_id, search_session_id, global_session_id, search_entrance, search_mid, keyword)` 为 GROUP BY 键；
- 分别按 target_type（item / video / livestream）和 is_ads（true / false）计算各类曝光、点击、订单、GMV 的 SUM 及 COUNT DISTINCT；
- 计算位置相关指标：`max_imp_location`、`click_top1` / `click_top4` / `click_top20`、`first_click_location`（`time_rank = 1` 的首次点击位置）、`avg_order_location`；
- 取首次 view 事件的 `page_type`、`session_id`、`search_time`；
- 生成 `is_view` 标记，供最终写入时过滤使用。

**Step 3 — Temp View `dws_search_other`（补充会话特征标识）**

- 仅对 impression 事件聚合，按会话识别 `is_shop_imp`（是否有店铺曝光）和 `is_no_recall`（是否有无召回曝光）；
- GROUP BY 与主表一致（`user_id, search_session_id, global_session_id, keyword`）。

**Step 4 — Temp View `dim_user`（用户画像提取）**

- 从 `dim_sr_data_warehouse_user` 取当日用户性别（gender 编码映射为 Male / Female / Unknown）和年龄；
- 过滤 `user_id > 0`，以 `user_id` 为粒度聚合（FIRST）。

**Step 5 — INSERT OVERWRITE（写入目标分区）**

- 以 `dws_search_main` 为主表，LEFT JOIN `dim_user`（on `user_id`）、LEFT JOIN `dws_search_other`（on `user_id <=> c.user_id AND search_session_id AND global_session_id <=> AND keyword <=>`，使用 `<=>` 处理 NULL 安全等值）；
- 最终过滤 `is_view = true`，仅保留存在 view 事件的搜索会话；
- 按 `grass_region` + `local_date` 分区覆写写入。

### 注意事项

- **单文件单写：** 本表为单 ETL 文件、单 writer，不存在多文件并发写入同一分区的风险。
- **分区覆写：** 每次执行对指定 `(grass_region, local_date)` 分区做 `INSERT OVERWRITE`，重跑幂等，但会覆盖当日数据，回溯时需逐分区执行。
- **NULL 安全 JOIN：** `dws_search_other` 与主表的 JOIN 使用 `<=>` 操作符，`global_session_id` 和 `keyword` 为 NULL 时仍可正确关联。
- **参数化分区：** SQL 中使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等模板变量，不同站点对应独立的 Temp View 命名空间，避免多站点并发执行时的命名冲突。
- **订单多路归因导致重复计数：** source1 / source2 订单归因将同一笔订单拆分归因到不同搜索会话，汇总全站订单时存在重复，需在业务层去重处理。
- **`order_cnt` 精度：** 订单相关字段类型为 `double`，源自 `operation_cnt`（可能含权重），跨会话累加时需关注精度和业务口径一致性。

---

*文档生成时间：2026-05-17*