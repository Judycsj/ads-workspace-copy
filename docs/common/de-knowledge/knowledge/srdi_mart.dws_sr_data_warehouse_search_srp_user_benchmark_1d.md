<!-- ads-workspace-gdoc-sync: gdoc_id=1NXrOKgKLgCSrinxFQbgl5BLMvesniZZLrhd-vd3rUAs gdoc_url=https://docs.google.com/document/d/1NXrOKgKLgCSrinxFQbgl5BLMvesniZZLrhd-vd3rUAs/edit -->

# srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d

**分层：** dws_search
**主键：** user_id, device_id, platform, page_type, page_section, target_type, keyword, is_ads, sort_type, location_type, search_entrance, search_mid, is_llm_deepthinking, grass_region, local_date
**分区：** grass_region, local_date
**更新频率：** 每日（1d）
**引用频次 / 访问频次：** 10,277

---

## 业务描述

本表为搜索 SRP（Search Result Page）页面的**用户 × 关键词**粒度日汇总宽表，面向搜索业务数仓的核心明细聚合层。

**核心业务场景：**
- 以用户维度分析 SRP 页面的搜索行为：曝光、点击、浏览、加购、下单及 GMV 等转化漏斗指标；
- 结合关键词聚类（`keyword_cluster`）与关键词类目（`level1/level2_keyword_category`）分析搜索词质量与用户意图；
- 区分广告位（`is_ads`）、排序方式（`sort_type`）、位置区间（`location_type`）等页面特征，支持广告效果与算法排序对比分析；
- 支持按地区（`grass_region`）、平台（`platform`）、页面类型（`page_type`）、搜索入口（`search_entrance`）等多维切片；
- 支持 LLM 深度思考功能（`is_llm_deepthinking`）对搜索行为影响的实验分析。

**适合回答的问题：**
- 某地区某日，特定关键词下不同平台的 CTR / CVR / GMV 是多少？
- 广告与自然结果在 SRP 的曝光点击差异如何？
- 搜索入口（`search_entrance`）和搜索模块（`search_mid`）对转化的影响？
- 哪些关键词聚类/类目带来了最多订单和 GMV？
- 开启 LLM 深度思考的用户与普通用户的搜索转化对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区，如 TH、ID、VN 等，所有查询必须指定 |
| `local_date` | date | 业务日期（本地时区），所有查询必须指定 |

### 维度：用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 登录用户 ID；未登录用户该字段为 NULL 或 0 |
| `device_id` | string | 设备 ID，用于覆盖未登录用户行为 |

### 维度：页面与平台

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，如 android、ios、pc 等 |
| `page_type` | string | 页面类型，来源于 `dim_search_domain_map` 映射后的 `mapped_page_type`，仅保留搜索域页面 |
| `page_section` | string | 页面分区/版块，如商品列表、视频区等 |
| `target_type` | string | 结果目标类型，如商品、店铺、视频等 |
| `location_type` | string | 结果位置区间分桶：0~9 按位逐一区分，10~19、20~29、30~39、40~49、50+ 分段，NULL 时显示 NA |

### 维度：搜索关键词与分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词（已做 TRIM + LOWER 标准化处理） |
| `keyword_cluster` | string | 关键词聚类，来源于 `dim_sr_data_warehouse_keyword_di`，同一关键词取 FIRST 值 |
| `level1_keyword_category` | string | 关键词一级类目，来源于 `dim_sr_data_warehouse_keyword_di` |
| `level2_keyword_category` | string | 关键词二级类目，来源于 `dim_sr_data_warehouse_keyword_di` |
| `last_keyword` | string | 上一次搜索关键词；当前 ETL 固定写入 NULL，暂未填充 |
| `module_keyword_type` | string | 模块关键词类型；当前 ETL 固定写入 NULL，暂未填充 |
| `entrance_keyword_type` | string | 入口关键词类型；当前 ETL 固定写入 NULL，暂未填充 |

### 维度：搜索入口与排序

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口标识；空串统一转为 NA |
| `search_mid` | string | 搜索中间层/模块标识；空串统一转为 NA |
| `sort_type` | string | 排序方式，如综合排序、销量、价格等 |

### 维度：广告与特性标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | string | 是否为广告位，Flag of whether the target is an ad；上游为 NULL 时统一替换为 false |
| `is_llm_deepthinking` | boolean | 是否开启 LLM 深度思考功能；上游为 NULL 时统一替换为 FALSE |

### 指标：曝光与浏览

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（impression count） |
| `view_cnt` | bigint | 浏览次数（商品详情页 PV） |
| `view_not_back_cnt` | bigint | 浏览后未回跳次数（有效浏览） |
| `ppv_cnt` | bigint | PPV（Post-Page View）次数 |
| `ppv_include_isback_cnt` | bigint | 含回跳行为的 PPV 次数 |

### 指标：点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 点击次数 |

### 指标：加购与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购物车次数 |
| `order_cnt` | double | 下单件数/笔数（来源字段为 double，注意精度） |
| `algo_order_cnt` | double | 算法归因订单数；当前 ETL 固定写入 NULL，暂未填充 |

### 指标：GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 成交金额（美元或统一货币） |
| `gmv_local` | double | 本地货币 GMV |
| `pc2_gmv` | double | PC2 口径 GMV（特定归因模型下的 GMV） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，**每次查询必须同时指定**，否则将触发全表扫描，严重影响性能并可能产生高额计算费用。
- 示例：`WHERE grass_region = 'TH' AND local_date = '2025-01-01'`
- 若需多日数据，使用 `local_date BETWEEN '...' AND '...'` 并明确 `grass_region`。

### 不可直接 SUM 的字段

- **`order_cnt`、`gmv`、`gmv_local`、`pc2_gmv`、`algo_order_cnt`** 均为 double 类型，可在用户×关键词×维度粒度内 SUM 汇总，但跨不同维度切片时需注意**数据重复计算风险**（同一用户在多维组合下可能被多次计入）。
- **`is_ads`** 字段为 string 类型（非 boolean），过滤时需使用字符串比较：`WHERE is_ads = 'true'`。
- **`last_keyword`、`module_keyword_type`、`entrance_keyword_type`、`algo_order_cnt`** 当前全部为 NULL，查询这些字段将得到空值，不可用于过滤或聚合。
- `keyword_cluster`、`level1_keyword_category`、`level2_keyword_category` 通过 LEFT JOIN 关键词维表补全，若关键词未命中维表则为 NULL，聚合时需注意 NULL 分组行为。

### 时效性说明

- 本表为 **T+1 日更新**（`_1d` 后缀），数据反映前一自然日（本地时区）的行为。
- 每日通过 `INSERT OVERWRITE PARTITION` 全量覆写当日分区，幂等性强，无需担心重复写入。
- 关键词维度信息来自同日（`local_date`）的 `dim_sr_data_warehouse_keyword_di`，如维表当日数据未就绪可能导致关键词分类字段为 NULL。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 主数据源，提供用户×关键词×商品粒度的搜索行为指标，过滤 `original_page_type = 'search'` 后聚合至用户×关键词粒度 |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词维表，补充关键词聚类（`keyword_cluster`）、一级/二级关键词类目 |
| `mp_foa.dim_search_domain_map__reg_live` | 搜索域页面类型映射表，用于过滤合法的搜索 `page_type`，取前一天（`grass_date = date_sub(local_date, 1)`）数据 |

---

## ETL 逻辑摘要

### 数据流

```
mp_foa.dim_search_domain_map__reg_live
        │ (过滤合法 page_type)
        ▼
srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d
        │ (过滤 search 域，按用户×关键词×维度聚合)
        ▼
dws_user_keyword [Temp View]
        │
        ├──── LEFT JOIN ────►  srdi_mart.dim_sr_data_warehouse_keyword_di [Temp View]
        │                       (补充 keyword_cluster / 类目)
        ▼
srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d
        (INSERT OVERWRITE PARTITION)
```

### 关键步骤

**Step 1 — Temporary View: `dim_keyword_<region>`**
从关键词维表 `dim_sr_data_warehouse_keyword_di` 按当日分区和大区过滤，以 keyword 为 GROUP BY KEY，用 `FIRST()` 聚合取 `keyword_cluster`、`level1_keyword_category`、`level2_keyword_category`，避免一个关键词对应多条记录时关联结果膨胀。

**Step 2 — Temporary View: `click_search_domain_map_<region>`**
从 `mp_foa.dim_search_domain_map__reg_live` 中取前一天（`date_sub(local_date, 1)`）指定大区的合法搜索页面类型列表（`mapped_page_type`），用于后续 IN 子查询过滤。

**Step 3 — Temporary View: `dws_user_keyword_<region>`**
从 `dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` 中：
- 过滤 `original_page_type = 'search'` 且 `page_type` 在合法域映射内；
- 对 `keyword` 做 `TRIM(LOWER(...))` 标准化；
- 对 `is_ads` NULL 值填充 false，`search_entrance`/`search_mid` 空串填充 NA，`is_llm_deepthinking` NULL 填充 FALSE；
- `location` 字段按区间分桶为 `location_type`（0~9 逐位、之后每 10 分段、50+ 归并）；
- 按用户×设备×平台×页面×关键词×标记等 13 个维度 GROUP BY，对所有度量指标求 SUM。

**Step 4 — Final INSERT OVERWRITE**
将 Step 3 结果与 Step 1 关键词维表 LEFT JOIN（关联键为标准化后的 `keyword`），选取全部业务字段写入目标表分区。其中 `last_keyword`、`algo_order_cnt`、`module_keyword_type`、`entrance_keyword_type` 当前版本固定写入 NULL，预留供后续扩展。

### 注意事项

- **单一 Writer**：`multi_writer = false`，该表仅由一个 ETL 文件写入，无并发写冲突风险。
- **分区覆写**：采用 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 方式，每次运行幂等覆盖当日当地区分区，重跑安全。
- **域映射时效**：`dim_search_domain_map__reg_live` 使用 `date_sub(local_date, 1)` 的前一天数据，需确保该维表前一日分区已产出，否则 `click_search_domain_map` 为空导致 `page_type IN (...)` 过滤后数据全丢。
- **关键词维表缺失**：`dim_sr_data_warehouse_keyword_di` 使用当日分区，若维表产出晚于主表 ETL 触发时间，则 `keyword_cluster` 及类目字段全部为 NULL，需注意调度依赖顺序。
- **NULL 字段预留**：`last_keyword`、`algo_order_cnt`、`module_keyword_type`、`entrance_keyword_type` 均为 NULL 占位字段，使用时勿参与计算或过滤。
- **`is_ads` 类型**：字段在 DataMap 中为 string，ETL 源表中原始类型为布尔，写入时经 `IF(is_ads IS NOT NULL, is_ads, false)` 处理，查询过滤时应使用字符串字面值（如 `'true'`、`'false'`）。

---

*文档生成时间：2026-05-17*