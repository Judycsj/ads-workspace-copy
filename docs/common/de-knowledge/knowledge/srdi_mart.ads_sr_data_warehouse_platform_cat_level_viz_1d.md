<!-- ads-workspace-gdoc-sync: gdoc_id=1OV4Pf_pgUvWSEX6E9spXw1OEBmiKsElk1Lkp8aLrQd4 gdoc_url=https://docs.google.com/document/d/1OV4Pf_pgUvWSEX6E9spXw1OEBmiKsElk1Lkp8aLrQd4/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_cat_level_viz_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `scenario_tag` + `is_ads` + `level1_global_be_category_id` + `level2_global_be_category_id`
**分区：** `grass_region`（站点大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 2448 次

---

## 业务描述

本表是搜索与推荐（Search & Recommendation）数仓平台的**品类层级可视化日聚合 ADS 宽表**，以「站点 × 日期 × 场景标签 × 是否广告 × 一级品类 × 二级品类」为粒度，汇总用户在各品类下的曝光、点击、浏览（PPV）、加购、下单等全链路行为指标，以及涉及的商品数、店铺数、新店数和 GMV。

**核心业务场景：**

- **品类健康度监控**：按一级 / 二级品类下钻，分析各漏斗层级（曝光→点击→加购→下单）的转化表现。
- **搜推场景对比**：通过 `scenario_tag` 区分不同搜推场景（如搜索、推荐、首页等），横向对比各场景的品类流量质量。
- **广告 vs 自然流量拆解**：`is_ads` 字段区分广告流量和自然流量，支持广告效果评估。
- **新店/老店分析**：通过 `*_new_shop_cnt` 指标追踪新入驻店铺（创店 7 天内）在各品类的曝光与转化情况。
- **全站基准对比**：`scenario_tag = '__ALL__'`、`level1_global_be_category_id = 0`、`level2_global_be_category_id = 0` 分别代表全场景、全一级品类、全二级品类的汇总行，可直接用于基准线对比。

**适合回答的问题举例：**

- 某大区某日，各一级品类下的曝光用户数（`imp_uu`）和点击用户数（`click_uu`）分别是多少？
- 搜索场景下，二级品类 A 的广告 GMV 占比如何？
- 近期新店在各品类的曝光覆盖情况（`imp_new_shop_cnt`）如何变化？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识，如 `SG`、`MY` 等；查询时必须指定 |
| `local_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`；查询时必须指定 |

### 维度：场景与品类标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 搜推场景标签；`__ALL__` 表示所有场景合计 |
| `is_ads` | string | 是否广告流量；`'true'` 为广告，`'false'` 为自然流量，`'__ALL__'` 表示不区分 |
| `level1_global_be_category_id` | bigint | 全球后端一级品类 ID；`0` 表示全品类汇总，`-1` 表示品类未知 |
| `level2_global_be_category_id` | bigint | 全球后端二级品类 ID；`0` 表示全品类汇总，`-1` 表示品类未知 |
| `level1_global_be_category` | string | 全球后端一级品类名称；`__ALL__` 表示全品类汇总，`__UNKNOWN__` 表示品类名称未能映射 |
| `level2_global_be_category` | string | 全球后端二级品类名称；`__ALL__` 表示全品类汇总，`__UNKNOWN__` 表示品类名称未能映射 |

### 指标：曝光（Impression）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（行为事件总计） |
| `imp_uu` | bigint | 曝光独立用户数（去重 user_id） |
| `imp_uv` | bigint | 曝光 UV（当前版本 ETL 中恒为 `null`，预留字段） |
| `imp_item_cnt` | bigint | 曝光涉及的独立商品数（去重 item_id） |
| `imp_shop_cnt` | bigint | 曝光涉及的独立店铺数（去重 shop_id） |
| `imp_new_shop_cnt` | bigint | 曝光涉及的新店铺数（创店 ≤ 7 天，去重 shop_id） |

### 指标：点击（Click）

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 点击次数 |
| `click_uu` | bigint | 点击独立用户数（去重 user_id） |
| `click_item_cnt` | bigint | 点击涉及的独立商品数（去重 item_id） |
| `click_shop_cnt` | bigint | 点击涉及的独立店铺数（去重 shop_id） |
| `click_new_shop_cnt` | bigint | 点击涉及的新店铺数（去重 shop_id） |

### 指标：商品详情页浏览（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页浏览次数（Product Page View） |
| `ppv_uu` | bigint | 商品详情页浏览独立用户数（去重 user_id） |

### 指标：加购（Cart）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数 |
| `cart_uu` | bigint | 加购独立用户数（去重 user_id） |
| `cart_item_cnt` | bigint | 加购涉及的独立商品数（去重 item_id） |
| `cart_shop_cnt` | bigint | 加购涉及的独立店铺数（去重 shop_id） |
| `cart_new_shop_cnt` | bigint | 加购涉及的新店铺数（去重 shop_id） |

### 指标：下单（Order）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单件数 |
| `order_uu` | bigint | 下单独立用户数（注意：ETL 中实际使用 `cart_cnt > 0` 的去重用户计算，与加购用户数等同，详见注意事项） |
| `order_item_cnt` | bigint | 下单涉及的独立商品数（去重 item_id） |
| `order_shop_cnt` | bigint | 下单涉及的独立店铺数（去重 shop_id） |
| `order_new_shop_cnt` | bigint | 下单涉及的新店铺数（去重 shop_id） |
| `gmv` | double | 成交金额（Gross Merchandise Value） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，**所有查询必须同时指定这两个分区**，否则将触发全表扫描，导致资源浪费和性能劣化。
- 如需特定场景数据，应同时过滤 `scenario_tag`；若查全量场景合计，使用 `scenario_tag = '__ALL__'`。
- 如需区分广告/自然流量，过滤 `is_ads = 'true'` 或 `is_ads = 'false'`；若需全量不区分，使用 `is_ads = '__ALL__'`。
- 品类下钻时，`level1_global_be_category_id = 0` 代表全品类汇总行，`level2_global_be_category_id = 0` 同理，**避免与明细行重复累加**。

### 不可直接 SUM 的字段

以下字段属于**去重计数（COUNT DISTINCT）预聚合**结果，跨维度（如多品类、多场景）聚合时**不能直接 SUM**，否则会导致重复计算：

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu` | 基于 user_id 去重计算，跨分组直接 SUM 会产生重复 |
| `imp_item_cnt`、`click_item_cnt`、`cart_item_cnt`、`order_item_cnt` | 基于 item_id 去重计算 |
| `imp_shop_cnt`、`click_shop_cnt`、`cart_shop_cnt`、`order_shop_cnt` | 基于 shop_id 去重计算 |
| `imp_new_shop_cnt`、`click_new_shop_cnt`、`cart_new_shop_cnt`、`order_new_shop_cnt` | 基于新店 shop_id 去重计算 |

如需跨品类/跨场景汇总上述去重指标，**应使用表中预置的 `level1_global_be_category_id = 0` 或 `scenario_tag = '__ALL__'` 等汇总行**，而非手动 SUM 明细行。

### 特殊字段说明

- **`imp_uv`**：当前 ETL 中该字段恒为 `null`，为预留字段，**不可用于分析**。
- **`order_uu`**：ETL 实现中以 `cart_cnt > 0` 的去重用户数填充此字段（而非 `order_cnt > 0`），存在语义偏差，使用时需注意其实际含义为「有加购行为的去重用户数」。
- **`level1_global_be_category_id = -1` / `level2_global_be_category_id = -1`**：表示商品无法映射到品类的未知行，与 `0`（全品类汇总）含义不同，查询时需注意区分。
- **新店判定**：`is_new_shop` 基于 `datediff(local_date, shop_create_datetime) <= 7` 计算，即以当日为基准，创店不超过 7 天的店铺。

### 时效性说明

- 本表为 **T+1 日刷新**的全量覆盖写入表（`INSERT OVERWRITE PARTITION`），每日产出前一日数据。
- 不包含小时级或实时数据。
- 无滑动窗口（`_nd`）字段，所有指标均为**单日当日**的汇总值。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 主事实源，提供用户维度的曝光、点击、PPV、加购、下单等行为事件明细，以及场景标签、是否广告标识 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，提供 item_id 到一级/二级品类 ID 及品类名称的映射 |
| `srdi_mart.dim_sr_data_warehouse_shop` | 店铺维度表，提供 shop_id 对应的店铺创建时间，用于判断是否为新店 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item (行为明细)
        │
        ▼
dwm_base  ──── left join ──── dim_sr_data_warehouse_item (品类映射)
        │
        ▼
dwm_join  (关联品类 ID；item_id <= 0 归为 -1 品类)
        │
        ▼
benchmark_inter  (展开 scenario_tag / '__ALL__' 双路 + 按用户/商品/店铺聚合)
        │
        ▼
benchmark_final  (补充品类层级汇总行：level2=0 行 + level1=level2=0 行)
        │
        ├──► user_data_final   (按 user_id 聚合，用于 UU 类指标)
        ├──► item_data_final   (按 item_id 聚合，用于商品数指标)
        └──► shop_data_final   ──── left join ──── dim_sr_data_warehouse_shop (新店标记)
                                                    (按 shop_id 聚合，用于店铺数指标)
        │
        ▼
result_union  (三路 UNION ALL，分别计算 UU/商品数/店铺数，使用 grouping sets 生成 is_ads/__ALL__ 两套)
        │
        ▼
result_group  (按维度聚合，用 MAX 合并三路 null 填充的宽表)
        │
        ├──── left join ──── level1_category_mapping (一级品类 ID→名称)
        └──── left join ──── level2_category_mapping (二级品类 ID→名称)
        │
        ▼
INSERT OVERWRITE ads_sr_data_warehouse_platform_cat_level_viz_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 核心逻辑 |
|---|---|---|
| 1 | `dwm_base` | 从 DWM 事实表过滤当日当站点数据；合并三路 scenario_tags 为 `union_scenario_tags`；标准化 `is_ads` 为字符串 |
| 2 | `item_category` | 从商品维度表取品类 ID 映射，过滤无效商品（`item_id > 0`） |
| 3 | `dwm_join` | 事实表 left join 品类映射；`item_id <= 0` 或无法映射的记录品类 ID 统一标为 `-1`；UNION ALL 保留两路 |
| 4 | `benchmark_inter` | 双路 UNION ALL：第一路以 `'__ALL__'` 为 scenario_tag 聚合全场景；第二路 `LATERAL VIEW EXPLODE` 展开各场景标签，按 `(scenario_tag, is_ads, 品类, user_id, item_id, shop_id)` 聚合 |
| 5 | `benchmark_final` | 三路 UNION ALL：原始明细行 + `level2=0` 品类汇总行 + `level1=level2=0` 全品类汇总行，构建多粒度分析基础 |
| 6 | `user_data_final` | 按 `(scenario_tag, is_ads, 品类, user_id)` 聚合，为 UU 去重计算准备 |
| 7 | `item_data_final` | 过滤 `item_id > 0`，按 `(scenario_tag, is_ads, 品类, item_id)` 聚合，为商品去重计算准备 |
| 8 | `shop_data_base` / `shop_data` / `shop_data_final` | 过滤 `shop_id > 0`，关联店铺维度表，基于 `datediff ≤ 7` 打上 `is_new_shop` 标记 |
| 9 | `result_union` | 三路 UNION ALL（用户维度/商品维度/店铺维度），各路仅填充自身负责的列，其余列置 `null`；使用 `GROUPING SETS` 同时生成 `is_ads` 原值和 `'__ALL__'` 两套分组 |
| 10 | `result_group` | 按维度聚合，用 `MAX()` 将三路 `null` 填充的宽表合并为完整宽表 |
| 11 | `level1_category_mapping` / `level2_category_mapping` | 从商品维度表聚合取各品类 ID 对应的代表性名称（`MAX`） |
| 12 | `INSERT OVERWRITE` | BROADCAST JOIN 关联两级品类名称；`level1/2_global_be_category_id = 0` 输出 `'__ALL__'`，无映射输出 `'__UNKNOWN__'`；`imp_uv` 恒写入 `null` |

### 注意事项

- **单 Writer**：本表仅由一个 ETL 文件写入，无多 Writer 并发冲突风险，但每次执行为 `INSERT OVERWRITE PARTITION`，会全量覆盖该 `(grass_region, local_date)` 分区。
- **`order_uu` 计算偏差**：ETL 中 `order_uu` 实际使用 `count(distinct if(cart_cnt > 0, user_id, null))`（即加购用户数）而非下单用户数，字段语义与名称不符，使用时需特别注意。
- **`imp_uv` 预留**：最终 INSERT 中 `imp_uv` 写入 `null`，字段已存在于 DDL 但当前无实际数据，不可用于分析。
- **品类汇总行与明细行共存**：`level1_global_be_category_id = 0` 和 `level2_global_be_category_id = 0` 为预聚合汇总行，与明细品类行共存于同一分区，直接 SUM 所有行将导致重复计算，务必在查询中明确过滤或区分。
- **`-1` 品类含义**：`level1/2_global_be_category_id = -1` 表示商品无法映射到有效品类（原始 ID ≤ 0 或维度表中不存在），与 `0`（汇总行）含义不同。
- **Broadcast Join 提示**：最终 INSERT 使用 `/*+ BROADCAST(t2, t3) */` 对品类映射表进行广播，若品类表数据量大幅增长，需关注 Spark 内存压力。

---

*文档生成时间：2026-05-17*