<!-- ads-workspace-gdoc-sync: gdoc_id=15XxCZvpmlIU04N2boH5mskHUDdEYcOD31i7fSOw9CXc gdoc_url=https://docs.google.com/document/d/15XxCZvpmlIU04N2boH5mskHUDdEYcOD31i7fSOw9CXc/edit -->

# srdi_mart.dim_sr_data_warehouse_item

**分层：** DIM（维度层）
**主键：** `item_id`（在分区 `grass_region` + `local_date` 内唯一）
**分区：** `grass_region`（站点/大区）、`local_date`（本地日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 12,280 次

---

## 业务描述

本表是搜推数仓（SRDI）商品维度宽表，以商品（item）为粒度，每日按站点分区存储商品的核心属性快照。表中整合了商品基础信息、价格体系、类目层级、品牌、评价、销量、店铺基础信息等多维度数据，同时标注了商品类目的高/低 GMV 分类标签（`category_tag`），并预留了店铺维度扩展字段（当前版本均为 NULL）。

**核心业务场景：**
- 搜索/推荐排序模型的离线特征提取（商品属性、价格、类目、评分等）
- 商品分析报表的维度关联（按类目、品牌、站点、日期下钻）
- 高/低 GMV 类目商品结构分析
- 跨境商品（CB）、官方店、SBS 商品的专项分析

**适合回答的问题：**
- 某站点某日有哪些商品，其价格、折扣、销量、评分情况如何？
- 某一级/二级全球类目下的商品分布及价格区间？
- 高 GMV 类目 vs 低 GMV 类目的商品数量及价格对比？
- 某商品是否为跨境商品、预售商品、SBS 商品？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识（如 SG、MY、TH 等），分区键，查询时必须指定 |
| `local_date` | date | 本地日期，数据快照日期，分区键，查询时必须指定 |

### 维度：商品基础信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，表内主键 |
| `item_name` | string | 商品名称 |
| `item_status` | bigint | 商品状态（来源于 `mp_item.dim_item__reg_s0_live` 的 `status` 字段） |
| `item_create_datetime` | string | 商品创建时间（字符串格式，来源于 `create_datetime`） |
| `item_create_timestamp` | bigint | 商品创建时间戳（Unix timestamp，来源于 `create_timestamp`） |
| `mtsku_item_id` | bigint | 多规格 SKU 关联的商品 ID |
| `images` | string | 商品图片信息（来源于 `mp_item.dim_item_ext__reg_s0_live`） |

### 维度：商品类型标志

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_free_shipping` | boolean | 是否免运费（原始值 1/0 转换为 TRUE/FALSE） |
| `is_official_shop` | boolean | 是否官方店铺商品（原始值 1/0 转换为 TRUE/FALSE） |
| `is_cb_shop` | boolean | 是否跨境商品（来源于 `dim_item`，原始值 1/0 转换为 TRUE/FALSE） |
| `is_cod` | tinyint | 是否支持货到付款（Cash on Delivery），1=是，0=否 |
| `is_domestic_stocked` | tinyint | 是否国内备货（境外仓），1=是，0=否 |
| `is_sbs` | tinyint | 是否 SBS（Shopee Branded Seller）商品，1=是，0=否 |
| `is_pre_order` | tinyint | 是否预售商品，1=是，0=否 |

### 维度：全球类目体系

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_be_category_id` | bigint | 商品所属全球后端类目 ID（叶子节点） |
| `global_be_category` | string | 商品所属全球后端类目名称（叶子节点） |
| `level1_global_be_category_id` | bigint | 全球类目 L1 层级 ID |
| `level1_global_be_category` | string | 全球类目 L1 层级名称 |
| `level2_global_be_category_id` | bigint | 全球类目 L2 层级 ID |
| `level2_global_be_category` | string | 全球类目 L2 层级名称 |
| `level3_global_be_category_id` | bigint | 全球类目 L3 层级 ID |
| `level3_global_be_category` | string | 全球类目 L3 层级名称 |
| `level4_global_be_category_id` | bigint | 全球类目 L4 层级 ID |
| `level4_global_be_category` | string | 全球类目 L4 层级名称 |
| `level5_global_be_category_id` | bigint | 全球类目 L5 层级 ID |
| `level5_global_be_category` | string | 全球类目 L5 层级名称 |
| `local_l0_category` | string | 本地类目 L0 层级名称（当前版本恒为 NULL，预留字段） |
| `local_l1_category` | string | 本地类目 L1 层级名称（当前版本恒为 NULL，预留字段） |
| `category_tag` | string | 类目 GMV 等级标签，取值 `'high gmv'` 或 `'low gmv'`，基于 `srdi_mart.dim_sr_data_warehouse_high_gmv_category` 中的高 GMV 类目列表与 `level1_global_be_category` 比对得出 |

### 维度：品牌信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_global_brand` | string | 商品全球品牌名称（来源于 `global_brand_details.name`） |
| `item_global_brand_id` | string | 商品全球品牌 ID（来源于 `global_brand_details.id`） |

### 维度：店铺基础信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID |
| `shop_name` | string | 店铺名称（当前版本恒为 NULL，预留字段） |
| `shop_user_id` | bigint | 店铺关联用户 ID（当前版本恒为 NULL，预留字段） |
| `shop_type` | string | 店铺类型（当前版本恒为 NULL，预留字段） |
| `shop_status` | bigint | 店铺状态（当前版本恒为 NULL，预留字段） |
| `shop_seller_status` | bigint | 卖家状态（当前版本恒为 NULL，预留字段） |
| `shop_tier` | string | 店铺等级（当前版本恒为 NULL，预留字段） |
| `shop_primary_managed_kpi_category` | string | 店铺主要运营 KPI 类目（当前版本恒为 NULL，预留字段） |

### 维度：店铺类型标志

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_is_cb_shop` | tinyint | 店铺是否跨境（当前版本恒为 NULL，预留字段） |
| `shop_is_b2c` | int | 店铺是否 B2C（当前版本恒为 NULL，预留字段） |
| `shop_is_bi_excluded` | int | 店铺是否被 BI 排除（当前版本恒为 NULL，预留字段） |
| `shop_is_ccb_shop` | int | 店铺是否 CCB 跨境（当前版本恒为 NULL，预留字段） |
| `shop_is_fbs` | int | 店铺是否 FBS（Fulfilled by Shopee）（当前版本恒为 NULL，预留字段） |
| `shop_is_fss_shop` | int | 店铺是否 FSS（当前版本恒为 NULL，预留字段） |
| `shop_is_supermarket_shop` | int | 店铺是否超市类型（当前版本恒为 NULL，预留字段） |
| `shop_is_holiday_mode` | tinyint | 店铺是否处于假期模式（当前版本恒为 NULL，预留字段） |
| `shop_is_competitor` | boolean | 店铺是否为竞品（当前版本恒为 NULL，预留字段） |
| `shop_cb_shop_origin_country` | string | 跨境店铺来源国家（当前版本恒为 NULL，预留字段） |

### 维度：店铺时间信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_first_listing_datetime` | string | 店铺首次上架时间（当前版本恒为 NULL，预留字段） |
| `shop_last_listing_datetime` | string | 店铺最近上架时间（当前版本恒为 NULL，预留字段） |
| `shop_last_login_datetime_td` | string | 店铺最近登录时间（截至当日，当前版本恒为 NULL，预留字段） |

### 指标：商品价格

| 字段 | 类型 | 说明 |
|---|---|---|
| `price` | double | 商品当前价格（USD，来源于 `price_usd`） |
| `price_local` | double | 商品当前价格（本地货币，来源于 `price`） |
| `price_before_discount` | double | 折扣前价格（USD，来源于 `price_before_discount_usd`） |
| `price_before_discount_local` | double | 折扣前价格（本地货币，来源于 `price_before_discount`） |
| `item_price_max` | double | 商品最高规格价格（USD，来源于 `price_max_usd`） |
| `item_price_max_local` | double | 商品最高规格价格（本地货币，来源于 `price_max`） |
| `discount_pct` | double | 折扣百分比（0~100 或 0~1，具体精度取决于上游定义） |

### 指标：商品评价与销量

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_rating_score` | double | 商品评分（通常为 0~5 分，均值型指标，不可直接 SUM） |
| `item_rating_total_cnt` | bigint | 商品评分总次数 |
| `comment_cnt` | bigint | 商品评论数量 |
| `item_sold_cnt` | double | 商品历史销量（累计值，类型为 double，来源于 `sold_cnt`） |
| `estimated_days_to_ship` | bigint | 预计发货天数 |

### 指标：店铺运营指标（截至当日）

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_follower_cnt_td` | bigint | 店铺关注者数量（截至当日，当前版本恒为 NULL，预留字段） |
| `shop_like_cnt_td` | bigint | 店铺点赞数量（截至当日，当前版本恒为 NULL，预留字段） |
| `shop_sold_total` | bigint | 店铺历史总销量（当前版本恒为 NULL，预留字段） |
| `shop_active_item_with_stock_cnt` | bigint | 店铺有库存的在售商品数（当前版本恒为 NULL，预留字段） |
| `shop_response_rate` | double | 店铺回复率（均值型指标，不可直接 SUM；当前版本恒为 NULL，预留字段） |
| `shop_seller_rating` | string | 店铺卖家综合评级（当前版本恒为 NULL，预留字段） |
| `shop_rating_bad` | bigint | 店铺差评数（当前版本恒为 NULL，预留字段） |
| `shop_rating_normal` | bigint | 店铺中评数（当前版本恒为 NULL，预留字段） |
| `shop_rating_good` | bigint | 店铺好评数（当前版本恒为 NULL，预留字段） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，每次查询必须显式指定，否则触发全表扫描，影响性能。示例：`WHERE grass_region = 'SG'`
- **`local_date`**：分区字段，必须显式指定日期。如需最新快照，取最大分区日期。示例：`WHERE local_date = '2026-05-16'`
- 两个分区字段需**同时指定**，避免跨站点、跨日期的意外聚合。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_rating_score` | 均值型指标，需加权平均（× `item_rating_total_cnt`）后再聚合 |
| `discount_pct` | 比率型字段，不可直接 SUM，需 AVG 或加权计算 |
| `shop_response_rate` | 比率型字段，当前为 NULL，后续填充后仍不可直接 SUM |
| `item_sold_cnt` | 类型为 double，为累计历史销量快照值，跨日期 SUM 会重复计算 |
| `shop_follower_cnt_td`、`shop_like_cnt_td` | 截至当日的累计值（`_td` 后缀），跨日期 SUM 无意义 |

### 时效性说明

- 本表为**日快照表**，每日全量覆盖写入，数据反映各分区 `local_date` 当天的状态。
- `_td` 后缀字段（`shop_follower_cnt_td`、`shop_like_cnt_td`、`shop_last_login_datetime_td`）为截至当日（to-date）的累计值，仅在单一 `local_date` 分区内有意义。
- 当前版本中所有 `shop_*` 字段（除 `shop_id`）均为 NULL，**不可用于店铺维度分析**，如需店铺信息请关联店铺维度表。
- `local_l0_category`、`local_l1_category` 当前版本恒为 NULL，本地类目分析请使用全球类目字段。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_item.dim_item__reg_s0_live` | 商品核心维度源表，提供商品基础属性、价格、类目、评分、销量、标志位等字段；按 `grass_date` + `grass_region` + `tz_type='local'` 过滤 |
| `mp_item.dim_item_ext__reg_s0_live` | 商品扩展属性表，提供商品图片（`images`）及跨境标志（`is_cb_shop`）；按相同分区过滤 |
| `srdi_mart.dim_sr_data_warehouse_high_gmv_category` | 高 GMV 类目配置表，用于判断一级类目是否为高 GMV，生成 `category_tag` 标签；取最新 `update_date` 的一条记录 |

---

## ETL 逻辑摘要

### 数据流

```
mp_item.dim_item__reg_s0_live
        │ (按 grass_date, grass_region, tz_type='local' 过滤)
        ▼
  dim_item_{region}  (Temp View - 商品主维度)
        │
        ├──────────────────────────────────────────────────┐
        │                                                  │
mp_item.dim_item_ext__reg_s0_live              srdi_mart.dim_sr_data_warehouse_high_gmv_category
        │ (图片、跨境标志)                               │ (最新高GMV类目列表)
        ▼                                                  ▼
  dim_item_ext_{region} (Temp View)       dim_high_gmv_cate_{region} (Temp View)
        │                                                  │
        └──────────────────────┬───────────────────────────┘
                               ▼
                  dim_item_merged_{region} (Temp View - LEFT JOIN 合并)
                               │
                               ▼
              srdi_mart.dim_sr_data_warehouse_item
              PARTITION(grass_region, local_date)
              INSERT OVERWRITE
```

### 关键步骤

**Step 1 — `dim_item_{region}`（Temp View）**
从 `mp_item.dim_item__reg_s0_live` 读取指定站点、指定日期、本地时区的商品数据，完成字段重命名（如价格 USD/本地化双路、`rating_score`→`item_rating_score` 等）和类型转换（`is_free_shipping`、`is_official_shop`、`is_cb_shop` 由 int 转 boolean）。

**Step 2 — `dim_item_ext_{region}`（Temp View）**
从 `mp_item.dim_item_ext__reg_s0_live` 读取同分区数据，仅取 `item_id`、`images`、`is_cb_shop` 三个字段，用于补充商品图片信息。

**Step 3 — `dim_high_gmv_cate_{region}`（Temp View）**
从 `srdi_mart.dim_sr_data_warehouse_high_gmv_category` 读取指定站点的高 GMV 类目配置，通过窗口函数 `ROW_NUMBER() OVER (ORDER BY update_date DESC)` 取最新一条，并解析类目数组（`split` + `transform` + `trim`）为标准数组格式。

**Step 4 — `dim_item_merged_{region}`（Temp View）**
- `dim_item` LEFT JOIN `dim_item_ext`（关联条件：`item_id` + `is_cb_shop`）补充 `images` 字段
- LEFT JOIN `dim_high_gmv_cate`（广播 JOIN，使用 `BROADCASTJOIN` hint）
- 通过 `array_contains(high_gmv_category, level1_global_be_category)` 生成 `category_tag`（`'high gmv'` / `'low gmv'`）
- `local_l0_cat`、`local_l1_cat` 显式写入 NULL

**Step 5 — INSERT OVERWRITE（写目标表）**
从 `dim_item_merged_{region}` 读取所有字段，所有 `shop_*` 维度字段（除 `shop_id`）显式写入 NULL，按 `level1~5_global_be_category_id`、`shop_id`、`item_id` 排序后写入目标分区。

### 注意事项

- **单一写入方：** 本表仅由 1 个 ETL 文件写入，无 multi-writer 风险。
- **INSERT OVERWRITE：** 每次执行覆盖指定 `(grass_region, local_date)` 分区，历史分区不受影响。
- **店铺字段全部为 NULL：** ETL 中所有 `shop_*` 字段（除 `shop_id`）均硬编码为 NULL，当前表不提供店铺维度数据，这是**已知的设计预留状态**，使用时需注意。
- **`local_l0_category` / `local_l1_category` 为 NULL：** 本地类目字段当前未被填充，分析时不可使用。
- **`is_cb_shop` JOIN 条件：** Step 4 中 `dim_item_ext` 的关联条件包含 `is_cb_shop`，若两表该字段值不一致可能导致 `images` 丢失，需注意数据一致性。
- **高 GMV 类目配置时效：** `category_tag` 依赖 `dim_sr_data_warehouse_high_gmv_category` 的最新一条配置，若该表长时间未更新，`category_tag` 可能基于过期的类目列表计算。
- **参数化执行：** SQL 通过 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等模板参数驱动，单次执行覆盖一个分区，多站点需多次调度。

---

*文档生成时间：2026-05-17*