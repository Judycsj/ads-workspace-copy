<!-- ads-workspace-gdoc-sync: gdoc_id=13hP-vtwE3mu1YRh1jRcBvFArzqoKtLpayEf2wbGpB48 gdoc_url=https://docs.google.com/document/d/13hP-vtwE3mu1YRh1jRcBvFArzqoKtLpayEf2wbGpB48/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_ni_new_item_createdate_scene_exp_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `mapping_general` + `is_ads` + `create_date_type`
**分区：** `grass_region`（地区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次/访问频次：** 6 次

---

## 业务描述

本表为搜推（SR）数仓 **新商品（New Item）实验分析** 专用汇总表，聚焦 Shopee 平台推荐链路的 **TC（流量控制/新品扶持）A/B 实验**，以 **商品创建日期分桶 × 推荐场景 × 实验分组** 为核心粒度，统计各实验分组在不同场景下的曝光、点击、成交及广告收入等指标。

**核心业务场景：**
- 追踪新品在不同推荐场景（Post Purchase OSP/MPP、Shop 系列场景、搜索、发现等）中的实验效果；
- 按商品上架时长分桶（10d / 20d / 30d / 90d / others）分析新品冷启动各阶段的实验组表现差异；
- 支持实验层（layer）级别和实验组（exp_group）级别的效果归因；
- 同时覆盖自然流量与广告流量（`is_ads`），并补充广告收入维度。

**适合回答的问题：**
- 不同实验分组在新品推荐场景中的 GMV / 订单 / 曝光表现如何？
- 新品上线 0~10 天、11~20 天等不同生命周期阶段，各实验组的转化率是否存在显著差异？
- 各场景的广告收入（USD）在实验组之间是否有差异？
- 995 口径（去除高消费异常用户）下的稳健指标表现如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/国家代码，如 ID、MY、TH、PH、SG、TW、VN |
| `local_date` | date | 业务日期（本地时区），格式 YYYY-MM-DD |

---

### 维度：实验信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `layer_id` | bigint | 实验层 ID，对应 NewItem 专属实验层（如 114215、114572、115980 等） |
| `experiment_id` | bigint | 实验 ID，标识具体 A/B 实验（如 135151、178865 等） |
| `exp_group_id` | bigint | 实验分组 ID；`-99999` 表示 group2~group8 的混合实验组 |
| `exp_group_type` | int | 实验分组类型，来源于 `dim_sr_data_warehouse_tc_exp_rule`，用于区分对照组与实验组等 |

---

### 维度：场景与商品属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `mapping_general` | string | 推荐场景归因标签，如 `Post Purchase OSP`、`Post Purchase MPP`、`Shop Product Tab`、`Shop Recommended For You`、`Shop Main Browsing`、`From the Same Shop`、`Search`、`Daily Discover`、`You May Also Like`、`S&R__ALL__`、`S&R__MAIN__`、`__ALL__` 等 |
| `is_ads` | string | 是否为广告流量，取值 `'true'`/`'false'`/`'__ALL__'`（`__ALL__` 为全流量汇总） |
| `create_date_type` | string | 商品创建日期分桶：`10d`（0~10 天）、`20d`（11~20 天）、`30d`（21~30 天）、`90d`（31~90 天）、`others`（90 天以上或无创建时间）、`__ALL__`（全量汇总） |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_pv` | bigint | 商品曝光 PV（展示次数之和） |
| `item_imp_uv` | bigint | 商品曝光 UV（有曝光的用户数，去重） |
| `item_imp_uv_995` | bigint | 995 口径曝光 UV：剔除 GPO（每单均价）超过场景 995 分位阈值的用户后的曝光用户数 |
| `item_click_pv` | bigint | 商品点击 PV |

---

### 指标：成交与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单数（含小数，来源于底层聚合） |
| `order_uv` | bigint | 下单用户数（有订单的去重用户数） |
| `gmv` | double | 全量 GMV（USD 口径，来自 `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` 的 gmv 字段） |
| `gmv_995` | double | 995 口径 GMV：仅统计 GPO ≤ 场景 995 分位阈值用户的 GMV |
| `pc2_gmv` | double | PC2 口径 GMV（Platform Commission 2 口径） |
| `pc2_gmv_995` | double | 995 口径 PC2 GMV |

---

### 指标：商品品类漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `exposed_item_cnt` | bigint | 有曝光的商品数（item 维度去重，`item_imp_pv > 0 and item_id > 0`） |
| `clicked_item_cnt` | bigint | 有点击的商品数（`item_click_pv > 0 and item_id > 0`） |
| `ordered_item_cnt` | bigint | 有成交的商品数（`order_cnt > 0 and item_id > 0`） |

---

### 指标：广告收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_ads_revenue_usd` | double | 场景广告收入（USD），仅在 `is_ads = '__ALL__'` 的行中写入，来源于付费广告明细表 |
| `scene_ads_revenue_usd_roi2` | double | 场景 ROI2 类型广告收入（USD），定价类型为 11 或 15 的广告对应收入；仅在 `is_ads = '__ALL__'` 的行中写入 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则全分区扫描，性能极差。有效值为 `'ID'`、`'MY'`、`'TH'`、`'PH'`、`'SG'`、`'TW'`、`'VN'`。
- **`local_date`**：必须指定具体日期（如 `local_date = date('2024-01-01')`），本表为日分区表，不指定将触发全量扫描。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `item_imp_uv` / `item_imp_uv_995` | 用户维度去重指标，跨实验组或跨分桶 SUM 会导致用户重复计数 |
| `order_uv` | 同上，为去重用户数 |
| `exposed_item_cnt` / `clicked_item_cnt` / `ordered_item_cnt` | 商品维度去重指标，跨维度叠加无意义 |
| `gmv_995` / `pc2_gmv_995` / `item_imp_uv_995` | 995 口径基于场景×is_ads 维度的阈值过滤，跨场景/分组直接 SUM 结果不具备可比性 |
| `scene_ads_revenue_usd` / `scene_ads_revenue_usd_roi2` | 仅在 `is_ads = '__ALL__'` 行中有值，若不过滤 `is_ads` 直接 SUM 将导致重复累加 |

### 注意事项

1. **`is_ads = '__ALL__'` 与广告收入**：`scene_ads_revenue_usd`、`scene_ads_revenue_usd_roi2` 仅在 `is_ads = '__ALL__'` 的汇总行写入，查询广告收入时必须加过滤条件 `is_ads = '__ALL__'`，否则会漏数或多数。
2. **`create_date_type = '__ALL__'`**：为商品创建日期分桶的全量汇总行，与各具体分桶（`10d`/`20d`/`30d`/`90d`/`others`）并存，聚合分析时需明确选择一种粒度，避免重复计算。
3. **`exp_group_id = -99999`**：代表 group2~group8 的混合合并实验组，是 ETL 中额外构造的 UNION ALL 行，与真实分组行并存，直接 SUM 所有 `exp_group_id` 会造成重复统计。
4. **`mapping_general = '__ALL__'` / `'S&R__ALL__'` / `'S&R__MAIN__'`**：均为汇总口径场景标签，与细粒度场景并存，请勿混用。
5. **数据时效性**：每日 T+1 更新，数据反映前一自然日的业务情况。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_tc_exp_rule` | 实验分组规则维表，提供 `exp_group_type` |
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 实验分组与实验层映射关系，构建实验流量信息 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户实验分组分配明细（assignment log），过滤有效分配日志 |
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 搜推 TC 全量卡片行为数据（曝光/点击/下单），提供流量侧基础指标 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 搜推 PB 场景基础聚合表，补充 Post Purchase、Search、Daily Discover 等主场景流量 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表，提供 `item_create_datetime`，用于计算 `create_date_type` 分桶 |
| `srdi_mart.dws_sr_data_warehouse_tc_scene_995_threshold_1d` | 场景 995 分位 GPO 阈值表，用于计算 995 口径指标 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 付费广告投放明细，提供广告收入原始数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，将本地币广告收入换算为 USD |
| `mp_paidads.dim_entry_point_mapping_v2` | 广告入口点与流量类型映射，用于识别广告来源场景 |

---

## ETL 逻辑摘要

### 数据流

```
实验分组维表 + 用户分组分配表
        │
        ▼
   用户-实验分组映射（含混合组 -99999）
        │
        ├──────────────────────────────────┐
        │                                  │
        ▼                                  ▼
  流量行为数据（曝光/点击/订单）      付费广告明细数据
  dwm_tc_ab_all_cards                dwd_advertise_performance_di
  dws_tc_pb_basic_aggr_1d                │
        │                          关联汇率表 + 入口映射
        ▼                                  │
  场景过滤与归因（mapping_general）         ▼
        │                          广告收入聚合（场景×用户×商品创建分桶）
        ▼                                  │
  关联商品维表，计算 create_date_type       │
        │                                  │
        ▼                                  │
  关联用户-实验分组                         │
        │                                  │
        ▼                                  │
  场景指标聚合（含 995 口径计算）            │
        │                                  │
        └──────────────┬───────────────────┘
                       │ LEFT JOIN on mapping_general + exp_group_id + create_date_type
                       ▼
             INSERT OVERWRITE 目标表
             （按 grass_region + local_date 分区写入）
```

### 关键步骤

1. **`tc_exp_rule`**：从 `dim_sr_data_warehouse_tc_exp_rule` 加载当日实验规则（`exp_group_type` 等），作为实验流量信息基础。

2. **`exp_traffic_info`**：关联 ABTest 实验管理表，筛选 NewItem 相关实验层（layer_id in 6 个值）和实验（experiment_id in 6 个值），构建实验分组元信息（`exp_group_id`、`exp_group_type`、`layer_id`、`experiment_id`）。

3. **`user_exp_raw` / `user_exp`**：从用户分组分配维表中拉取当日有效分配记录，与 `exp_traffic_info` JOIN 得到每个用户所属的实验分组；同时通过 UNION ALL 构造 `exp_group_id = -99999` 的混合实验组记录（group2~group8 用户合并统计）。

4. **`traffic_data_raw`**：从 `dwm_sr_data_warehouse_tc_ab_all_cards` 拉取当日曝光/点击/订单数据，按多维度预聚合，保留 is_ads、source_is_ads、feature_group 等归因字段。

5. **`every_scene_data_raw_step1`（CACHE）**：对流量数据进行场景过滤，仅保留 Post Purchase OSP/MPP、Shop 系列场景的流量，并生成 `mapping_general`、`source1/2_mapping_general` 归因标签（缓存至磁盘以供后续多次引用）。

6. **`every_scene_data_raw_step2`**：将主归因、source1 归因、source2 归因分别展开为三路 UNION ALL，实现订单的多场景归因拷贝（防止重复）。

7. **`traffic_data_item`**：合并来自 `dws_tc_pb_basic_aggr_1d`（主场景）和 `every_scene_data_raw_step2`（Shop 类子场景）的流量数据，按 `user_id`、`item_id`、`is_ads`、`mapping_general` 聚合。

8. **`basic_scene_data`**：将流量数据关联商品维表计算 `create_date_type` 分桶，再 JOIN 用户实验分组，得到带实验标签和商品创建分桶的基础事实数据。

9. **`scene_995_threshold`**：加载当日场景 995 分位 GPO 阈值。

10. **`scene_data`**：核心聚合步骤，分两路 UNION ALL 再汇总：
    - **第一路**：基于用户维度，使用 `GROUPING SETS` 对 `is_ads`、`create_date_type` 做多维汇总，计算 PV 类指标、UV 类指标、GMV 类指标，并关联 995 阈值过滤计算 995 口径指标；
    - **第二路**：基于商品维度（`item_id`），使用 `GROUPING SETS` 计算 `exposed_item_cnt`、`clicked_item_cnt`、`ordered_item_cnt`；
    - 两路结果按 `mapping_general`、`is_ads`、`exp_group_id`、`create_date_type` 合并聚合。

11. **`ads_raw_step1~4` / `ads` / `exp_ads`**：广告收入支路，从付费广告投放明细出发，关联汇率和入口映射，聚合至用户-场景-创建分桶粒度，再 JOIN 用户实验分组，最终按实验组和场景汇总广告收入（全量 + ROI2 口径）。`create_date_type` 同样按商品创建时间分桶。

12. **`INSERT OVERWRITE`**：将 `scene_data` 与 `exp_traffic_info`（补充 `layer_id`、`experiment_id`）、`exp_ads`（补充广告收入，仅 `is_ads = '__ALL__'` 行 JOIN）做 LEFT JOIN，按 `grass_region`、`local_date` 分区覆盖写入目标表。

### 注意事项

- **单文件单分区写入**：本表为单一 ETL 文件写入，`multi_writer = false`，无多路写入风险，但每次执行以 `INSERT OVERWRITE` 方式覆盖当日当区分区，重跑安全。
- **参数化执行**：SQL 中大量使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}`、`${schema}` 等 Spark 变量，实际运行时由调度系统注入，脚本本身不可单独执行。
- **广告收入与 `is_ads` 维度错位**：`scene_ads_revenue_usd` 仅在 `is_ads = '__ALL__'` 行 JOIN 写入，其余 `is_ads` 值的行该字段为 NULL，查询时需特别注意。
- **混合实验组行额外存在**：`exp_group_id = -99999` 的行为 ETL 额外构造，与真实分组行并存于同一分区，分析时需明确是否纳入。
- **CACHE 表**：`every_scene_data_raw_step1` 使用 `DISK_ONLY` 缓存，说明该中间结果数据量较大，后续多步引用均基于磁盘缓存，调度资源需保障磁盘空间充足。

---

*文档生成时间：2026-05-17*