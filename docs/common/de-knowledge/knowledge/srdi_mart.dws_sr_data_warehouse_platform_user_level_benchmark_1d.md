<!-- ads-workspace-gdoc-sync: gdoc_id=1J8iZkLs8WUoAQOgtTBdl9Pku1sAZfzYUqWmuX7B--LI gdoc_url=https://docs.google.com/document/d/1J8iZkLs8WUoAQOgtTBdl9Pku1sAZfzYUqWmuX7B--LI/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d

**分层：** DWS（数据汇总层）
**主键：** `user_id` + `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `grass_region` + `local_date`
**分区：** `grass_region`（站点大区），`local_date`（业务日期）
**更新频率：** 每日全量覆盖写入（`INSERT OVERWRITE PARTITION`）
**访问频次：** 8491 次

---

## 业务描述

本表是搜推数据仓库平台（SR Data Warehouse Platform）的**用户粒度每日基准宽表**，以「用户 × 平台 × 广告标识 × 功能入口 × 场景标签」为分析维度，汇聚当日全链路漏斗指标（曝光→点击→浏览→加购→下单→GMV）以及广告投放效果指标（ADVV、ROI、ADS GMV 等），同时附带异常 GMV 截尾（995 分位）处理后的指标。

**核心业务场景：**
- 搜推各场景（搜索、推荐频道、购物车、订单详情页等）的用户级日常效果监控
- 广告与自然流量（`is_ads`）的分离分析及对比
- ATC（加购）归因 GMV 统计（当日 / 3 日窗口）
- 基于 995 分位截尾的高价值 / 低价值 GMV 稳定性评估
- 跨场景漏斗分析（Omni 曝光/点击补充）

**适合回答的问题：**
- 某站点某日某用户在搜索场景的自然流量曝光、点击、下单表现如何？
- 广告（`is_ads=true`）在各场景的 GMV、ROAS（`ads_gmv_usd / broad_advv_cost`）表现？
- 某功能入口（`feature_detail`）下的用户加购-成交转化漏斗数据？
- 去除高价值 GMV 异常值（995 截尾）后，各场景用户 GMV 贡献如何分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 SG、MY、TH 等），分区键，查询必须指定 |
| `local_date` | date | 业务日期（本地时区），分区键，查询必须指定 |

### 维度：用户与平台标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；`user_id <= 0` 的记录已在上游过滤，广告数据中未登录用户以 -1 替代 |
| `device_id` | string | 设备 ID；当前版本 ETL 写入值恒为 `NULL`，预留字段 |
| `platform` | string | 平台标识（如 Android、iOS、Web 等） |
| `is_ads` | boolean | 是否为广告流量；`true` 表示广告，`false` 表示自然流量 |
| `feature_detail` | string | 功能入口细节标识（如 `home-rec-item`）；`'__ALL__'` 表示汇总行（不拆分功能入口维度） |
| `scenario_tag` | string | 场景标签（如 `__ALL__`、`DA_Search`、`dpm module Global Search business line Search`、`DA_Cart_Unify` 等）；`'__ALL__'` 表示跨场景汇总行 |

### 指标：流量漏斗指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数；仅主 feature_detail 来源有效，source1/source2 来源补 0 |
| `click_cnt` | bigint | 点击次数；仅主 feature_detail 来源有效，source1/source2 来源补 0 |
| `item_imp_cnt` | bigint | 商品级曝光次数；`feature_detail` 层级中为 `item` 的曝光量 |
| `item_click_cnt` | bigint | 商品级点击次数；`feature_detail` 层级中为 `item` 的点击量 |
| `ppv_cnt` | bigint | 商品详情页（PDV）浏览次数 |
| `ppv_cnt_exclude_isback` | bigint | 排除返回行为（is_back=true）后的 PDV 浏览次数 |
| `cart_cnt` | bigint | 加购次数 |
| `omni_imp_cnt` | bigint | Omni 曝光次数（跨渠道补充曝光） |
| `omni_click_cnt` | bigint | Omni 点击次数（跨渠道补充点击） |

### 指标：自然流量转化指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单笔数（自然流量口径） |
| `gmv` | double | 成交金额（自然流量口径，本地货币） |
| `pc2_gmv` | double | PC2 口径 GMV（自然流量） |
| `atc_same_day_order_cnt` | double | ATC 归因当日下单笔数（用户加购当天产生的订单） |
| `atc_same_day_gmv` | double | ATC 归因当日 GMV |
| `atc_within_3day_order_cnt` | double | ATC 归因 3 日内下单笔数 |
| `atc_within_3day_gmv` | double | ATC 归因 3 日内 GMV |

### 指标：广告效果指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue_usd` | double | 广告收入（USD），来源于广告 ADVV 请求数据 |
| `ads_gmv_usd` | double | 广告归因 GMV（USD） |
| `broad_gmv_usd` | double | 泛归因 GMV（USD），广告宽口径归因 |
| `ads_order_cnt` | double | 广告归因下单笔数 |
| `ads_broad_order_cnt` | double | 泛归因下单笔数 |
| `ads_imp_cnt` | bigint | 广告曝光次数（来源于 ADVV 请求数据） |
| `ads_click_cnt` | bigint | 广告点击次数（来源于 ADVV 请求数据） |
| `broad_advv_cost` | double | 广告主花费（ADVV 泛口径，USD） |
| `roi2_broad_advv_cost` | double | ROI 2.0 产品类型对应的广告主花费（USD） |

> **注意**：当 `feature_detail != '__ALL__'`（即 `feature_detail` 维度行）时，广告效果指标（`revenue_usd`、`ads_gmv_usd` 等）恒为 0，广告 ADVV 数据仅在 `feature_detail = '__ALL__'` 的汇总行中有效。

### 指标：GMV 异常截尾指标（995 分位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高价值商品（`category_tag='high gmv'`）截尾后 GMV（订单 GMV 与 995 分位取 min 后聚合） |
| `low_gmv_995_v2` | double | 低价值商品（`category_tag='low gmv'`）截尾后 GMV |
| `high_pc2_gmv_995_v2` | double | 高价值商品截尾后 PC2 GMV |
| `low_pc2_gmv_995_v2` | double | 低价值商品截尾后 PC2 GMV |

> **注意**：截尾指标仅在 `feature_detail = '__ALL__'` 的汇总行中有非零值；`feature_detail` 维度行恒为 0。截尾阈值来自 `dim_sr_data_warehouse_category_gmv_outlier`，按 `scenario_tag`、`is_ads`、`category_tag` 匹配。

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 均为物理分区字段，查询时**必须同时指定**，否则将触发全表扫描，严重影响性能和成本。
  ```sql
  WHERE grass_region = 'SG' AND local_date = '2025-01-01'
  ```

### 数据行结构说明

本表同一分区内存在两类语义行，使用前需明确区分：

| 行类型 | `feature_detail` 值 | 广告 ADVV 指标 | GMV 截尾指标 |
|---|---|---|---|
| 场景汇总行（不拆功能入口） | `'__ALL__'` | 有效 | 有效 |
| 功能入口明细行 | 具体路径字符串 | 恒为 0 | 恒为 0 |

- 若只需分析场景级汇总数据（含广告和截尾 GMV），请增加过滤 `feature_detail = '__ALL__'`。
- 若需下钻功能入口，请使用 `feature_detail != '__ALL__'`，并注意广告相关指标不可用。

### `scenario_tag` 特殊值

- `'__ALL__'`：所有场景的跨场景汇总，与各具体 `scenario_tag` 行存在**重复计算**关系，不可直接 SUM 混合使用。
- 单个用户在同一天同一 `feature_detail` 下可能存在多行不同 `scenario_tag`，对场景维度聚合时需先确认 `scenario_tag` 的枚举范围，避免重叠。

### 不可直接 SUM 的场景

- **比率类指标**（需基于分子/分母单独聚合再计算）：CTR（`click_cnt / imp_cnt`）、CVR（`order_cnt / click_cnt`）、ROAS（`ads_gmv_usd / broad_advv_cost`）等，均需自行构建，不可对派生比率求和。
- **995 截尾指标**（`high_gmv_995_v2`、`low_gmv_995_v2` 等）：属于在订单粒度截尾后的聚合结果，不可与原始 `gmv` 字段混用或二次 SUM 叠加，也不可跨 `scenario_tag` 重叠行求和。
- **广告 ADVV 指标**（`revenue_usd`、`ads_gmv_usd`、`ads_order_cnt` 等）：仅 `feature_detail = '__ALL__'` 行有值，跨 `scenario_tag` 聚合时需防止 `__ALL__` 与具体场景行的重叠。

### 时效性说明

- 本表为 **T+1 日级快照表**（`_1d` 后缀），每日覆盖写入当日分区，不保留历史分区数据的增量累计。
- 如需多日趋势，需按 `local_date` 范围扫描多个分区，成本较高，建议结合 `local_date` 范围收窄。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 主流量漏斗数据源；提供曝光、点击、PPV、加购、订单、GMV 等用户×商品×功能入口粒度原始指标 |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 广告 ADVV 请求数据源；提供广告收入、广告 GMV、花费、广告曝光/点击等广告效果指标（按 user_id × platform 聚合） |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 订单数据源；用于计算 GMV 995 截尾指标，提供订单级 GMV 和 PC2 GMV |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | GMV 995 分位阈值维表；按 `scenario_tag`、`is_ads`、`category_tag`（高/低价值）存储截尾基准值 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表；提供商品的 `category_tag`（high gmv / low gmv）标签，用于 GMV 截尾分类 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │ (操作类型过滤：impression/click/ppv/cart/order/omni_*)
        ▼
  [CACHE: base_table]  ← 用户×平台×is_ads×feature_detail×scenario_tags 聚合
        │
        ├──► [scenario_tag_feature_detail_level_data]  ← EXPLODE scenario_tags，保留 feature_detail 维度
        │
        └──► [scenario_tag_level_dwm_platform]  ← EXPLODE union_scenario_tags + __ALL__ 汇总行
                                                    （丢弃 feature_detail，仅保留场景维度）

dws_sr_data_warehouse_ads_request_benchmark_advv_1d
        │ (product_types='__ALL__' 过滤，feature_group 映射为 scenario_tag)
        ▼
  [dws_request_advv_base] → [scenario_tag_level_advv]

dws_sr_data_warehouse_platform_order_benchmark_1d + dim_sr_data_warehouse_category_gmv_outlier + dim_sr_data_warehouse_item
        │
        ▼
  [dws_order_benchmark] → [dws_gmv_995] → [dws_gmv_995_agg]
        │ (订单级截尾后按用户×平台×is_ads×scenario_tag 聚合)

  [scenario_tag_level_dwm_platform] FULL OUTER JOIN [scenario_tag_level_advv]
                                    LEFT JOIN [dws_gmv_995_agg]
        ▼
  [scenario_tag_level_data]  ← 合并全量维度指标

        ▼ INSERT OVERWRITE（feature_detail='__ALL__' 行，含广告和截尾指标）
  UNION ALL
        ▼ INSERT OVERWRITE（feature_detail 明细行，广告和截尾指标补 0）

  目标表: dws_sr_data_warehouse_platform_user_level_benchmark_1d
```

### 关键步骤

| 步骤 | 类型 | 描述 |
|---|---|---|
| Step 1 | CACHE TABLE `base_table` | 从 `dwm_sr_data_warehouse_platform_user_item` 按 `operation` 类型过滤，按用户×平台×is_ads×feature_detail×scenario_tags 聚合，计算流量漏斗指标；使用 `MEMORY_AND_DISK_SER` 缓存供后续复用 |
| Step 2 | TEMP VIEW `dws_request_advv_base` | 从广告 ADVV 表读取，过滤 `product_types='__ALL__'`，聚合广告效果指标；拆分 `feature_groups` 数组，包含 `roi2_broad_advv_cost`（ROI 2.0 花费） |
| Step 3 | TEMP VIEW `dws_order_benchmark` | 从订单基准表读取直接归因订单（`is_direct=true`，`__ALL__` 场景）及按 `dedup_scenario_tags` EXPLODE 的场景订单（限 `DA_%` 或 Global Search 场景） |
| Step 4 | TEMP VIEW `gmv995_v2_outlier` | 从 GMV 异常值维表读取 995 分位阈值，限定 `is_ads != '__ALL__'` 且 `feature_group` 范围 |
| Step 5 | TEMP VIEW `dim_item` | 从商品维表读取商品的 `category_tag`，过滤掉默认值 `'low gmv'` 的兜底项（以 join 缺失记录方式补 `'low gmv'`） |
| Step 6 | TEMP VIEW `dws_gmv_995` | 订单数据 LEFT JOIN 商品维表获取 category_tag，INNER JOIN 截尾阈值表，按订单级计算截尾后 GMV（`min(gmv, gmv_995pct)`） |
| Step 7 | TEMP VIEW `dws_gmv_995_agg` | 对 Step 6 结果按用户×平台×is_ads×scenario_tag 聚合，分别计算高/低价值 GMV 和 PC2 GMV 截尾汇总 |
| Step 8 | TEMP VIEW `scenario_tag_feature_detail_level_data` | 对 `base_table` 按三路 UNION：主 feature_detail EXPLODE scenario_tags、source1_feature_detail EXPLODE source1_scenario_tags、source2_feature_detail EXPLODE source2_scenario_tags，生成带 feature_detail 的场景明细行；source1/source2 的 `imp_cnt`/`click_cnt`/`item_*_cnt` 补 0 |
| Step 9 | TEMP VIEW `scenario_tag_level_dwm_platform` | 对 `base_table` 生成两类汇总行：①按 `union_scenario_tags` EXPLODE 的场景行；② `scenario_tag='__ALL__'` 的全局汇总行 |
| Step 10 | TEMP VIEW `scenario_tag_level_advv` | 对 Step 2 按 feature_group EXPLODE 并映射为 `scenario_tag`，聚合广告指标；feature_groups 仅有一个元素时补充 `'others'` |
| Step 11 | TEMP VIEW `scenario_tag_level_data` | Step 9 FULL OUTER JOIN Step 10（on user_id、platform、is_ads、scenario_tag），再 LEFT JOIN Step 7（GMV 截尾），合并全量指标；`NULL` 值统一 COALESCE 为 0 |
| Step 12 | INSERT OVERWRITE | 最终写入目标表分区（`grass_region`、`local_date`）：①从 `scenario_tag_level_data` 写 `feature_detail='__ALL__'` 汇总行（含广告和截尾指标）；② UNION ALL 从 `scenario_tag_feature_detail_level_data` 按 feature_detail 聚合后写明细行（广告和截尾指标补 0） |

### 注意事项

- **单 writer，无 multi-writer 风险**：本表仅由单个 ETL 文件写入，无并发分区写入冲突。
- **`__ALL__` 场景行与具体场景行共存**：`scenario_tag='__ALL__'` 是跨场景聚合汇总行，与各具体 `scenario_tag` 行的指标存在重叠，下游使用时**禁止将 `__ALL__` 与其他 `scenario_tag` 混合 SUM**。
- **`feature_detail='__ALL__'` 行与明细行的指标不对称**：广告 ADVV 指标仅在 `feature_detail='__ALL__'` 行有值，明细行强制补 0，两类行不可混合聚合广告指标。
- **source1/source2 来源的流量指标不可用**：`imp_cnt`、`click_cnt`、`item_imp_cnt`、`item_click_cnt` 在 source1/source2 来源行补 0，仅转化漏斗指标（PPV、cart、order、GMV）有效，使用 `feature_detail` 明细数据时需注意该限制。
- **GMV 截尾指标为预聚合结果**：`high_gmv_995_v2` 等字段已在订单粒度截尾后再聚合，不可与原始 `gmv` 直接相加比较，也不可对截尾指标跨场景重复 SUM。
- **CACHE TABLE 依赖**：ETL 使用 `CACHE TABLE` 缓存中间结果，在 Spark 集群内存不足时可能降级为磁盘序列化，需关注集群资源配置。

---

*文档生成时间：2026-05-17*