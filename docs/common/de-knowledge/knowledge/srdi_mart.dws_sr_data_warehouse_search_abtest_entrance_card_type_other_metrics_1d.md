<!-- ads-workspace-gdoc-sync: gdoc_id=1r4vCySNwfCIKUmIL9kbIXm8VQw6OTz1fgoQGIUNNOIg gdoc_url=https://docs.google.com/document/d/1r4vCySNwfCIKUmIL9kbIXm8VQw6OTz1fgoQGIUNNOIg/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_card_type_other_metrics_1d

**分层：** dws_search
**主键：** `grass_region` + `local_date` + `exp_group_id` + `card_type` + `is_ads` + `search_entrance`
**分区：** `grass_region`（地区）, `local_date`（业务日期）
**更新频率：** 每日 T+1 全量覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次：** 775

---

## 业务描述

本表是搜索 A/B 实验（ABTest）的**每日多维度汇总指标宽表**，面向搜索结果页（SRP）的实验分析场景。以实验分组（experiment / layer / group）为核心维度，同时按**搜索入口（search\_entrance）**、**卡片类型（card\_type）**、**是否广告（is\_ads）**进行细粒度交叉聚合，覆盖以下核心业务指标域：

- **搜索转化与 GMV**：含 995 分位截尾 GMV、PC2 GMV 及人均指标，区分高/低 GMV 品类
- **广告收益**：广告曝光数、广告收入
- **内容侧（视频 / 直播）**：搜索触达的视频播放、直播观看时长、订单及 GMV
- **用户时长**：SRP 停留时长、PDP 停留时长、视频/直播时长（均为人均值）
- **留存**：1 日留存、7 日留存 UU
- **搜索质量**：无召回率、首次点击位置均值/中位数、最大曝光位置均值/中位数

**适合回答的问题举例：**
- 某实验组相比对照组，在特定搜索入口下，搜索 GMV（995 截尾）有无显著提升？
- 视频卡 / 直播卡上线对搜索用户的内容消费时长和订单是否有正向影响？
- 实验是否影响了用户次日或 7 日回访留存？
- 广告曝光和广告收入在实验组间是否存在差异？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 ID、TH、BR 等；是所有查询的必要过滤条件 |
| `local_date` | date | 业务日期（本地时区），格式 YYYY-MM-DD；是所有查询的必要过滤条件 |

### 维度：实验体系

| 字段名 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来自实验白名单维表 |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验分组 ID，ETL 驱动字段（主 JOIN 键） |
| `exp_group_name` | string | 实验分组名称，如"对照组""实验组 A"等 |

### 维度：搜索行为分类

| 字段名 | 类型 | 说明 |
|---|---|---|
| `search_entrance` | string | 搜索入口，原始值如 `live_search`、`video_search`、`content_mix_search`、`NA`；聚合值 `__ALL__`（全入口汇总）、`all_content_search`（内容搜索汇总）、`not_content_search`（非内容搜索汇总） |
| `card_type` | string | 搜索结果卡片类型，取值为 `item`（商品卡）、`video`（视频卡）、`livestream`（直播卡）、`__ALL__`（全卡型汇总）或 `Other` |
| `is_ads` | string | 是否广告流量，取值 `true`/`false`/`__ALL__`（全量汇总） |

### 指标：GMV 与转化（995 分位截尾）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `gmv_995` | double | 按用户 ABS（人均订单金额）995 分位阈值截尾后的总 GMV（USD），已通过 `global_search_abs995_benchmark` 过滤异常高值用户 |
| `gmv_uu_995` | double | 995 截尾 GMV 除以有效曝光用户数，即人均 GMV；**不可直接 SUM** |
| `pc2_gmv_995` | double | PC2 口径 GMV 的 995 截尾总值（USD） |
| `pc2_gmv_uu_995` | double | 995 截尾 PC2 GMV 除以有效曝光用户数；**不可直接 SUM** |

### 指标：GMV 分品类截尾（v2 方法）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高 GMV 品类（category_tag = 'high gmv'）按单品订单维度 995 阈值截尾后的累计 GMV（USD） |
| `high_gmv_order_cnt_995_v2` | double | 高 GMV 品类截尾口径下的累计订单数 |
| `high_pc2_gmv_995_v2` | double | 高 GMV 品类截尾口径下的 PC2 GMV（USD） |
| `low_gmv_995_v2` | double | 低 GMV 品类按单品订单维度 995 阈值截尾后的累计 GMV（USD） |
| `low_gmv_order_cnt_995_v2` | double | 低 GMV 品类截尾口径下的累计订单数 |
| `low_pc2_gmv_995_v2` | double | 低 GMV 品类截尾口径下的 PC2 GMV（USD） |

### 指标：广告

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_rev` | double | 搜索场景下的广告收入（USD），来源于付费广告曝光消耗金额（`expenditure_amt_usd`），仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `paidads_imp_cnt` | bigint | 付费广告曝光次数，仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |

### 指标：搜索曝光

| 字段名 | 类型 | 说明 |
|---|---|---|
| `search_scene_imp_cnt` | bigint | 搜索场景下（含多种 page_type）实验用户的总曝光量，仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |

### 指标：搜索质量

| 字段名 | 类型 | 说明 |
|---|---|---|
| `norecall_rate` | double | 无召回率，定义为有无召回关键词 PV 中无召回关键词占比；**不可直接 SUM**，仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `first_click_location_avg` | double | 搜索会话内首次点击位置的均值；**不可直接 SUM**，仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `first_click_location_p50` | double | 搜索会话内首次点击位置的中位数（P50，近似算法）；**不可直接 SUM** |
| `max_imp_location_avg` | double | 搜索会话内最大曝光位置的均值；**不可直接 SUM**，仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `max_imp_location_p50` | double | 搜索会话内最大曝光位置的中位数（P50，近似算法）；**不可直接 SUM** |

### 指标：用户时长（人均）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `srp_duration_per_uu` | double | 实验用户在 SRP 页面的人均停留时长（ms / 人），由 SRP 总时长除以实验组活跃用户数计算得出；**不可直接 SUM** |
| `pdp_duration_per_uu` | double | 从搜索点击进入 PDP 后的人均停留时长（ms / 人）；**不可直接 SUM** |
| `video_duration_per_uu` | double | 搜索触达视频的人均观看时长（ms / 人）；**不可直接 SUM** |
| `live_duration_per_uu` | double | 搜索触达直播的人均观看时长（ms / 人）；**不可直接 SUM** |

### 指标：留存

| 字段名 | 类型 | 说明 |
|---|---|---|
| `search_uu_1d` | bigint | 前 1 日（T-1）在实验组内有搜索行为的 UU 数，用于计算次日留存分母；仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `retention_uu_1d` | bigint | 次日留存 UU：T-1 日搜索且 T 日也有搜索行为的用户数；仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `search_uu_7d` | bigint | 前 7 日（T-7）在实验组内有搜索行为的 UU 数，用于计算 7 日留存分母；仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |
| `retention_uu_7d` | bigint | 7 日留存 UU：T-7 日搜索且 T 日也有搜索行为的用户数；仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 时有值 |

### 指标：直播侧（搜索触达 & 全站）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `search_to_live_viewer` | bigint | 从搜索入口进入直播间的 UV（去重用户数） |
| `search_to_live_view_pv` | bigint | 从搜索入口进入直播间的 PV 数 |
| `search_to_live_duration_time` | bigint | 从搜索入口进入直播间的累计观看时长（ms） |
| `search_to_live_order` | double | 从搜索入口触达直播的直播订单数（分摊口径） |
| `search_to_live_gmv` | double | 从搜索入口触达直播的直播 GMV（USD，分摊口径） |
| `all_live_side_viewer` | bigint | 实验用户全站直播观看 UV |
| `all_live_side_view_pv` | bigint | 实验用户全站直播观看 PV |
| `all_live_side_duration_time` | bigint | 实验用户全站直播观看累计时长（ms） |
| `all_live_side_order` | double | 实验用户全站直播订单数（分摊口径） |
| `all_live_side_gmv` | double | 实验用户全站直播 GMV（USD，分摊口径） |

### 指标：视频侧（搜索触达 & 全站）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `search_to_video_viewer` | bigint | 从搜索入口触达视频的 UV（去重用户数） |
| `search_to_video_vv` | bigint | 从搜索入口触达视频的播放次数（VV） |
| `search_to_video_duration_time` | bigint | 从搜索入口触达视频的累计观看时长（ms） |
| `search_to_video_order` | double | 从搜索入口触达视频的视频订单数（分摊口径） |
| `search_to_video_gmv` | double | 从搜索入口触达视频的视频 GMV（USD，分摊口径） |
| `all_video_side_viewer` | bigint | 实验用户全站视频观看 UV |
| `all_video_side_vv` | bigint | 实验用户全站视频播放次数 |
| `all_video_side_duration_time` | bigint | 实验用户全站视频累计观看时长（ms） |
| `all_video_side_order` | double | 实验用户全站视频订单数（分摊口径） |
| `all_video_side_gmv` | double | 实验用户全站视频 GMV（USD，分摊口径） |

---

## 查询使用须知

### 必须包含的过滤条件

1. **分区字段必须显式指定**，否则触发全表扫描：
   ```sql
   WHERE grass_region = 'ID'
     AND local_date = '2025-05-16'
   ```
2. 若需多天趋势分析，务必限定 `local_date` 范围，避免扫描过多分区。

### 维度组合说明

- `is_ads` 取值为 `'true'`、`'false'` 或 `'__ALL__'`（全量），分析总体时请过滤 `is_ads = '__ALL__'`。
- `card_type` 取值为 `'item'`、`'video'`、`'livestream'`、`'__ALL__'`、`'Other'`。
- `search_entrance` 含原始入口值及聚合值 `'__ALL__'`、`'all_content_search'`、`'not_content_search'`，务必按实际分析需求选择合适粒度，**不要对不同 search\_entrance 值的同一指标进行累加**（存在重复计数）。

### 不可直接 SUM 的字段

以下字段为比率、均值、分位数或人均派生值，**跨行直接 SUM 无业务意义**，需重新拉取原始分子分母计算：

| 字段 | 原因 |
|---|---|
| `gmv_uu_995` | 人均 GMV（GMV / 有效曝光 UU） |
| `pc2_gmv_uu_995` | 人均 PC2 GMV |
| `norecall_rate` | 无召回率（比率） |
| `srp_duration_per_uu` | 人均 SRP 停留时长 |
| `pdp_duration_per_uu` | 人均 PDP 停留时长 |
| `video_duration_per_uu` | 人均视频时长 |
| `live_duration_per_uu` | 人均直播时长 |
| `first_click_location_avg` | 首次点击位置均值 |
| `first_click_location_p50` | 首次点击位置中位数（预聚合分位数） |
| `max_imp_location_avg` | 最大曝光位置均值 |
| `max_imp_location_p50` | 最大曝光位置中位数（预聚合分位数） |

### 稀疏字段说明

部分指标仅在特定维度组合下有值（非空），JOIN 条件限定如下：

- 留存类、广告类、搜索曝光类、无召回率、点击/曝光位置类字段：仅在 `is_ads = '__ALL__'` 且 `card_type = '__ALL__'` 的行有值，其他维度组合为 NULL。
- 视频/直播时长、订单、GMV 类字段：仅在 `search_entrance = '__ALL__'` 或对应 `card_type` 行有值。

### 时效性说明

- 本表为日粒度（`_1d`），数据反映 `local_date` 当天的完整业务日（本地时区）。
- ETL 通常 T+1 执行，当日数据不可查，分析时应查前一日或更早日期。
- 留存字段（`retention_uu_1d`、`search_uu_1d` 等）依赖 T-1 和 T-7 历史数据，若上游分区缺失可能导致留存为 0。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_search_scene_layer_whitelist` | 场景/层级白名单过滤 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验分组维表（scene/layer/experiment/group 信息） |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户-实验组映射（含 T、T-1、T-7 三个分区） |
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 搜索 SRP 用户级曝光、点击、订单、GMV 基准数据 |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 平台订单数据（用于 GMV v2 截尾计算） |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表（category_tag，用于高/低 GMV 品类分类） |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 品类 GMV 分位阈值（用于 995 v2 截尾） |
| `srdi_mart.dws_sr_data_warehouse_search_session_level_metircs_1d` | 搜索会话级指标（首次点击位置、最大曝光位置） |
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | 流量点击日志（SRP/PDP 停留时长） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 付费广告曝光和消耗数据 |
| `video.video_mart_ads_bi_content_userid_cp_fs_ssp_vft_1d` | 视频播放量/时长（商业化侧） |
| `video.video_mart_dws_ls_content_minils_userid_cp_ssp_vft_aggr_1d` | 视频播放量/时长（迷你直播侧） |
| `mp_content_oa.dwd_video_order_omni_local_content_direct_final_detail_di` | 视频带货订单 |
| `livestream.ls_mart_dwd_view_streaming_detail_di` | 直播观看详情（duration） |
| `livestream.ls_mart_dwd_viewer_view_detail_di` | 直播观看行为详情（PV、duration） |
| `mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di` | 直播带货订单 |
| `srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_card_type_video_metrics_1d` | 拉美地区（BR/CO/CL/MX/AR）视频指标补充数据 |
| `srdi_mart.dws_sr_data_warehouse_search_abtest_entrance_card_type_livestream_metrics_1d` | 拉美地区（BR/CO/CL/MX/AR）直播指标补充数据 |

---

## ETL 逻辑摘要

### 数据流

```
dim_whitelist / dim_exp / user_exp_mapping
        ↓
用户-实验组映射（T、T-1、T-7）
        ↓
SRP 搜索行为 → GMV 995 截尾 → dws_995_metrics（核心驱动表）
        ↓
分别 LEFT JOIN 以下各域指标中间表
├── 广告收入 (ads_performance)
├── 留存 (retention_exp)
├── SRP/PDP 停留时长 (srp_duration / pdp_duration)
├── 搜索场景曝光 (search_scene_exp)
├── 无召回率 (norecall_rate)
├── 视频指标 (video_metrics / video_duration)
├── 直播指标 (live_order / live_duration)
├── 会话位置指标 (first_location / max_imp_location)
└── GMV v2 截尾指标 (gmv995_v2_metrics)
        ↓
INSERT OVERWRITE 写入目标分区
```

### 关键步骤

1. **白名单与实验维表初始化**（Temporary View）
   - `dim_whitelist_scene`、`dim_whitelist_layer`：从白名单维表获取有效 scene_id / layer_id。
   - `dim_exp`：读取当天实验分组元数据（scene/layer/experiment/group 信息）。
   - `user_exp_mapping`：加载 T、T-1、T-7 三个日期的用户-实验组分配，缓存当天映射为 `user_exp_mapping_1d`。

2. **SRP 行为数据清洗与聚合**（Temporary View → CACHE）
   - `dwm_search_user_keyword_raw`：从 SRP benchmark 表读取多日数据，过滤 global_search / search_in_pdp / search_prefill 页面的登录用户。
   - `dws_search_feature`：按 (user_id, device_id, keyword, card_type, is_ads, search_entrance) 聚合，通过 CUBE 展开 `card_type × is_ads`，LATERAL VIEW EXPLODE 展开 search_entrance 为原始值 / 内容汇总 / `__ALL__` 三维。
   - `dws_995_metrics`（CACHE）：以用户人均 ABS 的全局 995 分位阈值（`global_search_abs995_benchmark`）截尾，JOIN 用户实验映射，聚合出 GMV/PC2 GMV 的 995 截尾汇总及人均值，作为最终 INSERT 的驱动表。

3. **各域指标中间表构建**（Temporary View / CACHE TABLE）
   - **留存**：通过 `srp_user_view` → `retention_exp_user` → `retention_exp` 三层，计算 1D/7D 留存 UU。
   - **搜索场景曝光**：`srp_all_search_scene` → `search_scene_exp`，覆盖更宽泛的 page_type。
   - **广告**：`ads_performance` → `dws_ads_performance`，读取付费广告曝光数和消耗金额。
   - **SRP 停留时长**：`dwd_srp_duration` → `dws_srp_duration`，过滤 0s < 时长 < 10h 的异常值。
   - **PDP 停留时长**：`dwd_srp_click` + `dwd_pdp` 通过 session_id / item_id / 时间窗口（点击前 10 分钟内）关联，聚合得到 `dws_pdp_duration`。
   - **视频指标**：分别读取商业化视频和迷你直播数据 UNION ALL，FULL JOIN 视频订单表，按 `sv_source_page` 分桶区分搜索来源 vs 全站，输出 `dws_video_metrics` 和 `dws_video_duration`；拉美地区（BR/CO/CL/MX/AR）从同类历史表补充。
   - **直播指标**：`dwd_live_duration_pv` 通过 `from_source` 区分 SRP 直播卡（source_type=1）和搜索浮动入口（source_type=2），UNION ALL 展开 search_entrance 内容汇总维度，输出 `dws_live_order` 和 `dws_live_duration`；拉美地区同样从历史表补充。
   - **位置指标**：`dwd_first_location` 按 ROW_NUMBER 取每会话首次点击记录，`dwd_max_imp_location` 取最大曝光位置，分别聚合均值和中位数（COLLECT_LIST + SORT_ARRAY 近似中位数）。
   - **GMV v2 截尾**：按（用户、商品、订单）粒度匹配品类 GMV 阈值维表，对高/低 GMV 品类分别截尾，聚合至实验组维度。
   - **无召回率**：统计有搜索查看行为的关键词中，无召回关键词的占比。

4. **最终写入**（INSERT OVERWRITE）
   - 以 `dws_995_metrics` 为主驱动，通过多路 LEFT JOIN 拼接所有域指标（注意各域 JOIN 条件中固定 `is_ads = '__ALL__'`、`card_type = '__ALL__'` 或按 card_type 匹配）。
   - `srp_duration_per_uu`、`pdp_duration_per_uu`、`video_duration_per_uu`、`live_duration_per_uu` 在 SELECT 层直接用总时长除以 `search_uu`（实验组总用户数）计算。
   - `ads_rev` 对应 SQL 中的 `ads_revenue`（来源于广告消耗金额）。

### 注意事项

- **单一写入器（multi_writer = false）**：本表仅由一个 ETL Job 写入，无并发写入风险。
- **地区差异（Region-specific Logic）**：视频和直播指标在东南亚（ID/MY/PH/TH/TW/VN/SG）由实时数据源计算，拉美（BR/CO/CL/MX/AR）从历史同类表 UNION 补充；若目标 region 不在以上覆盖范围，对应指标可能为 NULL。
- **search_entrance 多值展开导致行数膨胀**：ETL 通过 LATERAL VIEW EXPLODE 将每条用户记录展开为原始 entrance、内容汇总维度、`__ALL__` 三行，查询时需严格匹配所需 search_entrance 值，避免重复统计。
- **中位数近似算法**：`first_click_location_p50` 和 `max_imp_location_p50` 使用 `COLLECT_LIST + SORT_ARRAY` 计算，在数据量极大时存在内存压力；为近似值，非精确中位数。
- **GMV 995 截尾阈值**：阈值基于当日全站（`search_entrance = '__ALL__'`，`card_type = '__ALL__'`）的 ABS 分布计算，非按实验组独立计算，实验组间共用同一阈值，符合 A/B 实验公平性要求。
- **INSERT OVERWRITE 分区安全**：每次运行对指定 `grass_region + local_date` 分区全量覆盖，重跑幂等，但需确保上游所有 CACHE TABLE 在同一 Spark Session 内可用。

---

*文档生成时间：2026-05-17*