<!-- ads-workspace-gdoc-sync: gdoc_id=19Z4cWRrA-uek2G4o9_FyM-MxeR8SiAlkYmwRlRu6FFQ gdoc_url=https://docs.google.com/document/d/19Z4cWRrA-uek2G4o9_FyM-MxeR8SiAlkYmwRlRu6FFQ/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_session_level_metrics

**分层**：DWD（明细数据层）
**主键**：`grass_region` + `local_date` + `search_session_id` + `request_id` + `item_id`
**分区**：`grass_region`（地区）/ `local_date`（本地日期）
**更新频率**：每日（T+1 批处理）
**引用频次 / 访问频次**：734

---

## 业务描述

本表是搜索域数仓的 **搜索会话级别明细宽表**，以"一次搜索请求 × 一个曝光商品"为粒度，记录 Shopee 各站点用户在搜索场景下的完整行为链路（曝光 → 点击 → 加购 → 下单）及商品、用户的维度属性。

**核心业务场景**：

- 搜索相关性分析：通过 `rel_raw`、`rel_lx`、`rel_add` 等相关性分数评估搜索结果质量
- 搜索结果行为漏斗分析：基于 `is_click`、`is_atc`、`is_order` 计算点击率、加购率、转化率
- 广告 vs. 自然结果对比：`is_ads` 标识广告商品，便于广告效果评估
- 搜索用户活跃度分析：结合 `search_activeness_type` 分层分析不同活跃度用户的搜索行为
- 商品搜索竞争力分析：结合 `price`、`item_sold_cnt`、`item_rating_score` 评估搜索曝光商品的商业属性

**适合回答的典型问题**：

- 某关键词下各位置商品的点击率/转化率分布如何？
- 不同排序方式（`sort_type`）对用户行为的影响？
- 广告商品与自然商品的曝光占比及转化差异？
- 高活跃用户 vs. 低活跃用户的搜索行为模式有何不同？
- 特定商品在搜索场景中的曝光位置和用户行为表现？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 `SG`、`MY`、`ID` 等，所有查询必须过滤此字段 |
| `local_date` | date | 数据所属本地日期（按站点时区转换后的日期），所有查询必须过滤此字段 |

### 维度：会话与请求标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `session_id` | string | 用户会话 ID，标识一次完整的用户访问会话 |
| `search_session_id` | string | 搜索会话 ID，标识用户一次搜索行为的会话粒度 |
| `request_id` | string | 搜索请求 ID，标识一次具体的搜索请求，粒度细于搜索会话 |

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID |
| `platform` | string | 访问平台，如 `ios`、`android`、`web` 等 |
| `search_activeness_type` | string | 用户搜索活跃度类型，来源于 `dws_sr_data_warehouse_user_activeness_1d`，用于用户分层分析 |

### 维度：搜索上下文

| 字段 | 类型 | 说明 |
|---|---|---|
| `query` | string | 用户搜索关键词（原始查询词） |
| `sort_type` | string | 搜索结果排序方式，如综合排序、销量排序、价格排序等 |
| `location` | int | 商品在搜索结果列表中的曝光位置（排名） |
| `is_ads` | boolean | 是否为广告商品（`true` = 广告，`false` = 自然搜索结果） |
| `imp_datetime` | string | 商品曝光时间（已按站点时区转换，格式：`yyyy-MM-dd HH:mm:ss`） |

### 维度：商品基础信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `shop_id` | string | 店铺 ID |
| `item_name` | string | 商品名称 |
| `item_images` | array\<string\> | 商品图片文件名列表（拆分后的数组） |
| `item_images_link` | string | 商品主图 CDN 访问链接，格式：`https://cf.<region_domain>/file/<图片文件名>` |
| `image_fe_link` | string | 商品前台详情页链接，格式：`https://<region_domain>/product/<shop_id>/<item_id>` |
| `image_be_link` | string | 商品后台管理页链接（Shopee Admin），含 `itemId`、`region`、`shopId` 参数 |

### 维度：商品商业属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `price` | double | 商品价格，来源于 `dim_sr_data_warehouse_item`（当日在售商品维表） |
| `item_sold_cnt` | double | 商品历史销量，来源于 `dim_sr_data_warehouse_item` |
| `item_rating_score` | double | 商品评分，来源于 `dim_sr_data_warehouse_item` |

### 维度：搜索相关性与排序规则

| 字段 | 类型 | 说明 |
|---|---|---|
| `queues` | array\<int\> | 命中的排序规则 ID 列表（`rule_ids`），标识该结果由哪些搜索规则队列产生 |
| `rel_raw` | double | 原始相关性分数（模型直接输出的相关性得分） |
| `rel_lx` | int | 离线标注相关性等级（人工或离线标注的相关性标签） |
| `rel_add` | double | 附加相关性分数（在原始分数基础上的调整值） |

### 指标：用户行为转化标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_click` | boolean | 该商品在本次请求中是否被点击（`true` = 有点击行为） |
| `is_atc` | boolean | 该商品在本次请求中是否被加入购物车（`true` = 有加购行为） |
| `is_order` | boolean | 该商品在本次请求中是否产生订单（`true` = 有下单行为） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定具体站点，禁止跨 region 不加过滤地全表扫描。该字段为分区键之一。
- **`local_date`**：必须指定日期范围，禁止省略。该字段为分区键之一，缺失将导致全量分区扫描。
- 推荐的最小过滤模板：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM / AVG 的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `is_click` / `is_atc` / `is_order` | Boolean 标识，已在 item × request 粒度去重聚合，跨 session 直接 SUM 可能重复计数 | 先确认聚合粒度，再 `SUM(CASE WHEN is_click THEN 1 ELSE 0 END)` |
| `rel_raw` / `rel_add` | 相关性分数，均值无实际业务意义，应按 query/request 分组对比 | 按 `query`、`request_id` 分组后做分布统计 |
| `item_sold_cnt` / `item_rating_score` / `price` | 商品维度属性，非增量指标，跨行 SUM 无意义 | 用于过滤、分组或与其他指标关联分析 |
| `location` | 位置序号，SUM/AVG 结果无业务含义 | 用于分组分析不同位置的转化差异 |

### 时效性说明

- 本表为 **日级批处理表**（Daily Batch），数据反映每自然日的搜索明细，通常 **T+1** 产出。
- `imp_datetime` 已按各站点本地时区完成转换，跨站点时间对比时需注意时区一致性。
- `local_date` 为站点本地日期，与 UTC 日期可能存在偏差，跨站点分析时不可将 `local_date` 视为统一时间基准。
- 商品属性字段（`price`、`item_sold_cnt`、`item_rating_score`）来源于当日维表快照（`item_status = 1` 的在售商品），下架商品可能出现 NULL 值。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_fp_search_base_1d` | 搜索基础明细表，提供用户行为（曝光、点击、加购、下单）、商品、请求等核心字段 |
| `search_data.dim_tmp_region_domain_map` | 站点与域名的映射表，用于拼接商品前后台链接和图片 CDN 链接 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表（日快照），提供价格、销量、评分等商品商业属性（仅含在售商品 `item_status = 1`） |
| `srdi_mart.dws_sr_data_warehouse_user_activeness_1d` | 用户搜索活跃度日汇总表，提供用户活跃度分层标签 `search_activeness_type` |

---

## ETL 逻辑摘要

### 数据流

```
dwd_fp_search_base_1d
        │  按 country + dt 过滤，对 item×request 粒度去重聚合行为标识
        ▼
search_base (temp view)
        │
        ├── dim_tmp_region_domain_map ──► 获取站点 region_domain（用于拼接链接）
        │
        ├── dim_sr_data_warehouse_item ──► LEFT JOIN 补充商品属性（价格/销量/评分）
        │
        └── dws_sr_data_warehouse_user_activeness_1d ──► LEFT JOIN 补充用户活跃度分层
                        │
                        ▼
              search_base_merged (temp view)
                        │  字段转换、链接拼接、类型转换
                        ▼
  INSERT OVERWRITE dwd_sr_data_warehouse_search_session_level_metrics
  PARTITION (grass_region, local_date)
```

### 关键步骤

1. **`search_base`（Temporary View）**
   - 数据源：`srdi_mart.dwd_fp_search_base_1d`，按站点和日期过滤
   - 以 `(country, dt, user_id, device_id, platform, session_id, keyword, search_session_id, sort_type, request_id, shop_id, item_id, is_ads, location, name, images, rule_ids, rel_add, rel_lx, rel_raw)` 分组
   - 聚合逻辑：`max(imp_time)` 取最晚曝光时间；`is_click`/`is_atc`/`is_order` 用 `max(CASE WHEN ... IS NOT NULL THEN 1 ELSE 0 END)` 转为 0/1 标识
   - `HAVING max(imp_time) > 0`：过滤无有效曝光时间的记录

2. **`reg_domain` & `SET region_domain`（Temporary View + 变量赋值）**
   - 从 `dim_tmp_region_domain_map` 查询当前站点的域名
   - 通过 `SET` 将域名值存入 Spark SQL 变量，供后续链接拼接使用

3. **`dim_item`（Temporary View）**
   - 数据源：`srdi_mart.dim_sr_data_warehouse_item`
   - 过滤条件：`grass_region`、`local_date`、`item_status = 1`（仅在售商品）
   - 提取字段：`item_id`、`item_sold_cnt`、`item_rating_score`、`price`

4. **`user_activeness`（Temporary View）**
   - 数据源：`srdi_mart.dws_sr_data_warehouse_user_activeness_1d`
   - 按站点和日期过滤后 `DISTINCT`，取每个 `user_id` 对应的 `search_activeness_type`

5. **`search_base_merged`（Temporary View）**
   - 将 `search_base` 与 `dim_item` 做 **LEFT JOIN**（关联键：`item_id`）
   - 将 `search_base` 与 `user_activeness` 做 **LEFT JOIN**（关联键：`user_id`）
   - 注入 `region_domain` 变量值

6. **INSERT OVERWRITE（目标表写入）**
   - 目标表：`dwd_sr_data_warehouse_search_session_level_metrics`，按 `(grass_region, local_date)` 分区覆盖写入
   - 字段转换：
     - `imp_time` → `imp_datetime`：通过 `timestamp_timezone_convert()` UDF 按站点时区转换为字符串
     - `item_images`（字符串）→ `split(item_images, ',')` → `array<string>`
     - `item_images_link`：取图片数组第一张，拼接 CDN 前缀
     - `image_fe_link`：拼接商品前台详情页 URL
     - `image_be_link`：拼接 Admin 后台管理页 URL
     - `is_click`/`is_atc`/`is_order`：0/1 整数 → `CASE WHEN ... THEN TRUE ELSE FALSE END` → boolean

### 注意事项

- **单一 Writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无并发写入风险。
- **商品属性缺失**：`dim_item` 仅包含 `item_status = 1` 的在售商品，已下架商品关联后 `price`、`item_sold_cnt`、`item_rating_score` 字段将为 **NULL**，下游使用时需注意空值处理。
- **用户活跃度缺失**：`user_activeness` 使用 LEFT JOIN，未出现在当日活跃度表中的用户 `search_activeness_type` 将为 **NULL**。
- **`item_images` 字段来源**：上游 `dwd_fp_search_base_1d` 中 `images` 为逗号分隔字符串，ETL 中通过 `split()` 转为数组写入目标表 `item_images` 字段（类型为 `array<string>`）。
- **参数化执行**：ETL 使用 `${grass_region}`、`${local_date}` 等 Spark SQL 变量进行参数化，每次执行对应一个站点一个日期分区的覆盖写入。

---

*文档生成时间：2026-05-17*