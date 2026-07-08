<!-- ads-workspace-gdoc-sync: gdoc_id=1qz7xKrklVMNyIZyYiFIZOQHdaYpHrgOCgitDVadUIak gdoc_url=https://docs.google.com/document/d/1qz7xKrklVMNyIZyYiFIZOQHdaYpHrgOCgitDVadUIak/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_scenario_location_level_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `is_ads` + `location` + `scenario_tag`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日（1d）
**引用频次 / 访问频次：** 46

---

## 业务描述

本表是搜索与推荐（SR）数据仓库平台的 **场景 × 位置 × 广告标识** 维度日粒度汇总表，基于用户行为明细（曝光、点击、加购、下单等）按场景标签（`scenario_tag`）和坑位位置（`location`）双维度进行聚合，并同时提供"全量"与"广告/非广告"两个 `is_ads` 口径（`__ALL__` 表示全量）。

**核心业务场景：**
- 分析不同推荐/搜索场景（Homepage DPM 业务线、模块、算法标签、页面类型等）在各坑位位置上的流量质量与转化效能。
- 评估广告与自然流量在各场景、各位置的曝光-点击-加购-下单漏斗表现。
- 支持 ATC（加购后）当日及 3 日内归因的订单和 GMV 分析。

**适合回答的问题：**
- 某大区某日，指定场景标签下各坑位的曝光 UV、点击 UV 及点击率趋势如何？
- 广告坑位与自然坑位在特定场景下的下单量和 GMV 差异？
- 加购后当日、3 日内的转化订单数和 GMV 各是多少？
- 某算法标签 / DPM 模块在各坑位上的 PPV（排除回跳）UV 表现？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 ID、MY、TH 等；每次查询必须指定 |
| `local_date` | date | 业务本地日期，ETL 每日 INSERT OVERWRITE 写入对应分区 |

### 维度：场景 × 位置 × 广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenario_tag` | string | 场景标签，由 reporting_business_line、reporting_module、algo_tag、mapped_page_type 等拼接后 EXPLODE 展开，每行代表一个场景维度值（如 `dpm business line Homepage`、`Page xxx` 等） |
| `location` | int | 商品坑位位置，原始值 ≥ 250 时截断为 250；同时包含本次曝光位置及 source1/source2 归因位置 |
| `is_ads` | string | 广告标识：`true` / `false`；`__ALL__` 表示广告与自然流量合并的全量口径（由 GROUPING SETS 生成） |

### 指标：流量曝光

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（operation = 'impression' 的 operation_cnt 之和） |
| `imp_uu` | bigint | 曝光去重用户数（有曝光行为的 user_id 去重计数） |
| `omni_imp_cnt` | bigint | Omni 曝光次数（operation = 'omni_impression' 的 operation_cnt 之和） |
| `omni_imp_uu` | bigint | Omni 曝光去重用户数 |

### 指标：点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 点击次数（operation = 'click' 的 operation_cnt 之和） |
| `click_uu` | bigint | 点击去重用户数 |
| `omni_click_cnt` | bigint | Omni 点击次数（operation = 'omni_click' 的 operation_cnt 之和） |
| `omni_click_uu` | bigint | Omni 点击去重用户数 |

### 指标：详情页浏览（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页浏览次数（operation = 'ppv' 的 operation_cnt 之和） |
| `ppv_cnt_exclude_isback` | bigint | 排除回跳（is_back = true）后的 PPV 次数 |
| `ppv_exclude_isback_uu` | bigint | 排除回跳后有 PPV 行为的去重用户数 |

### 指标：加购（ATC）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数（operation = 'cart' 的 operation_cnt 之和） |
| `atc_uu` | bigint | 加购去重用户数 |

### 指标：下单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单笔数（operation = 'order' 的 operation_cnt 之和） |
| `order_uu` | bigint | 下单去重用户数 |
| `gmv` | double | 下单 GMV（operation = 'order' 时 place_order_gmv 之和） |

### 指标：ATC 归因订单与 GMV（时间窗口）

| 字段 | 类型 | 说明 |
|---|---|---|
| `atc_same_day_order_cnt` | double | 加购当日（window_day = 1）归因下单笔数 |
| `atc_within_3day_order_cnt` | double | 加购后 3 日内（window_day in [1, 4]）归因下单笔数 |
| `atc_same_day_gmv` | double | 加购当日归因下单 GMV |
| `atc_within_3day_gmv` | double | 加购后 3 日内归因下单 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：`grass_region` 和 `local_date`，缺失任意一个都会触发全分区扫描，严重影响性能。

```sql
WHERE grass_region = 'ID'
  AND local_date = '2025-05-01'
```

- 如需区分广告与自然流量，请过滤 `is_ads`：`'true'` / `'false'`；若需全量口径，使用 `is_ads = '__ALL__'`，**不要对 `is_ads` 做 SUM/COUNT 聚合后再过滤**，否则会重复计算。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`omni_imp_uu`、`omni_click_uu`、`ppv_exclude_isback_uu`、`atc_uu`、`order_uu` | 去重用户数（COUNT DISTINCT），跨 `scenario_tag` 或跨 `location` 直接 SUM 会导致用户重复计算 |

- 对于累加型指标（`imp_cnt`、`click_cnt`、`order_cnt`、`gmv` 等），在相同 `is_ads` 口径下跨 `scenario_tag` 或 `location` 聚合时也需注意：由于一个用户行为可能同时归属多个 scenario_tag（EXPLODE 展开），跨 `scenario_tag` SUM 存在重复计数风险。

### is_ads 口径说明

- `is_ads = '__ALL__'`：由 GROUPING SETS 生成的全量汇总行，与 `is_ads IN ('true','false')` 的合计**不能直接混用**，避免双重计算。

### 时效性说明

- 本表为 **T+1 日刷新**（1d 后缀），反映前一个自然日的行为数据，不适用于实时或准实时场景。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 用户行为明细事件表，提供 operation、operation_cnt、place_order_gmv、is_back、window_day、location、feature_detail、reporting_business_line、reporting_module、algo_tag 等字段，是本表的唯一数据来源 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    │  (过滤大区、日期、operation 类型、排除特定 feature_detail)
    ▼
dwd_derived_scenario           -- 字段清洗：location 截断、场景标签字段映射
    ▼
concat_data_raw                -- 拼接 scenario_tags_str / source1 / source2
    ▼
concat_data                    -- 拆分为 scenario_tags 数组（含 algo_tag 多值）
    ▼
user_location_base             -- 按 user_id + is_ads + scenario_tags + location 聚合各行为指标
                               -- 仅保留 scenario_tags / source1 / source2 至少一个 size > 1 的记录
    ▼
base_table                     -- UNION ALL：本次位置 + source1 位置 + source2 位置（三路归因展开）
    ▼
base_table_filtered            -- 过滤 size(scenario_tags) > 1
    ▼
base_table_exploded            -- LATERAL VIEW EXPLODE(scenario_tags)：每行展开为单个 scenario_tag
    ▼
metrics_agg                    -- GROUPING SETS：(is_ads, location, scenario_tag) 和 (location, scenario_tag)
                               -- 计算 UU（COUNT DISTINCT）和 CNT（SUM）指标
    ▼
INSERT OVERWRITE dws_sr_data_warehouse_platform_scenario_location_level_metrics_1d
PARTITION(grass_region, local_date)
    -- COALESCE(is_ads, '__ALL__') 将 GROUPING SETS 中 is_ads 为 NULL 的行标记为 '__ALL__'
```

### 关键步骤

1. **dwd_derived_scenario**：从 DWD 明细层读取指定大区和日期的行为数据，过滤有效 operation 类型（impression、click、ppv、cart、order、omni_impression、omni_click），排除底部导航栏、推送通知等干扰性 feature_detail；对 location ≥ 250 的坑位截断为 250；将 reporting_business_line、reporting_module（仅 Homepage 业务线）、algo_tag、feature_detail 中的页面类型拼装为场景标签原材料，同时处理 source1、source2 两级归因来源。

2. **concat_data_raw / concat_data**：将场景标签原材料用 `concat_ws(',')` 拼接为字符串，再 `split` 回数组，以兼容 algo_tag 本身含逗号的情况。

3. **user_location_base**：按 `user_id + is_ads + scenario_tags 数组 + location`（含 source1/source2 维度）聚合，计算各行为指标的 SUM；仅保留三路 scenario_tags 数组中至少一路 size > 1 的记录（确保场景标签有效）。

4. **base_table（UNION ALL 三路）**：将本次位置归因、source1 位置归因、source2 位置归因三路数据合并，实现多归因路径的位置展开。

5. **base_table_filtered / base_table_exploded**：过滤有效 scenario_tags 后，通过 `LATERAL VIEW EXPLODE` 将 scenario_tags 数组展开，每个 scenario_tag 值成为独立一行。

6. **metrics_agg**：使用 `GROUPING SETS((is_ads, location, scenario_tag), (location, scenario_tag))` 一次性计算广告分层和全量两个口径的 UU 指标（COUNT DISTINCT）及 CNT 指标（SUM），过滤空 scenario_tag。

7. **INSERT OVERWRITE**：将聚合结果写入目标表对应分区，`COALESCE(is_ads, NULL) → '__ALL__'` 标记全量汇总行。

### 注意事项

- **单文件单 writer**：本表无 multi-writer 风险，ETL 仅有 1 个源文件，`INSERT OVERWRITE` 按 `(grass_region, local_date)` 分区写入，不同大区、不同日期的任务互不干扰。
- **三路归因重复计数**：base_table UNION ALL 三路数据后未做去重，同一用户在同一行为可能通过本次位置、source1 位置、source2 位置三路各贡献一次，指标在跨 location 聚合时存在重复计数，应在单一 location 维度下分析或了解此设计背景后使用。
- **场景标签过滤条件**：`size(scenario_tags) > 1` 要求数组长度严格大于 1（即至少含两个元素），这意味着单独一个场景维度不满足条件，须两个及以上场景维度组合才被纳入统计。
- **location 截断**：坑位号 ≥ 250 均归并为 250，高坑位分析时需注意该聚合效果。
- **`__ALL__` 口径**：查询时若不过滤 `is_ads`，会同时返回广告分层行和 `__ALL__` 全量行，造成数据重复，务必明确过滤。

---

*文档生成时间：2026-05-17*