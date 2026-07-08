<!-- ads-workspace-gdoc-sync: gdoc_id=1g_YDgpwoCcEz0YOrkU8CxXP32Zj6Dn0Lv88qmFLQd2Y gdoc_url=https://docs.google.com/document/d/1g_YDgpwoCcEz0YOrkU8CxXP32Zj6Dn0Lv88qmFLQd2Y/edit -->

# srdi_mart.dwm_sr_data_warehouse_image_search_user

**分层：** DWM（数据仓库中间层）
**主键：** `user_id` + `platform` + `md5` + `feature_detail` + `page_type` + `page_section` + `target_type` + `search_entrance` + `image_source` + `liked` + `is_ads` + `camera_page_version` + `local_hour` + `regional_date` + `regional_hour` + `operation`（联合唯一）
**分区：** `grass_region` / `local_date` / `local_hour` / `regional_date` / `regional_hour` / `operation`
**更新频率：** 按小时分区增量覆盖写入（INSERT OVERWRITE，逐小时调度）
**引用频次/访问频次：** 647

---

## 业务描述

本表是**图搜（以图搜物）业务**的用户级别汇总中间层，记录用户在图搜全链路各环节（曝光、点击、浏览、加购、下单）的行为聚合指标，以及关联的商品相似度、广告标记、入口来源等维度信息。

**核心业务场景：**
- 分析图搜入口（拍照、相册、相似商品等）的流量漏斗（曝光→点击→浏览→加购→下单）
- 评估不同图搜来源（`image_source`）、搜索入口（`search_entrance`）的用户行为差异
- 计算图搜结果页 Top1 商品的相似度分布，评估图搜算法质量
- 监控图搜广告（`is_ads`）流量对用户行为及 GMV 的贡献
- 支持用户粒度的图搜会话归因分析（`md5` 唯一标识搜索图片）

**适合回答的问题：**
- 各站点/日期/小时维度下，图搜各入口的曝光量、点击率、加购率、转化率如何？
- 不同平台/页面类型下，图搜 GMV 及本地货币 GMV 贡献如何？
- 图搜结果页 Top1 商品的平均相似度（`top1_similarity_sum / top1_item_imp_cnt`）趋势如何？
- 用户在图搜结果页点击/加购商品的平均位置（`click_location_sum / click_cnt`）变化情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 `SG`、`MY`、`TH` 等，每次写入时固定注入分区 |
| `local_date` | date | 事件发生的本地日期（按站点本地时区），每次写入时固定注入分区 |
| `local_hour` | int | 事件发生的本地小时（0~23），动态分区字段 |
| `regional_date` | date | 事件发生的区域标准日期，动态分区字段 |
| `regional_hour` | int | 事件发生的区域标准小时（0~23），动态分区字段 |
| `operation` | string | 用户行为类型，如 `impression`、`click`、`ppv`、`view`、`cart`、`order`，动态分区字段 |

---

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识 |
| `platform` | string | 客户端平台，如 `android`、`ios` |

---

### 维度：图搜会话与图片

| 字段 | 类型 | 说明 |
|---|---|---|
| `md5` | string | 搜索图片的 MD5 哈希值，唯一标识一次图搜会话使用的图片 |
| `feature_detail` | string | 图片特征详情，来自算法侧的图片特征描述 |
| `image_source` | string | 图片来源，如拍照（camera）、相册（album）等；对于 PDP 点赞事件通过 self-join 回填 |

---

### 维度：页面与交互

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_type` | string | 页面类型，如 `image_search`（图搜结果页）、`product`（商品详情页）、`search` 等 |
| `page_section` | array\<string\> | 页面区块列表，标识事件发生的页面子区域 |
| `target_type` | string | 操作目标类型，如 `item`（商品）、`image_search_button`、`like_button` 等 |
| `search_entrance` | string | 图搜入口标识；对于图搜按钮曝光/点击事件，按 `page_type` 重新映射：`home`→`Home`、`pre_search`→`PRESEARCH`、`search`→`SEARCH_RESULT`、`find_similar_products`→`find_similar`、`mall`→`MALL`；其他场景沿用原始值 |
| `camera_page_version` | string | 拍照页版本号，用于区分不同版本的摄像头入口 |

---

### 维度：商品属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `liked` | boolean | 用户是否点赞该商品 |
| `is_ads` | boolean | 是否为广告商品，空值默认补 `false` |

---

### 指标：流量漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数，统计 `operation = 'impression'` 的事件计数之和 |
| `click_cnt` | bigint | 点击次数，统计 `operation = 'click'` 的事件计数之和 |
| `ppv_cnt` | double | 商品详情页浏览次数（排除回退行为），统计 `operation = 'ppv'` 且 `is_back = false` 的事件计数之和 |
| `view_cnt` | double | 页面浏览次数（排除回退行为），统计 `operation = 'view'` 且 `is_back = false` 的事件计数之和 |
| `cart_cnt` | double | 加购次数，统计 `operation = 'cart'` 的事件计数之和 |
| `order_cnt` | double | 下单次数，统计 `operation = 'order'` 的事件计数之和 |

---

### 指标：成交金额

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 下单 GMV（美元），统计 `operation = 'order'` 时的 `place_order_gmv` 之和 |
| `gmv_local` | double | 下单 GMV（本地货币），统计 `operation = 'order'` 时的 `place_order_gmv_local` 之和 |

---

### 指标：位置与相似度

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_location_sum` | bigint | 图搜结果页商品点击位置累加值（`page_type='image_search'` AND `target_type='item'` AND `operation='click'`），除以 `click_cnt` 可得平均点击位置 |
| `atc_location_sum` | bigint | 图搜结果页商品加购位置累加值（`page_type='image_search'` AND `target_type='item'` AND `operation='cart'`），对应 ETL 中的 `cart_location_sum`，除以 `cart_cnt` 可得平均加购位置 |
| `top1_similarity_sum` | double | 图搜结果页首位（location=0）商品相似度累加值，除以 `top1_item_imp_cnt` 可得 Top1 平均相似度 |
| `top1_item_imp_cnt` | bigint | 图搜结果页首位（location=0）商品曝光次数，用于计算 Top1 平均相似度的分母 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定站点，否则全表扫描开销极大。示例：`WHERE grass_region = 'SG'`
- **`local_date`**：必须指定日期范围，与 `grass_region` 共同构成最粗粒度分区。示例：`AND local_date = '2025-01-01'`
- 如需进一步缩小范围，可追加 `local_hour`、`regional_date`、`regional_hour`、`operation` 过滤条件，以减少读取的动态分区数量
- 本表按小时粒度分区，在多小时聚合查询时需明确 `local_hour IN (...)` 或范围条件

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确用法 |
|---|---|---|
| `click_location_sum` | 预聚合累加值，直接跨行 SUM 后需配合 `click_cnt` 计算均值 | `SUM(click_location_sum) / SUM(click_cnt)` |
| `atc_location_sum` | 同上，预聚合累加值 | `SUM(atc_location_sum) / SUM(cart_cnt)` |
| `top1_similarity_sum` | 预聚合累加值，需配合 `top1_item_imp_cnt` | `SUM(top1_similarity_sum) / SUM(top1_item_imp_cnt)` |
| `top1_item_imp_cnt` | 分母字段，单独 SUM 无业务意义 | 与 `top1_similarity_sum` 配合使用 |
| `ppv_cnt`、`view_cnt`、`cart_cnt`、`order_cnt`、`gmv`、`gmv_local` | 类型为 double，已在用户粒度做过聚合，跨不同 `operation` 分区 SUM 时需注意 `operation` 已作为分区字段，各行对应不同操作类型，不应将不同 `operation` 分区的同一计数字段直接叠加 | 查询时需先按 `operation` 过滤或在聚合逻辑中明确区分 |

### 时效性说明

- 本表为**小时级准实时表**，数据按小时调度写入，每小时覆盖写对应分区
- 最新可用数据通常滞后当前时间约 1~2 小时，不提供实时（秒/分钟级）数据
- `local_date` + `local_hour` 为本地时区维度，`regional_date` + `regional_hour` 为区域标准时区维度，跨时区分析时需注意二者差异，避免混用
- 不含累计（`_td`）或近 N 天（`_nd`）预聚合窗口，如需多日汇总需在查询层手动聚合

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 图搜业务明细事件源表，提供用户行为事件（曝光、点击、加购、下单等）的原始记录，包含图片 MD5、相似度、位置、GMV 等原始字段 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search
        │
        ▼
[Step 1] dwd_image_search（过滤站点/日期/小时/操作类型）
        │
        ▼
[Step 2] dwd_image_search_click_selfjoin（PDP 点赞事件回填图搜上下文）
        │
        ▼
[Step 3] dwd_image_search_aggregated（用户粒度聚合，计算各行为指标）
        │
        ▼
[Step 4] INSERT OVERWRITE → srdi_mart.dwm_sr_data_warehouse_image_search_user
```

### 关键步骤

**Step 1 — 临时视图 `dwd_image_search`**
从 `srdi_mart.dwd_sr_data_warehouse_search` 中按 `grass_region`、`local_date`、`local_hour`、`operation` 过滤，提取图搜相关事件的基础字段，形成当次任务的工作数据集。

**Step 2 — 临时视图 `dwd_image_search_click_selfjoin`**
对 Step 1 的视图进行自关联，将用户在商品详情页（`page_type='product'`）触发的点赞（`target_type='like_button'`）事件，通过 `pre_source_event_id = event_id` 关联到其来源的图搜结果页商品点击事件，从而将图搜上下文信息（`md5`、`search_mid`、`search_entrance`、`item_similarity`、`image_source`）回填至点赞事件行，弥补 PDP 事件缺失图搜来源信息的问题。非点赞场景的事件直接保留原始值（LEFT JOIN 不匹配行不受影响）。

**Step 3 — 临时视图 `dwd_image_search_aggregated`**
在用户（`user_id`）+ 维度组合（平台、图片、页面、入口、来源、广告标记等）粒度上进行聚合：
- 各行为计数：`imp_cnt`、`click_cnt`、`ppv_cnt`（排除回退）、`view_cnt`（排除回退）、`cart_cnt`、`order_cnt`
- 成交金额：`gmv`（美元）、`gmv_local`（本地货币）
- 位置累加：`click_location_sum`（点击位置之和）、`cart_location_sum`（加购位置之和），仅限图搜结果页商品行为
- 相似度：`top1_similarity_sum`（首位商品相似度之和）、`top1_item_imp_cnt`（首位商品曝光次数），仅限 `location=0` 的曝光事件
- 对图搜按钮自身的曝光/点击事件，`search_entrance` 按 `page_type` 规则重新映射为标准化入口名称

**Step 4 — INSERT OVERWRITE 写目标表**
将 Step 3 聚合结果写入目标表，`grass_region` 和 `local_date` 作为静态分区注入，其余分区字段（`local_hour`、`regional_date`、`regional_hour`、`operation`）作为动态分区，覆盖写入对应分区数据。

### 注意事项

- **`atc_location_sum` 字段名映射**：DataMap 快照中目标表字段名为 `atc_location_sum`，ETL SQL 中对应的计算列名为 `cart_location_sum`，二者为同一字段，查询时以 `atc_location_sum` 为准。
- **动态分区数量**：`operation` 作为动态分区字段，同一 `local_date` + `local_hour` 下可能产生 `impression`、`click`、`ppv`、`view`、`cart`、`order` 等多个子分区，查询时若不指定 `operation` 过滤，需注意避免各操作类型的指标字段被误加总。
- **self-join 性能**：Step 2 对同一临时视图执行自关联，数据量较大时需注意 Shuffle 开销，调度时应确保执行引擎资源充足。
- **`is_back` 字段过滤**：`ppv_cnt` 和 `view_cnt` 均排除 `is_back = true` 的回退行为，确保计数仅反映用户主动进入的浏览行为，使用时需了解此过滤语义。
- **单 ETL 文件，非 multi-writer**：本表仅由一个 ETL 文件写入，不存在多文件并发写入的分区冲突风险。

---

*文档生成时间：2026-05-17*