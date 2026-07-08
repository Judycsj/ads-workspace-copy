<!-- ads-workspace-gdoc-sync: gdoc_id=1ZmSYnGzV9rAABhhMD74QdEHp1z41x19H-1Qn_T_u0QA gdoc_url=https://docs.google.com/document/d/1ZmSYnGzV9rAABhhMD74QdEHp1z41x19H-1Qn_T_u0QA/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_feature_location_level_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `is_ads` + `feature_detail` + `location`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE）
**访问频次：** 969 次

---

## 业务描述

本表以 **平台功能位置（feature × location）** 为粒度，汇总搜推平台各页面功能区域在不同广告/非广告场景下的日维度用户行为指标，覆盖曝光、点击、全渠道曝光/点击、商品详情页浏览（PPV）、加购（ATC）、下单及 GMV 等核心漏斗指标。

**核心业务场景：**
- 分析各页面功能区域（`feature_detail`）在不同坑位（`location`）的流量表现与转化效率；
- 对比广告流量（`is_ads = 'true'`）与自然流量（`is_ads = 'false'`）在同一位置的曝光、点击、转化差异；
- 评估加购后当日及 3 日内的归因下单量与 GMV，支持 ATC 窗口归因分析；
- 支持 DPM 业务线（Homepage）场景标签筛选后的漏斗分析。

**适合回答的典型问题：**
- 某功能区域（如首页轮播）第 N 位的昨日曝光 UV、点击 UV 分别是多少？
- 广告位与自然位在同一功能区域的 CTR 差异如何？
- 用户加购后当日下单率与 3 日内转化 GMV 贡献如何？
- 各 feature_detail 在不同坑位的 PPV（排除回退）表现？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`MY`、`TH` 等，每次写入覆盖单个大区分区 |
| `local_date` | date | 业务日期（本地日期），格式 `yyyy-MM-dd` |

---

### 维度：功能位置与广告标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 页面功能区域标识，格式如 `页面-模块`（例：`home-flash_sale`）；同时包含来源 source1/source2 的归因维度展开值 |
| `location` | int | 功能区域内的坑位序号；原始值 ≥ 250 时统一截断为 250 |
| `is_ads` | string | 广告标识：`'true'` 表示广告流量，`'false'` 表示自然流量，`'__ALL__'` 表示广告与非广告合计（由 GROUPING SETS 聚合生成） |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（operation = 'impression' 的 operation_cnt 汇总） |
| `imp_uu` | bigint | 曝光独立用户数（有曝光行为的去重 user_id 数） |
| `click_cnt` | bigint | 点击次数（operation = 'click' 的 operation_cnt 汇总） |
| `click_uu` | bigint | 点击独立用户数（有点击行为的去重 user_id 数） |
| `omni_imp_cnt` | bigint | 全渠道曝光次数（operation = 'omni_impression' 的 operation_cnt 汇总） |
| `omni_imp_uu` | bigint | 全渠道曝光独立用户数 |
| `omni_click_cnt` | bigint | 全渠道点击次数（operation = 'omni_click' 的 operation_cnt 汇总） |
| `omni_click_uu` | bigint | 全渠道点击独立用户数 |

---

### 指标：商品详情页浏览（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页浏览次数（operation = 'ppv' 的 operation_cnt 汇总，含回退行为） |
| `ppv_cnt_exclude_isback` | bigint | 排除回退行为后的商品详情页浏览次数（is_back 不为 true 时计入） |
| `ppv_exclude_isback_uu` | bigint | 排除回退行为后的 PPV 独立用户数 |

---

### 指标：加购（ATC）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数（operation = 'cart' 的 operation_cnt 汇总） |
| `atc_uu` | bigint | 加购独立用户数（有加购行为的去重 user_id 数） |

---

### 指标：下单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单笔数（operation = 'order' 的 operation_cnt 汇总，含所有归因窗口） |
| `order_uu` | bigint | 下单独立用户数 |
| `gmv` | double | 下单 GMV（operation = 'order' 的 place_order_gmv 汇总，含所有归因窗口） |
| `atc_same_day_order_cnt` | double | 加购当日归因下单笔数（window_day = 1 的 order 事件 operation_cnt） |
| `atc_same_day_gmv` | double | 加购当日归因 GMV（window_day = 1 的 order 事件 place_order_gmv） |
| `atc_within_3day_order_cnt` | double | 加购 3 日内归因下单笔数（window_day between 1 and 4 的 order 事件 operation_cnt） |
| `atc_within_3day_gmv` | double | 加购 3 日内归因 GMV（window_day between 1 and 4 的 order 事件 place_order_gmv） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定大区分区，否则将触发全分区扫描，严重影响性能。例：`WHERE grass_region = 'ID'`
- **`local_date`**：必须指定日期分区，避免全量历史扫描。例：`AND local_date = '2024-01-01'`
- **`is_ads`** 过滤须知：
  - 若只需广告或自然流量，使用 `is_ads = 'true'` 或 `is_ads = 'false'`；
  - 若需广告+自然汇总值，使用 `is_ads = '__ALL__'`；
  - **切勿**在 `is_ads IN ('true', 'false')` 的基础上再手动 SUM，会与 `'__ALL__'` 行重复计数。

### 不可直接 SUM 的字段

以下去重指标（`_uu` 结尾）**不可跨行直接累加**，因为同一用户可能在多个 feature_detail 或 location 下均有记录：

- `imp_uu`、`click_uu`、`omni_imp_uu`、`omni_click_uu`
- `ppv_exclude_isback_uu`、`atc_uu`、`order_uu`

若需跨功能区域汇总 UV，须回溯至明细层（`dwd_sr_data_warehouse_platform`）重新去重。

### 多来源归因展开说明

- 本表数据源自当前曝光位置（`feature_detail`/`location`）、归因来源1（`source1_feature_detail`/`source1_location`）、归因来源2（`source2_feature_detail`/`source2_location`）三路 UNION ALL 展开，同一用户的同一行为事件可能在多个 feature_detail 行中均有计入，属于设计行为，用于多触点归因分析。

### 时效性说明

- 本表为 **日粒度**（`_1d` 后缀），每日 T+1 全量覆盖写入当日分区，查询时以 `local_date` 为准。
- 不支持实时/小时级别数据，最新数据为昨日。

### 坑位截断说明

- `location` 原始值 ≥ 250 时统一聚合为 250，查询时注意此边界行包含所有高坑位的汇总数据。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜推平台行为明细宽表，提供用户维度的各类操作事件（impression/click/ppv/cart/order/omni_impression/omni_click）、功能区域、位置、广告标识、场景标签及 GMV 等原始数据 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_platform
    └─► [过滤事件类型 & 剔除噪声 feature_detail]
         └─► dwd_derived_scenario（场景标签拼接、location 截断）
              └─► concat_data_raw（场景标签字符串拼接）
                   └─► concat_data（过滤有效场景标签记录）
                        └─► user_location_base（用户×feature_detail×location 粒度行为聚合）
                             └─► base_table（三路 UNION ALL：当前位置 + source1 + source2）
                                  └─► base_table_filtered（过滤 feature_detail 非空）
                                       └─► metrics_agg（GROUPING SETS 聚合，生成 is_ads 分组与汇总两个维度组合）
                                            └─► INSERT OVERWRITE 目标表分区
```

### 关键步骤

1. **dwd_derived_scenario**（Statement 1）
   - 从 `dwd_sr_data_warehouse_platform` 过滤指定大区、日期、有效 operation 类型，并剔除底部导航栏、推送通知等噪声功能区域；
   - 对 `location` 及 source1/source2 location 做 ≥250 截断处理；
   - 仅保留 `reporting_business_line = 'Homepage'` 的 DPM 场景标签（其余置 NULL）；
   - 生成 `mapped_page_type`（取 `feature_detail` 中 `-` 前的页面类型）。

2. **concat_data_raw / concat_data**（Statements 2-3）
   - 将各层场景标签拼接为逗号分隔字符串；
   - 过滤保留至少有一路（当前/source1/source2）场景标签数量 > 1 的记录，确保归因路径有效。

3. **user_location_base**（Statement 4）
   - 以 `user_id × is_ads × feature_detail × source1_feature_detail × source2_feature_detail × location × source1_location × source2_location` 为 GROUP BY 粒度；
   - 对各 operation 类型分别条件求和，计算各类行为次数及 GMV；
   - ATC 窗口归因：`window_day = 1` 对应当日，`window_day BETWEEN 1 AND 4` 对应 3 日内（含当日共4天）。

4. **base_table**（Statement 5）
   - 三路 UNION ALL：分别以当前 `feature_detail/location`、`source1_feature_detail/source1_location`、`source2_feature_detail/source2_location` 作为聚合维度键，实现多触点归因展开。

5. **base_table_filtered**（Statement 6）
   - 过滤 `feature_detail IS NOT NULL`，去除无效归因来源扩展行。

6. **metrics_agg**（Statement 7）
   - 使用 `GROUPING SETS ((is_ads, location, feature_detail), (location, feature_detail))` 同时生成：
     - 按 `is_ads` 细分的明细行；
     - 不含 `is_ads` 的汇总行（`is_ads` 字段为 NULL，在最终写入时转为 `'__ALL__'`）；
   - 对 UV 类指标使用 `COUNT(DISTINCT CASE WHEN ... THEN user_id ELSE NULL END)` 精确去重；
   - 对次数类指标在聚合层再做正值过滤（`CASE WHEN x > 0 THEN x ELSE 0 END`）。

7. **INSERT OVERWRITE**（Statement 8）
   - 按 `grass_region` 和 `local_date` 覆盖写入目标分区；
   - 将 `is_ads` 为 NULL 的汇总行通过 `COALESCE(is_ads, '__ALL__')` 标记为全量聚合行。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件，不存在多 Writer 并发写入风险；但 SQL 中使用了 `${grass_region}` 参数，不同大区的调度作业会覆盖各自的 `grass_region` 分区，互不干扰。
- **GROUPING SETS 重复行**：目标表中同一 `(feature_detail, location)` 组合存在多行，分别对应各 `is_ads` 值（`'true'`/`'false'`）和 `'__ALL__'` 汇总行，使用时须通过 `is_ads` 条件明确选择，避免重复计算。
- **三路 UNION ALL 导致数据放大**：同一行为事件被归因到最多 3 个 feature_detail，跨 feature_detail 汇总 UV 时需注意可能的重复计数问题。
- **ATC 窗口定义**：`window_day BETWEEN 1 AND 4` 在业务含义上对应"加购后 3 日内"（含加购当日，共 4 个 window_day 值），与字段名 `within_3day` 的表述存在 off-by-one，使用时须以 SQL 逻辑为准。

---

*文档生成时间：2026-05-17*