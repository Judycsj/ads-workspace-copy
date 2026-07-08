<!-- ads-workspace-gdoc-sync: gdoc_id=1lbGsz9FkA8naVTqh5V28LXC0ykrWPRkd5bKAOb9GHeQ gdoc_url=https://docs.google.com/document/d/1lbGsz9FkA8naVTqh5V28LXC0ykrWPRkd5bKAOb9GHeQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_mid_metrics_v2_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** `experiment_id`, `exp_group_id`, `sort_type`, `is_ads`, `search_entrance`, `search_mid`, `with_keyword`, `card_type`, `grass_region`, `local_date`
**分区：** `grass_region`（站点区域），`local_date`（业务日期）
**更新频率：** 每日（T+1 全量覆盖写入，`INSERT OVERWRITE PARTITION`）
**引用频次/访问频次：** 976

---

## 业务描述

本表是搜索 A/B 实验（ABTest）的**按入口 × 搜索通道（search_mid）多维度汇总**指标宽表，面向搜索算法与产品的实验效果评估。

核心业务场景：

- **实验分组效果对比**：按 `experiment_id` + `exp_group_id` 对比不同实验组的用户规模、转化漏斗、GMV 等核心指标。
- **多维下钻分析**：支持按搜索入口（`search_entrance`）、搜索通道（`search_mid`，含图搜/文搜/多模态等）、广告/自然位（`is_ads`）、排序方式（`sort_type`）、卡片类型（`card_type`）、是否带关键词（`with_keyword`）等维度拆分查看实验效果。
- **搜索质量指标**：覆盖搜索量、搜索成功率、无结果率、多模态搜索量等搜索质量相关指标。
- **GMV 去极值分析**：提供 99.5% 分位截断的 GMV 指标（高 GMV 类目 / 低 GMV 类目分开计算），用于压制长尾高价商品对实验评估的影响。
- **广告负载分析**：提供广告收入、广告曝光占比（Top20 位置）等广告相关指标。
- **用户留存分析**：提供 1 日留存、7 日留存相关 UU 指标，结合月活 DAU 评估实验对留存的影响。

适合回答的典型问题：

- 实验组 X 与对照组相比，搜索 CTR / GMV / 转化率是否有显著提升？
- 图搜入口的实验效果与文搜入口的实验效果有何差异？
- 广告位实验对广告负载和广告收入的影响？
- 某实验对用户次日/7 日留存率的影响？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域（如 SG、MY、TH 等），分区键，查询必须指定 |
| `local_date` | date | 业务本地日期，分区键，查询必须指定 |

### 维度：实验分组维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | 实验 ID，来源于 `dim_sr_data_warehouse_abtest_group`，标识该实验组所属的实验 |
| `exp_group_id` | bigint | 实验分组 ID，标识具体的实验组（如对照组、实验组 A/B），为主要关联键 |

### 维度：搜索行为维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口，如首页搜索、PDP 内搜索等；`__ALL__` 表示全量汇总 |
| `search_mid` | string | 搜索通道/模态，如 `text_search_all`（文本搜索汇总）、`multimodal_search_all`（多模态搜索汇总）、`image*`（图搜）等；`__ALL__` 表示全量 |
| `sort_type` | string | 排序方式，如 `relevancy`（相关性排序）；`__ALL__` 表示全量汇总 |
| `is_ads` | string | 是否广告位，`'true'` / `'false'` / `'__ALL__'`（全量） |
| `with_keyword` | string | 是否携带搜索关键词，`'true'` / `'false'` / `'__ALL__'` |
| `card_type` | string | 结果卡片类型，如 `item`（商品）、`video`（视频）、`livestream`（直播）、`item+video+live`（组合）、`__ALL__` |

### 指标：用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_uu` | bigint | 实验组去重用户数（UU），来源于 `dws_sr_data_warehouse_search_abtest_core_metrics_v2_1d`，代表该实验组总人数。**不可直接 SUM**（已为 UU 聚合值） |
| `search_dau` | bigint | 当日有搜索行为的去重用户数（搜索 DAU）。**不可直接 SUM** |
| `month_dau` | bigint | 近 30 日有搜索行为的累计去重用户数（月 DAU）。**不可直接 SUM** |

### 指标：曝光与点击漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果页商品曝光总次数（可加和） |
| `imp_uu` | bigint | 有曝光行为的去重用户数。**不可直接 SUM** |
| `click_cnt` | bigint | 搜索结果页点击总次数（可加和） |
| `click_uu` | bigint | 有点击行为的去重用户数。**不可直接 SUM** |
| `ctr` | double | 曝光点击率（次数维度）：`click_cnt / imp_cnt`。**预计算比率，不可直接 SUM** |
| `ctr_uu` | double | 曝光点击率（用户维度）：`click_uu / imp_uu`。**预计算比率，不可直接 SUM** |
| `ppv_cnt` | bigint | PDP（商品详情页）访问总次数（可加和） |
| `ppv_uu` | bigint | 有 PDP 访问行为的去重用户数。**不可直接 SUM** |
| `cart_cnt` | bigint | 加购总次数（可加和） |
| `cart_uu` | bigint | 有加购行为的去重用户数。**不可直接 SUM** |
| `buyer` | bigint | 有下单行为的去重用户数（购买 UU）。**不可直接 SUM** |

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 订单数（可加和） |
| `squared_user_order_sum` | double | 用户订单数的平方和（`SUM(order_cnt)^2`），用于统计方差检验（CUPED 等方法）。**不可直接 SUM 用于业务分析** |
| `gmv` | double | 搜索归因 GMV（可加和） |
| `pc2_gmv` | double | 搜索归因 PC2 GMV（可加和） |

### 指标：GMV 去极值（99.5% 分位截断）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_995` | double | 按用户 ABS（平均篮子价值）99.5% 分位截断后的 GMV，用于压制极端值影响（可加和） |
| `gmv_uu_995` | double | 按 ABS 99.5% 分位截断后有 GMV 的用户数。**不可直接 SUM**（`gmv_995 / imp_uu_995`，已预计算） |
| `pc2_gmv_995` | double | 按用户 ABS 99.5% 分位截断后的 PC2 GMV（可加和） |
| `pc2_gmv_uu_995` | double | 按 ABS 99.5% 分位截断后有 PC2 GMV 的用户数。**不可直接 SUM**（预计算比率） |
| `dpm_gmv_995` | double | DPM 口径 99.5% 分位截断 GMV（可加和） |
| `dpm_gmv_uu_995` | double | DPM 口径 99.5% 分位截断 GMV UU。**不可直接 SUM** |
| `dpm_pc2_gmv_995` | double | DPM 口径 99.5% 分位截断 PC2 GMV（可加和） |
| `dpm_pc2_gmv_uu_995` | double | DPM 口径 99.5% 分位截断 PC2 GMV UU。**不可直接 SUM** |

### 指标：分类别 GMV 去极值 v2（按高/低 GMV 类目分别截断）

| 字段 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高 GMV 类目商品按类目级 99.5% 分位截断后的 GMV 汇总（可加和） |
| `high_gmv_order_cnt_995_v2` | double | 高 GMV 类目截断范围内的订单数（可加和） |
| `high_pc2_gmv_995_v2` | double | 高 GMV 类目截断后的 PC2 GMV（可加和） |
| `low_gmv_995_v2` | double | 低 GMV 类目商品按类目级 99.5% 分位截断后的 GMV 汇总（可加和） |
| `low_gmv_order_cnt_995_v2` | double | 低 GMV 类目截断范围内的订单数（可加和） |
| `low_pc2_gmv_995_v2` | double | 低 GMV 类目截断后的 PC2 GMV（可加和） |

### 指标：搜索页 PV 与搜索量

| 字段 | 类型 | 说明 |
|---|---|---|
| `srp_pv_cnt` | bigint | 搜索结果页（SRP）PV 总数（`view_cnt`，可加和） |
| `srp_pv_not_back_cnt` | bigint | 搜索结果页 PV 中未返回上一页的次数（`view_no_back_cnt`，可加和），反映用户对搜索结果的满意度 |
| `search_volume` | bigint | 搜索词次数（按 `device_id + keyword` 去重计数，可加和） |
| `search_success_result_volume` | bigint | 有结果且用户有后续行为（PPV）的搜索词次数，衡量搜索成功率（可加和） |
| `search_non_result_volume` | bigint | 无召回结果的搜索词次数，衡量搜索空结果率（可加和） |
| `direct_search_success_volume` | bigint | 有直接点击（商品/视频/直播）行为的搜索词次数（可加和） |
| `broad_search_success_volume` | bigint | 有广义成功点击（含店铺、创作者等）行为的搜索词次数（可加和） |

### 指标：多模态搜索量（图搜）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ms_search_volume` | bigint | 多模态（图搜）搜索量，按 `device_id + keyword + md5`（图片哈希）去重（可加和） |
| `ms_direct_search_success_volume` | bigint | 多模态搜索中有直接点击的搜索量（可加和） |
| `ms_broad_search_success_volume` | bigint | 多模态搜索中有广义成功点击的搜索量（可加和） |
| `ms_search_volume_v2` | bigint | 多模态搜索量 v2，额外加入框选区域（`box_xy`）去重，粒度更细（可加和） |
| `ms_direct_search_success_volume_v2` | bigint | 多模态搜索中有直接点击的搜索量 v2（可加和） |
| `ms_broad_search_success_volume_v2` | bigint | 多模态搜索中有广义成功点击的搜索量 v2（可加和） |

### 指标：广告相关

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue` | double | 广告收入（美元，`expenditure_amt_usd` 汇总，可加和） |
| `ads_load` | double | 广告负载率：`广告曝光次数 / 全部商品曝光次数`（含多种 page_type）。**预计算比率，不可直接 SUM** |
| `top20_ads_load` | double | Top20 位置广告负载率：前 20 个位置广告曝光占前 20 位置总曝光的比率。**预计算比率，不可直接 SUM** |

### 指标：位置体验

| 字段 | 类型 | 说明 |
|---|---|---|
| `max_imp_location_avg` | double | 用户在搜索 Session 中最大曝光位置的加权均值，衡量用户浏览深度。**预计算均值，不可直接 SUM** |
| `max_imp_location_p50` | double | 用户最大曝光位置的 P50 分位数（中位数）。**预计算分位数，不可直接 SUM** |
| `first_click_location_avg` | double | 用户在 Session 内首次点击位置的加权均值，衡量用户点击偏好。**预计算均值，不可直接 SUM** |
| `first_click_location_p50` | double | 用户首次点击位置的 P50 分位数。**预计算分位数，不可直接 SUM** |

### 指标：用户留存

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu_1d` | bigint | 前 1 日（T-1）有搜索行为的去重用户数，用于计算次日留存分母。**不可直接 SUM** |
| `retention_uu_1d` | bigint | 前 1 日有搜索 + 当日（T）也有搜索的去重用户数，即次日留存 UU。**不可直接 SUM** |
| `search_uu_7d` | bigint | 前 7 日（T-7）有搜索行为的去重用户数，用于计算 7 日留存分母。**不可直接 SUM** |
| `retention_uu_7d` | bigint | 前 7 日有搜索 + 当日（T）也有搜索的去重用户数，即 7 日留存 UU。**不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，查询时必须显式指定，否则触发全表扫描，产生大量资源消耗。示例：`WHERE grass_region = 'SG'`。
- **`local_date`**：分区字段，必须指定，通常为目标分析日期。示例：`AND local_date = '2024-01-01'`。
- 查询特定实验时，建议同时过滤 `experiment_id` 或 `exp_group_id` 以缩小范围。

### 不可直接 SUM 的字段

以下字段为预聚合派生指标、比率、均值或分位数，**跨分组 SUM 无业务意义，会产生错误结果**：

| 字段 | 原因 |
|---|---|
| `ctr`、`ctr_uu` | 预计算比率（`click/imp`），应用分子/分母各自 SUM 后再除 |
| `ads_load`、`top20_ads_load` | 预计算比率，应用分子/分母各自 SUM 后再除 |
| `gmv_uu_995`、`pc2_gmv_uu_995`、`dpm_gmv_uu_995`、`dpm_pc2_gmv_uu_995` | 预计算比率（gmv_995 / imp_uu_995） |
| `max_imp_location_avg`、`first_click_location_avg` | 预计算加权均值，需用 session 级分子分母重新计算 |
| `max_imp_location_p50`、`first_click_location_p50` | 预计算分位数，不支持跨组合并 |
| `exp_group_uu`、`search_dau`、`month_dau` | 去重 UU，跨 `exp_group_id` 用户存在重叠 |
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`buyer` | 去重 UU，跨维度 SUM 无效 |
| `search_uu_1d`、`retention_uu_1d`、`search_uu_7d`、`retention_uu_7d` | 去重 UU |
| `squared_user_order_sum` | 统计检验中间量，非业务加和指标 |

### 维度枚举值约定

- `__ALL__` 是各维度的全量汇总行标识，分析特定子集时需排除或按需过滤。
- `sort_type` 仅对 `relevancy` 排序有独立值，其余均汇总至 `__ALL__`。
- `search_mid` 的聚合层级：具体 image 通道 → `multimodal_search_all` → `__ALL__`；文本搜索：具体通道 → `text_search_all` → `__ALL__`。

### 时效性说明

- 本表为 **T+1 天级表**，每日产出前一天数据，分区粒度为单日。
- 留存相关指标（`retention_uu_*`、`search_uu_*`）依赖近 30 日历史数据窗口计算，历史日期的留存数据不会因回跑而变化。
- 多模态指标（`ms_*`）仅当 `search_mid LIKE 'image%'` 时才有值，文本搜索组合下该字段为 NULL。
- 广告指标（`ads_load`、`ads_revenue`、`top20_ads_load`）仅在 `sort_type = '__ALL__'` 且 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时关联填充，其余组合为 NULL。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 实验用户分组映射（当日 1d 及近 30 日窗口），过滤正式分流日志和搜索白名单 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验组与实验 ID 的映射关系 |
| `srdi_mart.dws_sr_data_warehouse_search_abtest_core_metrics_v2_1d` | 获取实验组 UU 总人数（`exp_group_uu`） |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 用户级搜索行为宽表，提供曝光、点击、加购、下单、GMV 等核心指标及搜索量计算 |
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 用户级 SRP 基准表，提供搜索页 PV、广告负载分母、ABS（用于 gmv_995）及留存窗口数据 |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 订单级基准表，用于分类目 GMV 去极值 v2 计算 |
| `srdi_mart.dws_sr_data_warehouse_search_session_level_metircs_1d` | 搜索 Session 级数据，提供最大曝光位置和首次点击位置 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台 DWD 明细数据，提供多模态（图搜）搜索的 ai_search_info 字段（md5、box_xy） |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，提供 `category_tag`（高/低 GMV 类目标签），用于分类目 GMV 截断 |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 类目 GMV 极值阈值表，提供各类目 99.5% 分位截断阈值（`gmv_995pct`、`pc2_gmv_995pct`） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细表（付费广告域），提供广告收入（`expenditure_amt_usd`）及广告曝光次数 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group (1d + 30d)
    └─→ user_exp_mapping_1d / user_exp_mapping_30d / user_exp
            │
            ├─ dws_platform_user_item_keyword_benchmark_1d
            │       └─→ platform_benchmark_raw → platform_benchmark_user_agg
            │               + abs_995_benchmark (from search_srp_benchmark)
            │               └─→ uu_data → map_data
            │                       JOIN user_exp → explode_metric_table → search_exp_metrics  ← 主驱动表
            │
            ├─ dws_platform_user_item_keyword_benchmark_1d (search_volume 路径)
            │       └─→ srp_search → search_volume
            │               JOIN user_exp_mapping_1d → exp_search_volumn
            │
            ├─ dwd_sr_data_warehouse_platform (多模态路径)
            │       └─→ multimodal_metrics_raw → multimodal_metrics_user_grouped
            │               JOIN user_exp_mapping_1d → multimodal_exp_metrics
            │
            ├─ dws_search_srp_user_benchmark_1d + mp_paidads (广告路径)
            │       └─→ ads_load_denominator → ads_exp_denominator_metrics
            │           ads_metrics → ads_exp_metrics
            │
            ├─ dws_search_session_level_metircs_1d (位置路径)
            │       └─→ max_imp_location → max_imp_location_exp_metrics
            │           first_click_location → first_click_location_exp_metrics
            │
            ├─ dws_search_srp_user_benchmark_1d (留存路径, 30d窗口)
            │       JOIN user_exp_mapping_30d → retention_exp_user_level_metrics → retention_exp_metrics
            │
            └─ dws_platform_order_benchmark_1d + dim_item + dim_category_gmv_outlier (gmv995_v2路径)
                    └─→ gmv995_v2_raw → gmv995_v2_item_order_grouped → gmv995_v2_user_level_filtered
                            JOIN user_exp_mapping_1d → gmv995_v2_exp_metrics

所有路径结果 LEFT JOIN 至 search_exp_metrics →
INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_mid_metrics_v2_1d
PARTITION(grass_region, local_date)
```

### 关键步骤

**Step 1 — 实验用户映射准备**

- `user_exp_mapping_30d`：近 30 日（T-29 ～ T）实验分组数据，用于留存计算；实验 ID 硬编码为 `193244`。
- `user_exp_mapping_1d`：当日实验分组数据，用于大部分指标关联。
- `user_exp`：当日用户 → `collect_list(exp_group_id)` 映射，支持自定义聚合函数 `exp_sum` 的广播 JOIN。
- `dim_exp`：当日实验组 → 实验 ID 映射。

**Step 2 — 核心行为指标（主驱动路径）**

- 从 `dws_platform_user_item_keyword_benchmark_1d` 提取 `global_search / search_in_pdp / search_prefill` 页面类型数据，按用户 × 多维度组合 GROUPING SETS/CUBE 聚合，生成 `platform_benchmark_user_agg`。
- 计算 ABS（用户平均篮子价值）的 99.5% 分位阈值（`abs_995_benchmark`），用于 gmv_995 截断。
- 生成 `uu_data`（含各行为 UU 标识及 `gmv_995`、`pc2_gmv_995`）。
- 打包为 metrics 数组（`map_data`），使用自定义聚合函数 `exp_sum` 按实验组展开，生成 `search_exp_metrics`（主表，提供 imp/click/ppv/cart/order/gmv 等主要指标）。
- CTR 在最终 INSERT 时由 `click_uu / imp_uu`、`click_cnt / imp_cnt` 实时计算。

**Step 3 — 搜索量指标路径**

- 从 `dws_platform_user_item_keyword_benchmark_1d` 聚合 `search_volume`（`device_id + keyword` 去重），计算成功搜索量、无结果搜索量等。
- JOIN `user_exp_mapping_1d` 生成 `exp_search_volumn`（注：SQL 中此临时视图名有拼写错误 `volumn`）。

**Step 4 — 多模态（图搜）指标路径**

- 从 `dwd_sr_data_warehouse_platform` 提取 `ai_search_info` 中的 `md5`（图片哈希）和 `box_xy`（裁剪框），计算图搜量（v1：md5 去重；v2：md5 + box_xy 去重）。
- JOIN `user_exp_mapping_1d` 生成 `multimodal_exp_metrics`。

**Step 5 — 广告指标路径**

- 广告负载分母来自 `dws_search_srp_user_benchmark_1d`（更宽泛的 page_type 范围，含 `search_in_mall` 等）。
- 广告负载分子和广告收入来自 `mp_paidads.dwd_advertise_performance_di__reg_s0_live`（`entrance = 1` 过滤搜索入口广告）。
- 最终 INSERT 时计算：`ads_load = ads_load_numerator / ads_load_denominator`；`top20_ads_load = top20_ads_load_numerator / top20_ads_load_denominator`。

**Step 6 — 位置体验指标路径**

- 从 `dws_search_session_level_metircs_1d` 提取 Session 级最大曝光位置和首次点击位置。
- 通过窗口函数（累计计数）计算 P50 分位数；加权平均计算均值。
- 分别生成 `max_imp_location_exp_metrics` 和 `first_click_location_exp_metrics`。

**Step 7 — 用户留存指标路径**

- 从 `dws_search_srp_user_benchmark_1d` 取近 30 日搜索数据，JOIN `user_exp_mapping_30d`（含 `local_date` 条件防止用户跨日混用）。
- 标记用户是否在 T、T-1、T-7 日有搜索行为，计算 1 日和 7 日留存 UU。

**Step 8 — 分类目 GMV 去极值 v2 路径**

- 从 `dws_platform_order_benchmark_1d` 获取订单级 GMV 数据，JOIN `dim_sr_data_warehouse_item` 获取 `category_tag`（`high gmv` / `low gmv`）。
- JOIN `dim_sr_data_warehouse_category_gmv_outlier` 获取各类目 + is_ads 组合下的 99.5% 分位阈值，对 GMV 进行截断。
- JOIN `user_exp_mapping_1d` 汇总至实验组，分别输出高/低 GMV 类目的截断后 GMV 和订单数。

**Step 9 — 最终写入**

- `search_exp_metrics` 为主表，其余各路径结果通过 `exp_group_id` 及各维度字段 LEFT JOIN 拼接。
- 各路径 JOIN 条件中限制了维度组合（如广告、多模态等指标仅在 `sort_type = '__ALL__'`、`is_ads = '__ALL__'`、`card_type = '__ALL__'` 时填充），其他维度组合对应字段为 NULL。
- `INSERT OVERWRITE PARTITION(grass_region, local_date)` 全量覆盖写入。

### 注意事项

- **单一写入者**：本表由单个 ETL 文件写入，无 multi-writer 问题。
- **自定义函数依赖**：ETL 使用 `exp_sum` 自定义聚合函数（UDAF），负责将 metrics 数组按实验组 ID 列表分发并聚合，该函数需在执行环境中预注册。
- **实验 ID 硬编码**：`user_exp_mapping_30d` 中 `experiment_id = 193244` 为硬编码值，需关注实验配置变更对留存数据的影响。
- **JOIN 维度限制导致的 NULL 值**：广告、多模态、位置、留存等辅助指标在非 `__ALL__` 维度组合下不做 JOIN，对应字段输出为 NULL，下游使用时需注意过滤条件。
- **广告负载分母 page_type 范围比其他指标宽**：`ads_load_denominator` 包含 `search_in_mall`、`search_in_microsite` 等额外页面类型，而其他指标仅计算 `global_search / search_in_pdp / search_prefill`，导致不同指标的分母口径不一致。
- **gmv_uu_995 计算**：该字段在 `search_exp_metrics` 临时视图中由 `gmv_995 / imp_uu_995` 计算，`imp_uu_995` 仅用于除法（未单独落库），分析时需注意该字段的实际含义为"每有效曝光用户的截断 GMV"而非用户 UU 数。
- **分区写入**：每次运行按 `(grass_region, local_date)` 全量覆盖写入，重跑安全。

---

*文档生成时间：2026-05-17*