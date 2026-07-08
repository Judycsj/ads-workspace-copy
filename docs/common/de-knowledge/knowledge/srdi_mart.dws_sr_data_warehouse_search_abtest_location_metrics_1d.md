<!-- ads-workspace-gdoc-sync: gdoc_id=1vj3pJRRlTKzroX-NaJ0Up2nDbxcpzA2re0PQxwZP12M gdoc_url=https://docs.google.com/document/d/1vj3pJRRlTKzroX-NaJ0Up2nDbxcpzA2re0PQxwZP12M/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_location_metrics_1d

**分层：** dws_search  
**主键：** exp_group_id + card_type + is_ads + location + with_item + search_entrance + grass_region + local_date  
**分区：** grass_region, local_date  
**更新频率：** 每日一次（T+1）  
**引用频次/访问频次：** 745  

---

## 业务描述

本表是搜索 A/B 实验位置维度的日粒度宽表，用于支撑搜索推荐 A/B 实验（ABTest）效果的多维度分析与指标归因。表中按实验组（experiment / layer / group）、卡片类型（card_type）、是否广告（is_ads）、展示位置（location）、搜索入口（search_entrance）、是否含商品（with_item）等维度聚合当日的曝光、点击、加购、成单、GMV、广告收入、Session 数等核心指标。

**核心业务场景：**
- 搜索 A/B 实验日报：按实验组对比各组的曝光/点击/GMV 等差异；
- 搜索广告 ROI 分析：分析广告位加载率（ads_load）、广告 GMV（宽口径/窄口径）、广告收入等；
- 搜索位置效果分析：按 location 区间（0~3、0~9、0~19、全量）评估不同位置的转化效果；
- AI 搜索卡片（minifeed/topic card）实验效果追踪；
- 搜索 Session 广告纯广告 Session 占比分析（all_ads_session_cnt / search_session_cnt）。

**适合回答的问题举例：**
- 某实验组在搜索页面 Top3 位置的点击率与对照组相比如何？
- 搜索广告的 ads_load（广告加载率）在各实验组中的差异？
- AI minifeed 卡片实验组的平均最大内部位置是多少？
- 某实验组昨日的搜索 Session 中全广告 Session 占比为多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 MY、TH、ID 等，所有查询必须指定此分区字段 |
| `local_date` | date | 业务日期（本地时区），所有查询必须指定此分区字段 |

---

### 维度：实验体系维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来自 dim_sr_data_warehouse_abtest_group |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验分组 ID，主要关联维度 |
| `exp_group_name` | string | 实验分组名称 |

---

### 维度：流量切分维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 卡片类型，取值包括 `item`、`video`、`livestream`、`ai_minifeed_card`、`ai_topic_card`、`ai_minifeed_inner_item`、`ai_minifeed_inner_video`、`ai_topic_inner_item`、`item+video+live`（汇总值）等 |
| `is_ads` | string | 是否广告流量，取值 `true`（广告）、`false`（非广告）、`__ALL__`（汇总） |
| `location` | string | 搜索结果页展示位置编号（整数字符串，≤99 为有效位置，否则为 `NA`）；汇总值包括 `0~3`、`0~9`、`0~19`、`__ALL__` |
| `with_item` | string | 该条记录是否关联具体商品 item_id，取值 `true`、`false`、`__ALL__`（汇总） |
| `search_entrance` | string | 搜索入口，如 `live_search`、`video_search`、`content_mix_search`、`all_content_search`（内容搜索汇总）、`not_content_search`、`__ALL__`（全量汇总）等；原始值为空时填充 `NA` |

---

### 指标：实验组用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_uu` | bigint | 实验分组的用户去重数（UV），按 exp_group_id 统计当日进入该实验组的唯一用户数 |

---

### 指标：搜索行为指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（PV） |
| `imp_uu` | bigint | 曝光用户数（UV），至少有一次曝光的用户数 |
| `click_cnt` | bigint | 点击次数（PV） |
| `click_uu` | bigint | 点击用户数（UV） |
| `ppv_cnt` | bigint | 商品详情页（PDP）访问次数；AI 搜索卡片（ai_minifeed/ai_topic 系列）该字段为 NULL |
| `ppv_uu` | bigint | 商品详情页访问用户数；AI 搜索卡片该字段为 NULL |
| `cart_cnt` | bigint | 加购次数；AI 搜索卡片该字段为 NULL |
| `cart_uu` | bigint | 加购用户数；AI 搜索卡片该字段为 NULL |
| `order_cnt` | double | 成单次数 |
| `order_uu` | double | 成单用户数 |
| `gmv` | double | 成单 GMV（本地货币） |
| `pc2_gmv` | double | PC2 口径 GMV（本地货币） |

---

### 指标：广告效果指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_impression_cnt` | bigint | 广告曝光次数，来自广告绩效数据源 |
| `ads_click_cnt` | bigint | 广告点击次数 |
| `ads_broad_order` | double | 广告宽口径成单数（broad attribution） |
| `ads_broad_gmv_local` | double | 广告宽口径 GMV（本地货币） |
| `ads_broad_gmv_usd` | double | 广告宽口径 GMV（美元） |
| `ads_order` | double | 广告窄口径成单数（narrow attribution） |
| `ads_gmv_local` | double | 广告窄口径 GMV（本地货币） |
| `ads_gmv_usd` | double | 广告窄口径 GMV（美元） |
| `ads_revenue_local` | double | 广告收入/消耗（本地货币，expenditure） |
| `ads_revenue_usd` | double | 广告收入/消耗（美元） |
| `ads_load` | double | 广告加载率，= 广告曝光数 / 全搜索场景总曝光数（含更多 page_type），**不可直接 SUM** |

---

### 指标：广告商品归因指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_item_order` | double | 广告商品列表中的商品在搜索行为下的成单数（基于广告主投放商品与搜索行为交叉归因） |
| `ads_item_gmv_usd` | double | 广告商品在搜索中产生的 GMV（美元），由 `ads_item_gmv` 换算，字段在 DataMap 中以 `ads_item_gmv_usd` 命名 |
| `ads_item_pc2_gmv_usd` | double | 广告商品在搜索中产生的 PC2 GMV（美元），字段在 DataMap 中以 `ads_item_pc2_gmv_usd` 命名 |

---

### 指标：Session 级别指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `all_ads_session_cnt` | bigint | 纯广告 Session 数，即该 Session 内全部曝光均为广告的 Session 数量；仅当 `card_type = 'item+video+live'`、`is_ads = '__ALL__'`、`with_item = '__ALL__'` 时有意义 |
| `search_session_cnt` | bigint | 搜索 Session 总数；仅当 `card_type = 'item+video+live'`、`is_ads = '__ALL__'`、`with_item = '__ALL__'` 时有意义 |

---

### 指标：AI Minifeed 卡片位置分布指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `max_imp_inner_location_avg` | double | 用户在 video 页面 AI minifeed 卡片中最大内部曝光位置的均值；仅当 `card_type = 'ai_minifeed_card'`、`is_ads = '__ALL__'`、`location = '__ALL__'`、`search_entrance = '__ALL__'`、`with_item = '__ALL__'` 时有意义，**不可直接 SUM** |
| `max_imp_inner_location_p50` | double | 上述最大内部曝光位置的 P50 分位数，**不可直接 SUM** |
| `max_imp_inner_location_p90` | double | 上述最大内部曝光位置的 P90 分位数，**不可直接 SUM** |
| `max_imp_location_avg` | double | 搜索结果页最大曝光位置均值（ETL SQL 中未见计算逻辑，字段存在于 DataMap，保留备用） |
| `max_imp_location_p50` | double | 搜索结果页最大曝光位置 P50（同上） |
| `max_imp_location_p90` | double | 搜索结果页最大曝光位置 P90（同上） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，为分区字段，不指定将导致全表扫描；
- **`local_date`**：必须指定，为分区字段，建议精确到具体日期或有界范围；
- 分析特定指标时，建议同时过滤 `card_type`、`is_ads`、`location`、`with_item`、`search_entrance`，以避免维度汇总值（`__ALL__`）与明细值重复计算。

### 不可直接 SUM 的字段

以下字段为比率、均值或分位数，不能跨行直接相加：

| 字段 | 原因 |
|---|---|
| `ads_load` | 比率指标（广告曝光 / 全场景总曝光），跨组 SUM 无意义，需重新用分子分母计算 |
| `max_imp_inner_location_avg` | 均值，需用原始用户级数据重新计算 |
| `max_imp_inner_location_p50` | 分位数，不可加和 |
| `max_imp_inner_location_p90` | 分位数，不可加和 |
| `max_imp_location_avg` | 均值，不可加和 |
| `max_imp_location_p50` | 分位数，不可加和 |
| `max_imp_location_p90` | 分位数，不可加和 |
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`exp_group_uu` | 去重用户数，跨维度 SUM 存在重复计数风险 |

### 维度汇总值说明

- `location`、`card_type`、`is_ads`、`with_item`、`search_entrance` 均包含汇总值（`__ALL__`）和明细值，查询时应明确选择；
- `location` 还包含预聚合区间值 `0~3`、`0~9`、`0~19`，与精确位置值及 `__ALL__` 不可混合 SUM；
- `all_ads_session_cnt` 和 `search_session_cnt` 仅在 `card_type = 'item+video+live' AND is_ads = '__ALL__' AND with_item = '__ALL__'` 的行中有值，其他组合下为 NULL；
- `max_imp_inner_location_*` 系列指标仅在 `card_type = 'ai_minifeed_card' AND is_ads = '__ALL__' AND location = '__ALL__' AND search_entrance = '__ALL__' AND with_item = '__ALL__'` 的行中有值。

### 时效性说明

- 本表为 `_1d` 后缀日粒度表，每日 T+1 全量刷新对应分区，无历史修正机制；
- 不包含实时或准实时数据，不适用于当日数据查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验体系维度信息（scene/layer/experiment/group 层级） |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户-实验分组映射关系（assignment log） |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 搜索行为基础指标（曝光、点击、加购、成单、GMV），覆盖标准搜索页面 |
| `srdi_mart.dws_sr_data_warehouse_ai_search_wide_metrics_1d` | AI 搜索卡片（minifeed/topic card）行为指标 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜索 Session 级别明细数据，用于计算 session_cnt 指标 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效明细数据（曝光、点击、成单、收入） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于本地货币转换为美元 |

---

## ETL 逻辑摘要

### 数据流

```
搜索行为数据（benchmark + AI wide metrics）
    ↓ UNION ALL
dws_global_search（统一搜索行为宽表）
    ↓ CACHE + 多维度 LATERAL VIEW EXPLODE
explode_user_group_metrics_grouped（用户-维度级聚合）
    ↓ exp_sum() 自定义 UDAF + JOIN 实验分组映射
dws_search_exp_metric（实验组-维度级搜索指标）
    ↓
                          ↘
广告绩效数据（dwd_advertise_performance_di）           广告商品归因
    ↓ JOIN 用户实验映射                                   ↓
dwd_ads_performance_raw                          dwd_ads_order_metrics
    ↓ FULL JOIN + 多维度 LATERAL VIEW EXPLODE
dws_ads_metrics_grouped（实验组-维度级广告指标 + ads_load）
                          ↘
搜索 Session 数据（dwd_sr_data_warehouse_platform）
    ↓ Session 维度聚合 + JOIN 实验分组映射
dws_search_session_count（all_ads_session_cnt / search_session_cnt）
                          ↘
AI minifeed inner location 分位数指标
（ai_minifeed_card_max_location_percentile）
                          ↘
最终 INSERT OVERWRITE → dws_sr_data_warehouse_search_abtest_location_metrics_1d
```

### 关键步骤

1. **`dim_exp`**：从实验维度表过滤搜索白名单实验，获取实验体系层级信息；

2. **`user_exp_mapping`**：从用户-实验分组表过滤有效分配日志（`is_assignment_log=1`）及搜索白名单，构建 user_id → exp_group_id 映射；

3. **`user_exp_list`**：将同一用户的所有 exp_group_id collect 为数组，供 `exp_sum()` UDAF 使用；

4. **`dws_global_search`**：UNION ALL 合并标准搜索页面（item/video/livestream）与 AI 搜索卡片的行为数据，统一 location、card_type、search_entrance 等维度编码，并构建多维度分组数组（含汇总值 `__ALL__` 及位置区间）；

5. **`dwm_search_metric_flatten`（CACHE TABLE）**：对 dws_global_search 按用户+多维度分组聚合，将各维度数组字段保留供后续 EXPLODE；

6. **`explode_user_group_metrics_grouped`**：通过 LATERAL VIEW EXPLODE 展开多维度数组，再按 user+展开后的维度聚合，计算用户级 UV 标志（`imp_uu`、`click_uu` 等）；

7. **`dwm_search_exp_metric`**：使用自定义 UDAF `exp_sum()` 将用户级指标按其所属的所有实验分组（exp_group_ids 数组）分发并聚合，实现一个用户同时归属多个实验组的指标分摊；

8. **`dws_search_exp_metric`**：EXPLODE exp_metrics 数组，按字段顺序 CAST 还原各实验组-维度的指标字段；

9. **Session 指标链路**：从 dwd 明细表按 session 粒度聚合广告曝光与总曝光，JOIN 实验分组映射，计算 `all_ads_session_cnt`（纯广告 Session）和 `search_session_cnt`（总 Session）；

10. **广告指标链路**：从广告绩效源表聚合广告曝光/点击/GMV/收入；与广告商品归因指标（基于广告主投放商品与搜索行为交叉）及广告加载率分母（更宽 page_type 范围）进行 FULL JOIN 后多维度 EXPLODE，最终计算 `ads_load`；

11. **AI minifeed 位置分位数**：从 AI 搜索宽表取 video page 的 inner_location，计算用户级最大内部位置，再 JOIN 实验分组计算均值、P50、P90；

12. **`INSERT OVERWRITE`**：以 dws_search_exp_metric 为主表，LEFT JOIN 广告指标、实验组 UU、实验维度、Session 指标、AI minifeed 位置分位数，写入目标表分区。

### 注意事项

- **单文件写入**：本表仅有 1 个 ETL 文件（`multi_writer=false`），无多写入方并发冲突风险；
- **分区覆盖写入**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 静态分区写入，重跑安全；
- **维度爆炸（Dimension Explosion）**：ETL 中对 location、card_type、search_entrance、is_ads、with_item 均通过 LATERAL VIEW EXPLODE 展开汇总值，导致表行数为明细维度与汇总维度的笛卡尔积，查询时需严格过滤维度，否则极易重复计算；
- **`exp_sum()` UDAF**：非标准 Spark SQL 函数，为自定义 UDAF，用于将单用户指标分发至其参与的所有实验组，需确认 UDF 已注册；
- **广告指标 JOIN 条件**：广告指标仅在 `is_ads IN ('__ALL__', 'true')` 时关联，`is_ads = 'false'` 的行广告指标字段均为 NULL；
- **Session 指标 JOIN 条件**：`all_ads_session_cnt` 和 `search_session_cnt` 仅在 `card_type = 'item+video+live' AND is_ads = '__ALL__' AND with_item = '__ALL__'` 时关联有值，其余行为 NULL；
- **AI minifeed 位置分位数 JOIN 条件**：`max_imp_inner_location_*` 仅在 `card_type = 'ai_minifeed_card' AND is_ads = '__ALL__' AND location = '__ALL__' AND search_entrance = '__ALL__' AND with_item = '__ALL__'` 时关联有值；
- **ppv_cnt / cart_cnt 为 NULL**：AI 搜索宽表来源的 ai_minifeed 系列卡片行中，`ppv_cnt` 和 `cart_cnt` 在 ETL 中显式赋值为 NULL，查询时注意 SUM 前使用 COALESCE 处理。

---

*文档生成时间：2026-05-17*