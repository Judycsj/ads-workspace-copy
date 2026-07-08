<!-- ads-workspace-gdoc-sync: gdoc_id=1OVHNOaUktyJ9vVZV6jQ7QcJ0F-qWVW8vWutp0lqE_YA gdoc_url=https://docs.google.com/document/d/1OVHNOaUktyJ9vVZV6jQ7QcJ0F-qWVW8vWutp0lqE_YA/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_item_level_benchmark_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `platform` + `item_id` + `is_ads` + `feature_detail` + `scenario_tag`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日（T+1 全量覆盖写入）
**访问频次：** 5,217 次

---

## 业务描述

本表是搜推数仓**商品维度基准指标宽表**，以「大区 + 日期 + 平台 + 商品 + 广告标识 + 流量特征 + 场景标签」为粒度，汇总每个商品在各平台、各流量来源、各业务场景下的全链路漏斗指标（曝光 → 点击 → 浏览 → 加购 → 成交）及 GMV 表现，同时关联商品维度（类目、店铺）与广告标签（是否广告商品、是否 ROI² 商品）。

**核心业务场景：**

- 商品级别的日常流量与成交表现监控
- 搜推各场景（Search、Cart、YMAL 等）下商品曝光-转化漏斗分析
- 广告与自然流量商品的效果对比
- 类目/店铺维度的商品基准指标下钻
- ATC（加购后）同日及 3 日内归因的订单/GMV 分析

**适合回答的问题示例：**

- 某商品在某平台某日的曝光量、点击量、成交 GMV 是多少？
- Search 场景下，某类目广告商品与自然商品的转化率差异如何？
- 某店铺下所有商品在过去一天的 ATC 同日成交和 3 日成交分别是多少？
- ROI² 商品在各场景的 PC2 GMV 占比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SHOPEE_ID、SHOPEE_MY 等），分区键之一，每次查询必须指定 |
| `local_date` | date | 业务日期（当地时区），分区键之一，对应数据统计日期 |

### 维度：商品与流量标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 平台标识（如 Android、iOS、PC 等） |
| `item_id` | bigint | 商品 ID；`item_id <= 0` 的行为无法匹配商品维度的汇总行，shop/类目字段均为 null |
| `is_ads` | boolean | 该行是否为广告流量维度标识（来自上游 DWM 层） |
| `is_ads_item` | int | 商品是否为广告商品标识（来自广告标签表，1 表示是）；`item_id <= 0` 时为 null |
| `is_roi2_item` | int | 商品是否为 ROI² 广告商品标识（来自广告标签表）；`item_id <= 0` 时为 null |
| `feature_detail` | string | 流量特征明细标识，标识商品所在的具体入口特征；`__ALL__` 表示全量汇总 |
| `scenario_tag` | string | 业务场景标签，由 `scenario_tags` 数组展开得到；`__ALL__` 表示跨场景全量汇总，其他值如 `DA_Search`、`DA_Cart_Unify` 等 |

### 维度：店铺信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_id` | bigint | 店铺 ID，来自商品维度表关联；`item_id <= 0` 时为 null |
| `shop_type` | string | 店铺类型（如官方店、本地店等），来自店铺维度表关联；`item_id <= 0` 时为 null |

### 维度：全球后端类目（多级）

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | bigint | 一级全球后端类目 ID；`item_id <= 0` 时为 null |
| `level1_global_be_category` | string | 一级全球后端类目名称；`item_id <= 0` 时为 null |
| `level2_global_be_category_id` | bigint | 二级全球后端类目 ID；`item_id <= 0` 时为 null |
| `level2_global_be_category` | string | 二级全球后端类目名称；`item_id <= 0` 时为 null |
| `level3_global_be_category_id` | bigint | 三级全球后端类目 ID；`item_id <= 0` 时为 null |
| `level3_global_be_category` | string | 三级全球后端类目名称；`item_id <= 0` 时为 null |
| `level4_global_be_category_id` | bigint | 四级全球后端类目 ID；`item_id <= 0` 时为 null |
| `level4_global_be_category` | string | 四级全球后端类目名称；`item_id <= 0` 时为 null |
| `level5_global_be_category_id` | bigint | 五级全球后端类目 ID；`item_id <= 0` 时为 null |
| `level5_global_be_category` | string | 五级全球后端类目名称；`item_id <= 0` 时为 null |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 商品曝光次数（impression） |
| `omni_imp_cnt` | bigint | 全渠道曝光次数（omni_impression），含跨渠道曝光 |
| `click_cnt` | bigint | 商品点击次数 |
| `omni_click_cnt` | bigint | 全渠道点击次数（omni_click） |

### 指标：浏览与页面访问

| 字段 | 类型 | 说明 |
|---|---|---|
| `view_cnt` | bigint | 商品详情页浏览次数（view） |
| `ppv_cnt` | bigint | 商品详情页 PPV（Product Page View）次数 |
| `ppv_cnt_exclude_isback` | bigint | 排除返回行为后的 PPV 次数；计算逻辑：`SUM(IF(is_back, 0, ppv_cnt))` |

### 指标：加购与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加入购物车次数 |
| `order_cnt` | double | 成交订单数（直接归因） |
| `gmv` | double | 成交 GMV（直接归因，本地货币） |
| `pc2_gmv` | double | PC2 口径的 GMV |

### 指标：ATC 归因成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | ATC（加购）归因的同日成交订单数 |
| `atc_same_day_gmv` | double | ATC 归因的同日成交 GMV |
| `atc_within_3day_order_cnt` | double | ATC 归因的 3 日内成交订单数 |
| `atc_within_3day_gmv` | double | ATC 归因的 3 日内成交 GMV |

---

## 查询使用须知

### 必须指定的过滤条件

- **必须同时过滤 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全表扫描，影响性能并产生高额计算成本：
  ```sql
  WHERE grass_region = 'SHOPEE_ID'
    AND local_date = '2024-01-01'
  ```

### 数据行结构说明

- 本表存在多种粒度的汇总行，需注意 `feature_detail` 和 `scenario_tag` 的取值：
  - `feature_detail = '__ALL__'` 且 `scenario_tag = '__ALL__'`：商品在该平台下全流量、全场景的汇总；
  - `feature_detail = '__ALL__'` 且 `scenario_tag != '__ALL__'`：某场景下跨所有入口的汇总；
  - `feature_detail != '__ALL__'` 且 `scenario_tag != '__ALL__'`：某具体入口 × 某场景的明细行。
- **直接对不同 `feature_detail` / `scenario_tag` 组合 SUM 会造成重复计数**。如需商品级别总和，请过滤 `feature_detail = '__ALL__' AND scenario_tag = '__ALL__'`。

### 不可直接 SUM 的注意事项

- `order_cnt`、`gmv` 等指标因多粒度展开（`scenario_tags` 数组 explode），跨不同 `scenario_tag` 行之间存在重叠，**切勿在未过滤 `scenario_tag` 的情况下直接 SUM**。
- `atc_same_day_order_cnt`、`atc_within_3day_order_cnt`、`atc_same_day_gmv`、`atc_within_3day_gmv`、`pc2_gmv` 同理，为归因派生指标，跨行求和需确认去重逻辑。
- `ppv_cnt_exclude_isback` 是预聚合派生指标（已在 ETL 中计算 `SUM(IF(is_back, 0, ppv_cnt))`），不可与 `ppv_cnt` 混用求和。
- `is_ads_item` / `is_roi2_item` 为标签字段，不可 SUM，应使用 `MAX` 或 `CASE WHEN` 筛选。

### source1 / source2 来源流量的处理

- 上游 DWM 层存在 `source1_feature_detail` / `source2_feature_detail` 及对应的 `scenario_tags`，ETL 中对这些来源做了去重展开（仅在 `source1_feature_detail != feature_detail` 且非空时补充），对应行的 `imp_cnt`、`click_cnt`、`view_cnt` 被置为 0，仅保留加购/成交类指标。**使用曝光/点击指标时请注意此部分行不包含曝光点击数据**。

### 时效性说明

- 表命名为 `_1d`，为**每日快照表**，数据口径为自然日（当地时区），通常 T+1 日完成写入。
- 无近 N 天滚动窗口，如需多日趋势需按 `local_date` 自行聚合多个分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 主事实源表，提供商品级用户行为事件（曝光、点击、浏览、加购、成交等）及各类指标原始值 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，关联商品所属店铺 ID 及多级全球后端类目信息 |
| `srdi_mart.dim_sr_data_warehouse_shop` | 店铺维度表，关联店铺类型信息 |
| `srdi_mart.dwm_sr_data_warehouse_ads_item_tag` | 广告商品标签表，关联 `is_ads_item`、`is_roi2_item` 等广告归因标签 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │  按 grass_region + local_date 过滤，汇总各行为指标
        ▼
    base_table（CACHE）
        │  LATERAL VIEW EXPLODE(scenario_tags) 展开场景标签
        │  UNION ALL source1/source2 补充来源流量（仅保留加购/成交）
        ▼
  feature_tag_data（feature_detail × scenario_tag 明细）
        │
        ├── UNION ALL（feature_detail='__ALL__' + scenario_tag='__ALL__' 全汇总）
        ├── UNION ALL（feature_detail='__ALL__' + 各 scenario_tag 场景汇总）
        └── UNION ALL feature_tag_data（feature_detail × scenario_tag 明细）
        ▼
  union_data（多粒度汇总，含 __ALL__ 哨兵值）
        │  增加 feature_group 映射字段
        ▼
  final_data
        │
        ├── LEFT JOIN item_data（商品 → shop_id + 类目）
        ├── LEFT JOIN shop_data（shop_id → shop_type）
        └── LEFT JOIN ads_perf（item_id + feature_group → is_ads_item, is_roi2_item）
        │
        ├── UNION ALL（item_id > 0 的正常商品行，带维度关联结果）
        └── UNION ALL（item_id <= 0 的汇总行，维度字段全部为 null）
        ▼
INSERT OVERWRITE dws_sr_data_warehouse_platform_item_level_benchmark_1d
PARTITION(grass_region, local_date)
```

### 关键步骤

| 步骤 | 类型 | 说明 |
|---|---|---|
| Step 1 | CACHE TABLE `base_table` | 从 DWM 层按 `grass_region`、`local_date` 和 `operation` 类型过滤，GROUP BY `platform + is_ads + item_id + feature_detail + source1/2_feature_detail + scenario_tags`，对所有指标求和，缓存至内存+磁盘以供后续多次使用 |
| Step 2 | TEMP VIEW `feature_tag_data` | 对 `base_table` 进行三路 UNION：① `scenario_tags` explode（主 feature_detail）；② `source1_scenario_tags` explode（source1_feature_detail，非空且不同于主 feature_detail 时补充，imp/click/view 置 0）；③ `source2_feature_detail` 同理，进一步去重 |
| Step 3 | TEMP VIEW `union_data` | 三路 UNION 构建多粒度汇总：① 全汇总行（`feature_detail='__ALL__'`，`scenario_tag='__ALL__'`）；② 跨 feature 的 scenario 汇总（`feature_detail='__ALL__'`，合并三路 scenario_tags 去重展开）；③ 从 `feature_tag_data` 取 `feature_detail × scenario_tag` 明细汇总 |
| Step 4 | TEMP VIEW `shop_data` | 从店铺维度表取当日当大区的 `shop_id`、`shop_type`，过滤 `shop_id > 0` |
| Step 5 | TEMP VIEW `item_data` | 从商品维度表取当日当大区的商品 → 店铺 → 多级类目映射，过滤 `shop_id > 0 AND item_id > 0` |
| Step 6 | TEMP VIEW `final_data` | 在 `union_data` 基础上，按 `scenario_tag` 值 CASE WHEN 映射出 `feature_group` 字段（用于后续与广告标签关联） |
| Step 7 | TEMP VIEW `ads_perf` | 从广告标签 DWM 表取当日当大区有曝光的商品，获取 `is_roi2_item`、`is_ads_item`，以 `item_id + feature_group` 为粒度 |
| Step 8 | INSERT OVERWRITE | 最终写入目标表：`item_id > 0` 的行 LEFT JOIN 三个维度表及广告标签表（REPARTITION 500）；`item_id <= 0` 的行直接写入，维度字段全置 null（REPARTITION 200），两路 UNION ALL 后覆盖写入目标分区 |

### 注意事项

- **单 Writer 写入**：本表为单 ETL 文件写入，无 multi-writer 并发风险，但每次执行为 `INSERT OVERWRITE` 全量覆盖指定 `grass_region + local_date` 分区。
- **`feature_detail` 与 `scenario_tag` 的 `__ALL__` 哨兵值**：表中同时存在明细行与多级汇总行，下游使用时需明确过滤条件，避免重复计数。
- **source1/source2 补充行的指标不完整**：来源流量补充行（source1/source2 feature_detail 不同于主 feature_detail 的行）中，`imp_cnt`、`click_cnt`、`view_cnt` 被硬编码为 0，仅保留加购/成交类指标，使用时需注意。
- **广告标签关联依赖 `feature_group`**：`ads_perf` 通过 `item_id + feature_group` 关联，`feature_group` 由 `scenario_tag` 映射而来，若 `scenario_tag` 无法匹配任何规则则 `feature_group` 为空字符串，将导致广告标签关联失败，`is_ads_item` / `is_roi2_item` 为 null。
- **`item_id <= 0` 行的维度处理**：`item_id` 无效的汇总行直接从 `union_data` 取出，不做维度关联，所有维度字段（shop_id、shop_type、类目、is_ads_item、is_roi2_item）均为 null。

---

*文档生成时间：2026-05-17*