<!-- ads-workspace-gdoc-sync: gdoc_id=1OWz8We7LHwOzwmLqcbFiFmuF9ThjxQhrBh9qG4SgTG8 gdoc_url=https://docs.google.com/document/d/1OWz8We7LHwOzwmLqcbFiFmuF9ThjxQhrBh9qG4SgTG8/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_location_metrics_1d

**分层：** DWS（数据仓库服务层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `roi_item_type` + `location` + `feature_group` + `feature_detail`
**分区：** `grass_region`（大区）, `local_date`（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE，按 `grass_region` + `local_date` 分区）
**访问频次：** 584 次

---

## 业务描述

本表是搜推数仓（SRDI）搜推平台**实验 × 位置 × 特征**维度的日粒度聚合宽表，用于支持推荐/搜索 A/B 实验效果的多维度拆解分析。

**核心业务场景：**

- **A/B 实验效果评估**：按实验组（`exp_group_id`）统计曝光、点击、加购、下单等漏斗指标，以及 pCTR、pCR 等模型预测分数，评估算法实验收益。
- **位置效果分析**：按商品展示位置（`location`）分析各位置的流量质量与转化效率。
- **特征/场景归因**：结合 `feature_group`（如 Search、Cart Unify、You May Also Like 等）和 `feature_detail` 维度，定位具体推荐策略或场景的效果。
- **广告指标融合**：集成广告宽口径订单数、GMV、Revenue、ADS 订单等广告效果指标，支持搜广联合分析。
- **商品维度下钻**：通过 `item_cnt`、`price_v2` 等字段支持商品数量及均价的对比。

**适合回答的问题举例：**

- 实验组 X 相比对照组，搜索场景下的 CTR、转化率、GMV 变化如何？
- 位置 1~10 的点击率和成单率分布如何？`>120` 位置的流量质量如何？
- 某推荐场景（如 Cart Unify）在特定大区的广告宽口径 GMV 贡献？
- 各实验组的模型预测 pCTR 中位数（`pctr_50p`）是否与实际 CTR 一致？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 MY、TH、ID 等；写入时由 ETL 参数 `${grass_region}` 注入，每次作业覆写单一大区分区 |
| `local_date` | date | 业务日期（本地时区），与大区联合构成数据分区 |

### 维度：实验与特征分组

| 字段名 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验组 ID；仅保留推荐白名单实验组（`is_rcmd_whitelist = 1`） |
| `roi_item_type` | string | 商品 ROI 类型；ETL 中 `'null'` 字符串还原为 SQL NULL；`'__ALL__'` 表示所有类型汇总行 |
| `location` | string | 商品展示位置；原始整数型，ETL 映射规则：NULL→NULL，>120→`'>120'`，其余转字符串；`'__ALL__'` 行不适用 |
| `feature_group` | string | 特征场景分组，由 `scenario_tag` 映射而来，包含 `Search`、`You May Also Like`、`Cart Unify`、`My Purchase Page YMAL`、`Order Detail Page YMAL` 等 |
| `feature_detail` | string | 具体特征标识，来自 `dim_sr_data_warehouse_feature_scenario_tag_mapping`；`'__ALL__'` 表示跨特征汇总行 |

### 指标：曝光与行为漏斗

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（operation = 'impression' 的累计计数） |
| `click_cnt` | bigint | 点击次数（operation = 'click' 的累计计数） |
| `cart_cnt` | bigint | 加购次数（operation = 'cart' 的累计计数） |
| `order_cnt` | bigint | 下单次数（operation = 'order' 的累计计数） |
| `gmv` | double | 下单 GMV（USD），来自 `place_order_gmv` 的累加 |
| `gmv_local` | double | 下单 GMV（本地货币），来自 `place_order_gmv_local` 的累加 |
| `item_cnt` | bigint | 曝光/行为涉及的有效商品数（`item_id > 0` 的去重计数聚合，非精确去重） |
| `pclick_cnt` | bigint | 预测点击数（曝光次数 × pCTR 的累加，广告和非广告分别取不同字段）；不可直接跨组 SUM 后计算比率 |
| `porder_cnt_over_click` | bigint | 预测成单数（以点击为分母，click 次数 × pCR 的累加） |
| `porder_cnt_over_atc` | bigint | 预测成单数（以加购为分母，cart 次数 × pCR 的累加） |

### 指标：模型预测分数

| 字段名 | 类型 | 说明 |
|---|---|---|
| `pctr` | double | 预测点击率（pCTR）均值，由 `AVG(pctr)` 聚合得到；不可直接 SUM |
| `pcr` | double | 预测转化率（pCR）均值，由 `AVG(pcr)` 聚合得到；不可直接 SUM |
| `pctr_50p` | double | pCTR 的 50 分位数（中位数），由 `sketch_percentile(pctr)` 计算；不可直接 SUM 或 AVG |
| `pcr_50p` | double | pCR 的 50 分位数（中位数），由 `sketch_percentile(pcr)` 计算；不可直接 SUM 或 AVG |
| `avg_imp_price` | double | 曝光商品的平均价格（`AVG(price)`，price 来自曝光行的 impression 价格）；不可直接 SUM |

### 指标：商品价格

| 字段名 | 类型 | 说明 |
|---|---|---|
| `price_v2` | double | 商品标准化价格（USD），来源于 `item_price` 实时表（`price_usd/100000`），经 `AVG` 聚合；不可直接 SUM |

### 指标：广告效果

| 字段名 | 类型 | 说明 |
|---|---|---|
| `broad_order_cnt` | bigint | 宽口径广告订单数，来自 `dwm_sr_data_warehouse_ads_item_tag` |
| `broad_gmv_amt_local` | double | 宽口径广告 GMV（本地货币），来自 `dwm_sr_data_warehouse_ads_item_tag` |
| `revenue_usd` | double | 广告收入（USD），来自 `dwm_sr_data_warehouse_ads_item_tag` |
| `ads_order_gmv_usd` | double | 广告订单 GMV（USD），来自 `dwm_sr_data_warehouse_ads_item_tag` |
| `ads_order_cnt` | bigint | 广告订单数，来自 `dwm_sr_data_warehouse_ads_item_tag` |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则扫描全量分区，影响性能。示例：`WHERE grass_region = 'MY'`
- **`local_date`**：必须指定，否则扫描全部历史分区。示例：`AND local_date = '2025-01-01'`
- 两个分区字段缺一不可，建议同时过滤。

### 不可直接 SUM 的字段

以下字段为预聚合的均值、分位数或派生比率，**跨行直接 SUM 无统计意义**，需使用加权或其他方式重新聚合：

| 字段 | 原因 |
|---|---|
| `pctr` | `AVG(pctr)` 预聚合均值，跨维度不可 SUM |
| `pcr` | `AVG(pcr)` 预聚合均值，跨维度不可 SUM |
| `pctr_50p` | Sketch 分位数，不可 SUM / AVG |
| `pcr_50p` | Sketch 分位数，不可 SUM / AVG |
| `avg_imp_price` | `AVG(price)` 预聚合均值，不可 SUM |
| `price_v2` | `AVG(price_v2)` 预聚合均值，不可 SUM |

- **`pclick_cnt`、`porder_cnt_over_click`、`porder_cnt_over_atc`**：是预测值的累加，可以 SUM，但**不可直接用作比率分子/分母**与 `imp_cnt`、`click_cnt` 等真实计数混用比较。

### 汇总行说明

- `feature_detail = '__ALL__'` 表示跨特征汇总行，包含 `roi_item_type = '__ALL__'` 的全类型汇总。
- `roi_item_type = '__ALL__'` 表示全商品类型汇总行。
- 过滤明细时需排除 `feature_detail = '__ALL__'` 或 `roi_item_type = '__ALL__'`，否则会产生重复计算。

### 时效性说明

- 本表为 **T+1 日粒度**表（`_1d` 后缀），每日产出前一天数据，无实时/准实时数据。
- 数据仅覆盖已加入推荐白名单（`is_rcmd_whitelist = 1`）的实验组。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform_fe_join_be` | 主事件流水表，提供曝光、点击、加购、下单的前后端 join 明细，含模型分数、广告标识 |
| `srdi_mart.dwd_sr_data_warehouse_platform_fe_join_be_source` | 补充事件流水（加购、下单），用于弥补主表的来源数据缺失场景 |
| `srdi_mart.dim_sr_data_warehouse_feature_scenario_tag_mapping` | 特征维度映射表，提供 `feature_detail` 到场景标签（`scenario_tags`）的映射 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | A/B 实验组配置表，用于过滤推荐白名单实验组（`is_rcmd_whitelist = 1`） |
| `srdi_mart.dwm_sr_data_warehouse_ads_item_tag` | 广告商品聚合表，提供宽口径订单数、GMV、Revenue 等广告效果指标 |
| `mkplpaidads_data.item_price__reg_s0_live` | 商品实时价格表，提供商品 USD 标准化价格（`price_usd/100000`） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform_fe_join_be          ┐
dwd_sr_data_warehouse_platform_fe_join_be_source   ┘ → 行为漏斗指标聚合
dim_sr_data_warehouse_feature_scenario_tag_mapping → 场景 Tag 关联
dim_sr_data_warehouse_abtest_group                 → 实验组白名单过滤
dwm_sr_data_warehouse_ads_item_tag                 → 广告指标 Left Join
item_price__reg_s0_live                            → 商品价格 Left Join
                                                     ↓
                               FULL OUTER JOIN 合并行为指标 + 商品/广告指标
                                                     ↓
             INSERT OVERWRITE dws_sr_data_warehouse_platform_exp_location_metrics_1d
```

### 关键步骤

1. **`feature_scenario_tag_mapping`（Temp View）**：从特征场景维度表中过滤当日有效的 DA 场景标签，按 `feature_detail` 聚合场景 Tag 数组，用于后续 Broadcast Join。

2. **`exp_filter`（Temp View）**：从 A/B 实验配置表中提取当日推荐白名单实验组（`is_rcmd_whitelist = 1`），用于后续过滤。

3. **`dwd_fe_join_be`（Temp View）**：合并主事件表（impression/click/cart/order）与补充事件表（cart/order），完成行为指标汇总（`imp_cnt`、`click_cnt`、`cart_cnt`、`order_cnt`、`gmv`、`gmv_local`、`pclick_cnt`、`porder_cnt_over_click`、`porder_cnt_over_atc`）及 pCTR/pCR 提取；位置字段做 >120 截断处理。

4. **`dwd_fe_join_be_tag → exp → exp_filter → explode_exp → fgroup`（多层 Temp View）**：依次关联场景标签、展开实验组 ID 数组、按白名单过滤、展开场景 Tag 数组、将 scenario_tag 映射为可读 `feature_group` 名称。

5. **`dwd_fe_join_be_exp_all`（Temp View）**：构造 `feature_detail = '__ALL__'` 和 `roi_item_type = '__ALL__'` 两类汇总行，保留 `COLLECT_SET(scenario_tag)` 用于后续展开。

6. **`fe_join_be_avgsum_metrics`（Temp View）**：使用 `GROUPING SETS` 对 `roi_item_type` 维度做 Cube 聚合，同时 UNION `__ALL__` 汇总行；计算 `AVG(price)` 为 `avg_imp_price`，`AVG(pctr/pcr)` 及 `sketch_percentile` 分位数。

7. **商品+广告侧 Temp View 链路**（`dwd_fe_join_be_item_*` 系列）：与行为漏斗侧并行，以 `item_id` 为粒度关联价格表（Left Join）和广告指标表（Left Join），同样做场景 Tag 关联、实验组过滤、`feature_group` 映射，并使用 `GROUPING SETS` 构造 Cube 维度汇总，最终产出 `fe_join_be_item_ads_metrics`（含 `item_cnt`、`price_v2`、广告指标）。

8. **`fe_join_be_metrics`（Temp View）**：以维度键（`exp_group_id`、`roi_item_type`、`location`、`feature_group`、`feature_detail`）对行为漏斗指标视图与商品/广告指标视图做 **FULL OUTER JOIN**，合并全部指标。

9. **`INSERT OVERWRITE`（最终写入）**：从合并视图中读取全部字段，将 `'null'` 字符串还原为 SQL NULL，以 `REPARTITION(200)` 控制输出文件数，按 `grass_region` 和 `local_date` 分区覆写目标表。

### 注意事项

- **Single Writer**：本表仅有一个 ETL 文件写入，无多写风险；但 ETL 按大区（`grass_region`）参数化执行，多大区并行任务需确保分区参数不重叠，否则可能出现分区互相覆盖。
- **FULL OUTER JOIN 空值风险**：行为漏斗侧与商品/广告侧使用 FULL OUTER JOIN 合并，当某侧数据缺失时，对应指标字段为 NULL，查询时需注意 `COALESCE` 或 NULL 过滤。
- **`__ALL__` 汇总行去重**：表中同时存在明细行与 `feature_detail = '__ALL__'`、`roi_item_type = '__ALL__'` 的汇总行，直接 SUM 全表会导致重复统计，使用时必须显式过滤。
- **实验组白名单过滤**：ETL 通过 INNER JOIN `exp_filter` 仅保留推荐白名单实验组，非白名单实验数据不在本表中，查询时无需额外过滤。
- **价格数据来源变更**：ETL 中注释掉了原先从 `dws_fp_search_item_feature` 读取价格的逻辑，当前使用 `mkplpaidads_data.item_price__reg_s0_live`，若数据源切换需关注字段单位（当前除以 100000 换算）。
- **Sketch 分位数不可聚合**：`pctr_50p`、`pcr_50p` 由 `sketch_percentile` 函数计算，为近似值，不支持二次 SUM/AVG 聚合。

---

*文档生成时间：2026-05-17*